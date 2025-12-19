// src/modules/auth/auth.controller.js
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const authService = require('./auth.service');

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

    // 1) create tenant
    const tenantQ = await client.query(
      `
      INSERT INTO tenants (name, type, phone, email)
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, type, phone, email, created_at
      `,
      [name, type, phone || null, email || null]
    );

    const tenant = tenantQ.rows[0];

    // 2) create admin user
    const password_hash = await bcrypt.hash(adminPassword, 10);

    const userQ = await client.query(
      `
      INSERT INTO users (tenant_id, full_name, email, phone, password_hash)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING 
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone
      `,
      [tenant.id, adminFullName, adminEmail || null, adminPhone || null, password_hash]
    );

    const admin = userQ.rows[0];

    // 3) ensure ADMIN role exists for this tenant
    const roleQ = await client.query(
      `
      INSERT INTO roles (tenant_id, name)
      VALUES ($1, 'ADMIN')
      ON CONFLICT (tenant_id, name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id, name
      `,
      [tenant.id]
    );

    const role = roleQ.rows[0];

    // 4) attach role to user
    await client.query(
      `
      INSERT INTO user_roles (user_id, role_id)
      VALUES ($1, $2)
      ON CONFLICT DO NOTHING
      `,
      [admin.id, role.id]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      tenant: {
        id: tenant.id,
        name: tenant.name,
        type: tenant.type,
        phone: tenant.phone,
        email: tenant.email,
        created_at: tenant.created_at,
      },
      admin: {
        id: admin.id,
        tenantId: admin.tenantId,
        fullName: admin.fullName,
        email: admin.email,
        phone: admin.phone,
      },
    });
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

    // 1) find user within tenant by email or phone
    const params = [tenantId];
    let where = `tenant_id = $1`;

    if (email) {
      params.push(email);
      where += ` AND email = $2`;
    } else {
      params.push(phone);
      where += ` AND phone = $2`;
    }

    const userQ = await pool.query(
      `
      SELECT
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone,
        password_hash,
        is_active AS "isActive",
        created_at AS "createdAt"
      FROM users
      WHERE ${where}
      LIMIT 1
      `,
      params
    );

    if (userQ.rowCount === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const u = userQ.rows[0];

    if (!u.isActive) {
      return res.status(403).json({ message: 'User is inactive' });
    }

    const ok = await bcrypt.compare(password, u.password_hash);
    if (!ok) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // 2) roles
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

    const roles = rolesQ.rows.map((x) => x.name);

    // 3) issue tokens and persist refresh session
    const tokens = await authService.issueTokensForUser(
      { userId: u.id, tenantId: u.tenantId, roles },
      { userAgent: req.headers['user-agent'], ip: req.ip }
    );

    // remove password hash from response
    delete u.password_hash;

    return res.json({
      ...tokens,
      user: {
        ...u,
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

    if (!refreshToken) {
      return res.status(400).json({ message: 'refreshToken is required' });
    }

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

module.exports = {
  registerTenant,
  login,
  refresh,
  logout,
};
