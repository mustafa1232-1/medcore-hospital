// src/modules/auth/auth.controller.js
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const authService = require('./auth.service');
const passwordService = require('./password.service'); // ✅ use service
const rolesService = require('../roles/roles.service'); // ✅ add this
async function registerTenant(req, res, next) {
  const client = await pool.connect();
  try {
    const {
      name,
      type,
      phone,
      email,
      adminFullName,
      adminEmail,
      adminPhone,
      adminPassword,
    } = req.body;

    await client.query('BEGIN');

    // 1) Create tenant
    const tenantQ = await client.query(
      `
      INSERT INTO tenants (id, name, type, phone, email, created_at)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, now()) -- ✅ FIX
      RETURNING id, name, type, phone, email, created_at
      `,
      [name, type, phone || null, email || null]
    );

    const tenant = tenantQ.rows[0];

    // 2) Create admin user
    const passwordHash = await bcrypt.hash(adminPassword, 10);

    const userQ = await client.query(
      `
      INSERT INTO users (id, tenant_id, full_name, email, phone, password_hash, is_active, created_at)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, true, now())
      RETURNING 
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone
      `,
      [tenant.id, adminFullName, adminEmail || null, adminPhone || null, passwordHash]
    );

    const admin = userQ.rows[0];

    // 3) Ensure ADMIN role
    const roleQ = await client.query(
      `
      INSERT INTO roles (tenant_id, name, created_at)
      VALUES ($1, 'ADMIN', now())
      ON CONFLICT (tenant_id, name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id, name
      `,
      [tenant.id]
    );

    const roleId = roleQ.rows[0].id;

    // 4) Link user_roles
    await client.query(
      `
      INSERT INTO user_roles (user_id, role_id)
      VALUES ($1, $2)
      ON CONFLICT DO NOTHING
      `,
      [admin.id, roleId]
    );
    // ✅ seed default roles for this tenant (idempotent)
await rolesService.ensureDefaultRolesForTenant(tenant.id);


    await client.query('COMMIT');

    return res.status(201).json({ tenant, admin });
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch {}
    return next(err);
  } finally {
    client.release();
  }
  
}

async function login(req, res, next) {
  try {
    const { tenantId, email, phone, password } = req.body;

    const userQ = await pool.query(
      `
      SELECT 
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone,
        password_hash AS "passwordHash",
        is_active AS "isActive",
        created_at AS "createdAt"
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

    if (userQ.rowCount === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const u = userQ.rows[0];

    if (!u.isActive) {
      return res.status(403).json({ message: 'User is inactive' });
    }

    const ok = await bcrypt.compare(password, u.passwordHash);
    if (!ok) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const rolesQ = await pool.query(
      `
      SELECT r.name
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = $1
      ORDER BY r.name
      `,
      [u.id]
    );

    const roles = rolesQ.rows.map(x => x.name);

    const tokens = await authService.issueTokensForUser(
      { userId: u.id, tenantId: u.tenantId, roles },
      { userAgent: req.headers['user-agent'], ip: req.ip }
    );

    return res.json({
      ...tokens,
      user: {
        id: u.id,
        tenantId: u.tenantId,
        fullName: u.fullName,
        email: u.email,
        phone: u.phone,
        isActive: u.isActive,
        createdAt: u.createdAt,
        roles,
      },
    });
  } catch (err) {
    return next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;

    const tokens = await authService.rotateRefreshToken(refreshToken, {
      userAgent: req.headers['user-agent'],
      ip: req.ip,
    });

    return res.json(tokens);
  } catch (err) {
    return next(err);
  }
}

async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await authService.revokeRefreshToken(refreshToken);
    }
    return res.json({ ok: true });
  } catch (err) {
    return next(err);
  }
}

// ✅ Change own password
async function changePassword(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    const userId = req.user?.sub;

    if (!tenantId || !userId) {
      return res.status(401).json({ message: 'Unauthorized: invalid payload' });
    }

    const { currentPassword, newPassword } = req.body;

    const result = await passwordService.changeOwnPassword({
      tenantId,
      userId,
      currentPassword,
      newPassword,
    });

    return res.json(result);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  registerTenant,
  login,
  refresh,
  logout,
  changePassword,
};
