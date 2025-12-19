// src/modules/auth/auth.service.js
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');

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
  const expiresAt = decoded?.exp ? new Date(decoded.exp * 1000) : new Date(Date.now() + 30 * 86400 * 1000);

  await pool.query(
    `
    INSERT INTO auth_sessions (id, user_id, refresh_hash, user_agent, ip, created_at, expires_at)
    VALUES (uuid_generate_v4(), $1, $2, $3, $4, now(), $5)
    `,
    [userId, refreshHash, meta.userAgent || null, meta.ip || null, expiresAt]
  );

  return { accessToken, refreshToken };
}

async function rotateRefreshToken(refreshToken, meta = {}) {
  // 1) Verify refresh token signature
  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch (e) {
    const err = new Error('Unauthorized: invalid refresh token');
    err.status = 401;
    throw err;
  }

  const userId = payload.sub;
  const tenantId = payload.tenantId;
  const roles = payload.roles || [];

  // 2) Find active session for this user (not revoked and not expired)
  // We store only hash; so we must fetch candidate sessions and compare.
  const { rows: sessions } = await pool.query(
    `
    SELECT id, refresh_hash
    FROM auth_sessions
    WHERE user_id = $1
      AND revoked_at IS NULL
      AND expires_at > now()
    ORDER BY created_at DESC
    LIMIT 20
    `,
    [userId]
  );

  let matchedSession = null;
  for (const s of sessions) {
    const ok = await bcrypt.compare(refreshToken, s.refresh_hash);
    if (ok) {
      matchedSession = s;
      break;
    }
  }

  if (!matchedSession) {
    const err = new Error('Unauthorized: refresh session not found');
    err.status = 401;
    throw err;
  }

  // 3) Issue new tokens
  const newPayload = { sub: userId, tenantId, roles };
  const newAccessToken = signAccessToken(newPayload);
  const newRefreshToken = signRefreshToken(newPayload);
  const newRefreshHash = await bcrypt.hash(newRefreshToken, 10);

  const decodedNew = jwt.decode(newRefreshToken);
  const newExpiresAt = decodedNew?.exp ? new Date(decodedNew.exp * 1000) : new Date(Date.now() + 30 * 86400 * 1000);

  // 4) Rotate the stored hash in the same session (keeps single session record)
  await pool.query(
    `
    UPDATE auth_sessions
    SET refresh_hash = $1,
        user_agent = COALESCE($2, user_agent),
        ip = COALESCE($3, ip),
        expires_at = $4
    WHERE id = $5
    `,
    [newRefreshHash, meta.userAgent || null, meta.ip || null, newExpiresAt, matchedSession.id]
  );

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}

async function revokeRefreshToken(refreshToken) {
  // optional: logout support
  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch {
    return; // ignore
  }

  const userId = payload.sub;

  const { rows: sessions } = await pool.query(
    `
    SELECT id, refresh_hash
    FROM auth_sessions
    WHERE user_id = $1
      AND revoked_at IS NULL
    ORDER BY created_at DESC
    LIMIT 20
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

module.exports = {
  issueTokensForUser,
  rotateRefreshToken,
  revokeRefreshToken,
};
