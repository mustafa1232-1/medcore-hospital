// src/modules/auth/auth.service.js
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const JWT_ACCESS_SECRET = mustEnv('JWT_ACCESS_SECRET');
const JWT_REFRESH_SECRET = mustEnv('JWT_REFRESH_SECRET');
const JWT_ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || '15m';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

function signAccessToken(payload) {
  return jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: JWT_ACCESS_EXPIRES_IN });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRES_IN });
}

async function getUserRoles({ tenantId, userId }) {
  const q = await pool.query(
    `
    SELECT r.name
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = $1 AND r.tenant_id = $2
    ORDER BY r.name
    `,
    [userId, tenantId]
  );

  return q.rows.map(r => r.name);
}

async function issueTokensForUser({ userId, tenantId, roles }, meta = {}) {
  const payload = {
    sub: userId,
    tenantId,
    roles,
  };

  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  const refreshHash = await bcrypt.hash(refreshToken, 10);

  // decode refresh to get exp
  const decoded = jwt.decode(refreshToken);
  const expiresAt = decoded?.exp
    ? new Date(decoded.exp * 1000)
    : new Date(Date.now() + 30 * 86400 * 1000);

  await pool.query(
    `
    INSERT INTO auth_sessions (id, user_id, refresh_hash, user_agent, ip, revoked_at, created_at, expires_at)
    VALUES (uuid_generate_v4(), $1, $2, $3, $4, NULL, now(), $5)
    `,
    [userId, refreshHash, meta.userAgent || null, meta.ip || null, expiresAt]
  );

  return { accessToken, refreshToken };
}

async function rotateRefreshToken(refreshToken, meta = {}) {
  if (!refreshToken) throw new HttpError(400, 'Missing refreshToken');

  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch {
    throw new HttpError(401, 'Unauthorized: invalid refresh token');
  }

  const userId = payload?.sub;
  const tenantId = payload?.tenantId;
  if (!userId || !tenantId) throw new HttpError(401, 'Unauthorized: invalid payload');

  // find active sessions for user (not revoked, not expired)
  const { rows: sessions } = await pool.query(
    `
    SELECT id, refresh_hash
    FROM auth_sessions
    WHERE user_id = $1
      AND revoked_at IS NULL
      AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 50
    `,
    [userId]
  );

  // match refresh token against stored hashes
  let matchedSessionId = null;
  for (const s of sessions) {
    const ok = await bcrypt.compare(refreshToken, s.refresh_hash);
    if (ok) {
      matchedSessionId = s.id;
      break;
    }
  }

  if (!matchedSessionId) {
    throw new HttpError(401, 'Unauthorized: refresh token not recognized');
  }

  // revoke old session
  await pool.query(`UPDATE auth_sessions SET revoked_at = now() WHERE id = $1`, [matchedSessionId]);

  // re-issue with current roles (fresh from DB)
  const roles = await getUserRoles({ tenantId, userId });
  const tokens = await issueTokensForUser({ userId, tenantId, roles }, meta);

  return tokens;
}

async function revokeRefreshToken(refreshToken) {
  if (!refreshToken) return;

  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch {
    // even if invalid, do nothing (logout idempotent)
    return;
  }

  const userId = payload?.sub;
  if (!userId) return;

  const { rows: sessions } = await pool.query(
    `
    SELECT id, refresh_hash
    FROM auth_sessions
    WHERE user_id = $1
      AND revoked_at IS NULL
    ORDER BY created_at DESC
    LIMIT 50
    `,
    [userId]
  );

  for (const s of sessions) {
    const ok = await bcrypt.compare(refreshToken, s.refresh_hash);
    if (ok) {
      await pool.query(`UPDATE auth_sessions SET revoked_at = now() WHERE id = $1`, [s.id]);
      break;
    }
  }
}

/**
 * ✅ NEW: login used by controller
 * Accepts either email or phone with tenantId
 */
async function login({ tenantId, email, phone, password }, meta = {}) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!password) throw new HttpError(400, 'password is required');
  if (!email && !phone) throw new HttpError(400, 'email or phone is required');

  const q = await pool.query(
    `
    SELECT
      id,
      tenant_id AS "tenantId",
      full_name AS "fullName",
      email,
      phone,
      password_hash AS "passwordHash",
      is_active AS "isActive"
    FROM users
    WHERE tenant_id = $1
      AND (
        ($2::text IS NOT NULL AND email = $2)
        OR
        ($3::text IS NOT NULL AND phone = $3)
      )
    LIMIT 1
    `,
    [tenantId, email || null, phone || null]
  );

  if (q.rowCount === 0) {
    throw new HttpError(401, 'Invalid credentials');
  }

  const user = q.rows[0];

  if (!user.isActive) {
    throw new HttpError(403, 'User is inactive');
  }

  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) {
    throw new HttpError(401, 'Invalid credentials');
  }

  const roles = await getUserRoles({ tenantId: user.tenantId, userId: user.id });
  const tokens = await issueTokensForUser(
    { userId: user.id, tenantId: user.tenantId, roles },
    meta
  );

  return {
    ok: true,
    user: {
      id: user.id,
      tenantId: user.tenantId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      roles,
    },
    ...tokens,
  };
}

/**
 * ✅ NEW: refresh used by controller
 */
async function refresh({ refreshToken }, meta = {}) {
  const tokens = await rotateRefreshToken(refreshToken, meta);
  return { ok: true, ...tokens };
}

/**
 * ✅ NEW: logout used by controller
 */
async function logout({ refreshToken }) {
  await revokeRefreshToken(refreshToken);
  return { ok: true };
}

module.exports = {
  issueTokensForUser,
  rotateRefreshToken,
  revokeRefreshToken,

  // ✅ exports required by controller
  login,
  refresh,
  logout,
};
