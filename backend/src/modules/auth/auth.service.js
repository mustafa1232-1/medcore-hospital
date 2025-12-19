const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const JWT_ACCESS_SECRET = mustEnv('JWT_ACCESS_SECRET');
const JWT_REFRESH_SECRET = mustEnv('JWT_REFRESH_SECRET');

const ACCESS_TTL_MIN = Number(process.env.JWT_ACCESS_TTL_MIN || 15);
const REFRESH_TTL_DAYS = Number(process.env.JWT_REFRESH_TTL_DAYS || 30);

function signAccessToken({ userId, tenantId, roles }) {
  return jwt.sign(
    { sub: userId, tenantId, roles },
    JWT_ACCESS_SECRET,
    { expiresIn: `${ACCESS_TTL_MIN}m` }
  );
}

function signRefreshToken({ userId, sessionId }) {
  // sessionId داخل التوكن لربط refresh بصف auth_sessions
  return jwt.sign(
    { sub: userId, sid: sessionId },
    JWT_REFRESH_SECRET,
    { expiresIn: `${REFRESH_TTL_DAYS}d` }
  );
}

function hashToken(token) {
  // hash ثابت وسريع (لا نحتاج bcrypt هنا)
  return crypto.createHash('sha256').update(token).digest('hex');
}

function addDaysUTC(days) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + days);
  return d;
}

async function login({ tenantId, email, phone, password, userAgent, ip }) {
  if (!tenantId) throw new Error('tenantId is required');

  const client = await pool.connect();
  try {
    const q = `
      select id, tenant_id, full_name, email, phone, password_hash, is_active
      from users
      where tenant_id = $1
        and (
          ($2::text is not null and email = $2)
          or ($3::text is not null and phone = $3)
        )
      limit 1
    `;
    const r = await client.query(q, [tenantId, email || null, phone || null]);
    if (r.rowCount === 0) {
      const e = new Error('Invalid credentials');
      e.status = 401;
      throw e;
    }

    const user = r.rows[0];
    if (!user.is_active) {
      const e = new Error('User disabled');
      e.status = 403;
      throw e;
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      const e = new Error('Invalid credentials');
      e.status = 401;
      throw e;
    }

    // roles
    const rolesR = await client.query(
      `
      select r.name
      from user_roles ur
      join roles r on r.id = ur.role_id
      where ur.user_id = $1
      `,
      [user.id]
    );
    const roles = rolesR.rows.map(x => x.name);

    // create session row
    const sessionId = crypto.randomUUID();
    const refreshExpiresAt = addDaysUTC(REFRESH_TTL_DAYS);

    const refreshToken = signRefreshToken({ userId: user.id, sessionId });
    const refreshHash = hashToken(refreshToken);

    await client.query(
      `
      insert into auth_sessions (id, user_id, refresh_hash, user_agent, ip, expires_at)
      values ($1, $2, $3, $4, $5, $6)
      `,
      [sessionId, user.id, refreshHash, userAgent || null, ip || null, refreshExpiresAt]
    );

    const accessToken = signAccessToken({
      userId: user.id,
      tenantId: user.tenant_id,
      roles,
    });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        tenantId: user.tenant_id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        roles,
      },
    };
  } finally {
    client.release();
  }
}

async function refresh({ refreshToken, userAgent, ip }) {
  if (!refreshToken) {
    const e = new Error('refreshToken is required');
    e.status = 400;
    throw e;
  }

  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch {
    const e = new Error('Invalid refresh token');
    e.status = 401;
    throw e;
  }

  const userId = payload.sub;
  const sessionId = payload.sid;

  const client = await pool.connect();
  try {
    // session must exist, not revoked, not expired, and hash must match
    const tokenHash = hashToken(refreshToken);

    const s = await client.query(
      `
      select id, user_id, revoked_at, expires_at
      from auth_sessions
      where id = $1 and user_id = $2
      limit 1
      `,
      [sessionId, userId]
    );

    if (s.rowCount === 0) {
      const e = new Error('Refresh session not found');
      e.status = 401;
      throw e;
    }

    const session = s.rows[0];
    if (session.revoked_at) {
      const e = new Error('Refresh session revoked');
      e.status = 401;
      throw e;
    }
    if (new Date(session.expires_at).getTime() <= Date.now()) {
      const e = new Error('Refresh session expired');
      e.status = 401;
      throw e;
    }

    const hashCheck = await client.query(
      `select 1 from auth_sessions where id=$1 and refresh_hash=$2 and revoked_at is null`,
      [sessionId, tokenHash]
    );
    if (hashCheck.rowCount === 0) {
      // token mismatch => possible reuse attack: revoke session
      await client.query(
        `update auth_sessions set revoked_at = now() where id=$1 and revoked_at is null`,
        [sessionId]
      );
      const e = new Error('Invalid refresh token');
      e.status = 401;
      throw e;
    }

    // load user + tenant + roles
    const u = await client.query(
      `select id, tenant_id, full_name, email, phone, is_active from users where id=$1 limit 1`,
      [userId]
    );
    if (u.rowCount === 0 || !u.rows[0].is_active) {
      const e = new Error('User invalid');
      e.status = 401;
      throw e;
    }
    const user = u.rows[0];

    const rolesR = await client.query(
      `
      select r.name
      from user_roles ur
      join roles r on r.id = ur.role_id
      where ur.user_id = $1
      `,
      [user.id]
    );
    const roles = rolesR.rows.map(x => x.name);

    // ROTATION: revoke old session & create new
    await client.query(
      `update auth_sessions set revoked_at = now() where id=$1 and revoked_at is null`,
      [sessionId]
    );

    const newSessionId = crypto.randomUUID();
    const refreshExpiresAt = addDaysUTC(REFRESH_TTL_DAYS);

    const newRefreshToken = signRefreshToken({ userId: user.id, sessionId: newSessionId });
    const newRefreshHash = hashToken(newRefreshToken);

    await client.query(
      `
      insert into auth_sessions (id, user_id, refresh_hash, user_agent, ip, expires_at)
      values ($1, $2, $3, $4, $5, $6)
      `,
      [newSessionId, user.id, newRefreshHash, userAgent || null, ip || null, refreshExpiresAt]
    );

    const newAccessToken = signAccessToken({
      userId: user.id,
      tenantId: user.tenant_id,
      roles,
    });

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      user: {
        id: user.id,
        tenantId: user.tenant_id,
        fullName: user.full_name,
        email: user.email,
        phone: user.phone,
        roles,
      },
    };
  } finally {
    client.release();
  }
}

async function logout({ refreshToken }) {
  if (!refreshToken) return { ok: true };

  let payload;
  try {
    payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch {
    return { ok: true };
  }

  const userId = payload.sub;
  const sessionId = payload.sid;
  const tokenHash = hashToken(refreshToken);

  await pool.query(
    `
    update auth_sessions
    set revoked_at = now()
    where id=$1 and user_id=$2 and refresh_hash=$3 and revoked_at is null
    `,
    [sessionId, userId, tokenHash]
  );

  return { ok: true };
}

module.exports = {
  login,
  refresh,
  logout,
  signAccessToken, // (اختياري)
};
