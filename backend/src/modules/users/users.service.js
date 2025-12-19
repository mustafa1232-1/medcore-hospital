// src/modules/users/users.service.js
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');

async function ensureRolesExist(tenantId, roleNames) {
  // Insert missing roles (idempotent)
  // roles table has UNIQUE (tenant_id, name)
  for (const name of roleNames) {
    await pool.query(
      `
      INSERT INTO roles (tenant_id, name)
      VALUES ($1, $2)
      ON CONFLICT (tenant_id, name) DO NOTHING
      `,
      [tenantId, name]
    );
  }

  // Fetch role ids
  const { rows } = await pool.query(
    `
    SELECT id, name
    FROM roles
    WHERE tenant_id = $1 AND name = ANY($2::text[])
    `,
    [tenantId, roleNames]
  );

  const map = new Map(rows.map(r => [r.name, r.id]));
  return roleNames.map(n => map.get(n)).filter(Boolean);
}

async function listUsers({ tenantId, q, active, limit = 50, offset = 0 }) {
  const params = [tenantId];
  let where = `WHERE u.tenant_id = $1`;

  if (typeof active === 'boolean') {
    params.push(active);
    where += ` AND u.is_active = $${params.length}`;
  }

  if (q) {
    params.push(`%${q}%`);
    const p = `$${params.length}`;
    where += ` AND (u.full_name ILIKE ${p} OR u.email ILIKE ${p} OR u.phone ILIKE ${p})`;
  }

  params.push(limit, offset);

  const usersQ = await pool.query(
    `
    SELECT
      u.id,
      u.tenant_id AS "tenantId",
      u.full_name AS "fullName",
      u.email,
      u.phone,
      u.is_active AS "isActive",
      u.created_at AS "createdAt"
    FROM users u
    ${where}
    ORDER BY u.created_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
    `,
    params
  );

  // Roles for returned users (one query)
  const ids = usersQ.rows.map(u => u.id);
  let rolesMap = new Map();

  if (ids.length) {
    const rolesQ = await pool.query(
      `
      SELECT ur.user_id, r.name
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = ANY($1::uuid[])
      ORDER BY r.name
      `,
      [ids]
    );

    rolesMap = new Map();
    for (const row of rolesQ.rows) {
      const arr = rolesMap.get(row.user_id) || [];
      arr.push(row.name);
      rolesMap.set(row.user_id, arr);
    }
  }

  const users = usersQ.rows.map(u => ({
    ...u,
    roles: rolesMap.get(u.id) || [],
  }));

  return users;
}

async function createUser({ tenantId, fullName, email, phone, password, roles }) {
  const passwordHash = await bcrypt.hash(password, 10);

  // Create user
  const { rows: uRows } = await pool.query(
    `
    INSERT INTO users (id, tenant_id, full_name, email, phone, password_hash, is_active, created_at)
    VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, true, now())
    RETURNING
      id,
      tenant_id AS "tenantId",
      full_name AS "fullName",
      email,
      phone,
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    [tenantId, fullName, email || null, phone || null, passwordHash]
  );

  const user = uRows[0];

  // Ensure roles exist in this tenant, then assign
  const roleIds = await ensureRolesExist(tenantId, roles);

  for (const roleId of roleIds) {
    await pool.query(
      `
      INSERT INTO user_roles (user_id, role_id)
      VALUES ($1, $2)
      ON CONFLICT DO NOTHING
      `,
      [user.id, roleId]
    );
  }

  // Fetch roles by name to return
  const rolesQ = await pool.query(
    `
    SELECT r.name
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = $1
    ORDER BY r.name
    `,
    [user.id]
  );

  return {
    ...user,
    roles: rolesQ.rows.map(r => r.name),
  };
}

async function setUserActive({ tenantId, userId, isActive }) {
  const { rowCount, rows } = await pool.query(
    `
    UPDATE users
    SET is_active = $1
    WHERE id = $2 AND tenant_id = $3
    RETURNING
      id,
      tenant_id AS "tenantId",
      full_name AS "fullName",
      email,
      phone,
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    [isActive, userId, tenantId]
  );

  if (rowCount === 0) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }

  const user = rows[0];

  const rolesQ = await pool.query(
    `
    SELECT r.name
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = $1
    ORDER BY r.name
    `,
    [user.id]
  );

  return { ...user, roles: rolesQ.rows.map(r => r.name) };
}

module.exports = {
  listUsers,
  createUser,
  setUserActive,
};
