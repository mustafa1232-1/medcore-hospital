const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../../db/pool');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const JWT_ACCESS_SECRET = mustEnv('JWT_ACCESS_SECRET');
const JWT_REFRESH_SECRET = mustEnv('JWT_REFRESH_SECRET');
const JWT_ACCESS_TTL_MIN = parseInt(process.env.JWT_ACCESS_TTL_MIN || '15', 10);
const JWT_REFRESH_TTL_DAYS = parseInt(process.env.JWT_REFRESH_TTL_DAYS || '30', 10);

function signAccessToken(payload) {
  return jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: `${JWT_ACCESS_TTL_MIN}m` });
}

function signRefreshToken(payload) {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: `${JWT_REFRESH_TTL_DAYS}d` });
}

function verifyRefreshToken(token) {
  return jwt.verify(token, JWT_REFRESH_SECRET);
}

function sha256(text) {
  // Refresh token hash باستخدام bcrypt (أسهل، آمن، بدون crypto)
  // نخزن hash فقط في DB
  return bcrypt.hash(text, 12);
}

async function createTenantWithAdmin(input) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // إنشاء Tenant
    const tenantRes = await client.query(
      `INSERT INTO tenants (name, type, phone, email)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, type, phone, email, created_at`,
      [input.name, input.type, input.phone || null, input.email || null]
    );
    const tenant = tenantRes.rows[0];

    // إنشاء Roles افتراضية
    const roles = ['ADMIN', 'DOCTOR', 'NURSE', 'PHARMACY', 'LAB'];
    const roleIds = {};
    for (const r of roles) {
      const rr = await client.query(
        `INSERT INTO roles (tenant_id, name) VALUES ($1, $2)
         ON CONFLICT (tenant_id, name) DO UPDATE SET name = EXCLUDED.name
         RETURNING id`,
        [tenant.id, r]
      );
      roleIds[r] = rr.rows[0].id;
    }

    // إنشاء Admin User
    const passwordHash = await bcrypt.hash(input.adminPassword, 12);

    const adminRes = await client.query(
      `INSERT INTO users (tenant_id, full_name, email, phone, password_hash, is_active)
       VALUES ($1, $2, $3, $4, $5, true)
       RETURNING id, tenant_id, full_name, email, phone, is_active, created_at`,
      [
        tenant.id,
        input.adminFullName,
        input.adminEmail || null,
        input.adminPhone || null,
        passwordHash,
      ]
    );
    const admin = adminRes.rows[0];

    // ربط ADMIN role
    await client.query(
      `INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [admin.id, roleIds.ADMIN]
    );

    await client.query('COMMIT');
    return { tenant, admin };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function login({ tenantId, email, phone, password, userAgent, ip }) {
  const idRes = await pool.query(
    `SELECT id, tenant_id, full_name, email, phone, password_hash, is_active
     FROM users
     WHERE tenant_id = $1
       AND (
         ($2::text IS NOT NULL AND email = $2)
         OR
         ($3::text IS NOT NULL AND phone = $3)
       )
     LIMIT 1`,
    [tenantId, email || null, phone || null]
  );

  const user = idRes.rows[0];
  if (!user) {
    const err = new Error('بيانات الدخول غير صحيحة');
    err.status = 401;
    throw err;
  }
  if (!user.is_active) {
    const err = new Error('الحساب معطّل');
    err.status = 403;
    throw err;
  }

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    const err = new Error('بيانات الدخول غير صحيحة');
    err.status = 401;
    throw err;
  }

  // roles
  const rolesRes = await pool.query(
    `SELECT r.name
     FROM user_roles ur
     JOIN roles r ON r.id = ur.role_id
     WHERE ur.user_id = $1`,
    [user.id]
  );
  const roles = rolesRes.rows.map((r) => r.name);

  const accessToken = signAccessToken({ sub: user.id, tenantId: user.tenant_id, roles });
  const refreshToken = signRefreshToken({ sub: user.id, tenantId: user.tenant_id });

  const refreshHash = await bcrypt.hash(refreshToken, 12);
  const expiresAt = new Date(Date.now() + JWT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);

  const sessRes = await pool.query(
    `INSERT INTO auth_sessions (user_id, refresh_hash, user_agent, ip, expires_at)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, created_at, expires_at`,
    [user.id, refreshHash, userAgent || null, ip || null, expiresAt]
  );

  return {
    user: {
      id: user.id,
      tenantId: user.tenant_id,
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      roles,
    },
    tokens: {
      accessToken,
      refreshToken,
      accessExpiresInMin: JWT_ACCESS_TTL_MIN,
      refreshExpiresInDays: JWT_REFRESH_TTL_DAYS,
      sessionId: sessRes.rows[0].id,
    },
  };
}

async function refresh({ refreshToken, userAgent, ip }) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    const err = new Error('Refresh token غير صالح');
    err.status = 401;
    throw err;
  }

  const userId = payload.sub;
  const tenantId = payload.tenantId;

  // احضر جلسات user غير منتهية وغير revoked
  const sessionsRes = await pool.query(
    `SELECT id, refresh_hash, expires_at, revoked_at
     FROM auth_sessions
     WHERE user_id = $1
       AND revoked_at IS NULL
       AND expires_at > now()
     ORDER BY created_at DESC`,
    [userId]
  );

  // لازم يطابق hash إحدى الجلسات
  let session = null;
  for (const s of sessionsRes.rows) {
    const match = await bcrypt.compare(refreshToken, s.refresh_hash);
    if (match) {
      session = s;
      break;
    }
  }
  if (!session) {
    const err = new Error('Session غير موجودة أو منتهية');
    err.status = 401;
    throw err;
  }

  // roles
  const rolesRes = await pool.query(
    `SELECT r.name
     FROM user_roles ur
     JOIN roles r ON r.id = ur.role_id
     WHERE ur.user_id = $1`,
    [userId]
  );
  const roles = rolesRes.rows.map((r) => r.name);

  const accessToken = signAccessToken({ sub: userId, tenantId, roles });

  // Optional rotation: إصدار refresh جديد وتحديث hash
  const newRefreshToken = signRefreshToken({ sub: userId, tenantId });
  const newRefreshHash = await bcrypt.hash(newRefreshToken, 12);
  const newExpiresAt = new Date(Date.now() + JWT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);

  await pool.query(
    `UPDATE auth_sessions
     SET refresh_hash = $1, user_agent = COALESCE($2, user_agent), ip = COALESCE($3, ip), expires_at = $4
     WHERE id = $5`,
    [newRefreshHash, userAgent || null, ip || null, newExpiresAt, session.id]
  );

  return {
    accessToken,
    refreshToken: newRefreshToken,
    accessExpiresInMin: JWT_ACCESS_TTL_MIN,
    refreshExpiresInDays: JWT_REFRESH_TTL_DAYS,
    sessionId: session.id,
  };
}

async function logout({ refreshToken }) {
  // revoke session matching refreshToken
  const sessionsRes = await pool.query(
    `SELECT id, refresh_hash
     FROM auth_sessions
     WHERE revoked_at IS NULL
       AND expires_at > now()
     ORDER BY created_at DESC`
  );

  for (const s of sessionsRes.rows) {
    const match = await bcrypt.compare(refreshToken, s.refresh_hash);
    if (match) {
      await pool.query(`UPDATE auth_sessions SET revoked_at = now() WHERE id = $1`, [s.id]);
      return { ok: true };
    }
  }

  // إذا ما وجدنا session نرجع ok أيضًا (idempotent)
  return { ok: true };
}

module.exports = {
  createTenantWithAdmin,
  login,
  refresh,
  logout,
};
