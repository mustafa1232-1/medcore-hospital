const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const authService = require('./auth.service');

// POST /api/auth/register-tenant
async function registerTenant(req, res) {
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

  if (!name || !type || !adminFullName || !adminPassword) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const tenantR = await client.query(
      `
      insert into tenants (name, type, phone, email)
      values ($1, $2, $3, $4)
      returning id, name, type, phone, email, created_at
      `,
      [name, type, phone || null, email || null]
    );

    const tenant = tenantR.rows[0];

    // Create roles (ADMIN, DOCTOR, NURSE, PHARMACY, LAB)
    const roles = ['ADMIN', 'DOCTOR', 'NURSE', 'PHARMACY', 'LAB'];
    const roleIds = {};

    for (const roleName of roles) {
      const rr = await client.query(
        `
        insert into roles (tenant_id, name)
        values ($1, $2)
        on conflict (tenant_id, name) do update set name=excluded.name
        returning id, name
        `,
        [tenant.id, roleName]
      );
      roleIds[roleName] = rr.rows[0].id;
    }

    const passwordHash = await bcrypt.hash(adminPassword, 12);

    const adminR = await client.query(
      `
      insert into users (tenant_id, full_name, email, phone, password_hash, is_active)
      values ($1, $2, $3, $4, $5, true)
    returning id, tenant_id, full_name, email, phone, is_active, created_at
      `,
      [tenant.id, adminFullName, adminEmail || null, adminPhone || null, passwordHash]
    );

    const admin = adminR.rows[0];

    await client.query(
      `
      insert into user_roles (user_id, role_id)
      values ($1, $2)
      on conflict do nothing
      `,
      [admin.id, roleIds.ADMIN]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      tenant,
      admin: {
        id: admin.id,
        tenantId: admin.tenant_id,
        fullName: admin.full_name,
        email: admin.email,
        phone: admin.phone,
      },
    });
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

// POST /api/auth/login
async function login(req, res) {
  const { tenantId, email, phone, password } = req.body;

  const result = await authService.login({
    tenantId,
    email,
    phone,
    password,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });

  res.json(result);
}

// POST /api/auth/refresh
async function refresh(req, res) {
  const { refreshToken } = req.body;

  const result = await authService.refresh({
    refreshToken,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });

  res.json(result);
}

// POST /api/auth/logout
async function logout(req, res) {
  const { refreshToken } = req.body;
  const result = await authService.logout({ refreshToken });
  res.json(result);
}

module.exports = {
  registerTenant,
  login,
  refresh,
  logout,
};
