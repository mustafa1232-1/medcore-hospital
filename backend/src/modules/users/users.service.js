// src/modules/users/users.service.js
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const pool = require('../../db/pool');

function slugify(input) {
  const s = String(input || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-+|-+$)/g, '');
  return s || 'staff';
}

function shortSuffix4() {
  return crypto.randomBytes(2).toString('hex'); // 4 hex chars
}

async function getTenantCodeBase(client, tenantId) {
  const q = await client.query(`SELECT code FROM tenants WHERE id = $1 LIMIT 1`, [tenantId]);
  const code = q.rows[0]?.code || 'facility';
  const base = String(code).split('-')[0] || 'facility';
  return base;
}

async function generateUniqueStaffCode(client, tenantId, fullName) {
  const nameBase0 = slugify(fullName);
  const nameBase = nameBase0.length > 14 ? nameBase0.slice(0, 14) : nameBase0;

  const tenantBase0 = await getTenantCodeBase(client, tenantId);
  const tenantBase = tenantBase0.length > 10 ? tenantBase0.slice(0, 10) : tenantBase0;

  for (let i = 0; i < 10; i++) {
    const staffCode = `${nameBase}-${tenantBase}-${shortSuffix4()}`;
    const chk = await client.query(
      `SELECT 1 FROM users WHERE tenant_id = $1 AND staff_code = $2 LIMIT 1`,
      [tenantId, staffCode]
    );
    if (chk.rowCount === 0) return staffCode;
  }

  throw new Error('Failed to generate unique staff code');
}

async function ensureRolesExist(tenantId, roleNames) {
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

  const { rows } = await pool.query(
    `
    SELECT id, name
    FROM roles
    WHERE tenant_id = $1 AND name = ANY($2::text[])
    `,
    [tenantId, roleNames]
  );

  const map = new Map(rows.map((r) => [r.name, r.id]));
  return roleNames.map((n) => map.get(n)).filter(Boolean);
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
    where += ` AND (
      u.full_name ILIKE ${p}
      OR u.email ILIKE ${p}
      OR u.phone ILIKE ${p}
      OR u.staff_code ILIKE ${p}
    )`;
  }

  params.push(limit, offset);

  const usersQ = await pool.query(
    `
    SELECT
      u.id,
      u.staff_code AS "staffCode",
      u.tenant_id AS "tenantId",
      u.full_name AS "fullName",
      u.email,
      u.phone,
      u.is_active AS "isActive",
      u.created_at AS "createdAt",

      -- ✅ department fields
      u.department_id AS "departmentId",
      d.name AS "departmentName",
      d.code AS "departmentCode"

    FROM users u
    LEFT JOIN departments d
      ON d.id = u.department_id
     AND d.tenant_id = u.tenant_id

    ${where}
    ORDER BY u.created_at DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
    `,
    params
  );

  const ids = usersQ.rows.map((u) => u.id);
  let rolesMap = new Map();

  if (ids.length) {
    // ✅ IMPORTANT: tenant-scope roles to avoid cross-tenant leakage
    const rolesQ = await pool.query(
      `
      SELECT ur.user_id, r.name
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = ANY($1::uuid[])
        AND r.tenant_id = $2
      ORDER BY r.name
      `,
      [ids, tenantId]
    );

    rolesMap = new Map();
    for (const row of rolesQ.rows) {
      const arr = rolesMap.get(row.user_id) || [];
      arr.push(row.name);
      rolesMap.set(row.user_id, arr);
    }
  }

  return usersQ.rows.map((u) => ({
    ...u,
    roles: rolesMap.get(u.id) || [],
  }));
}

// ✅ UPDATED: accepts departmentId
async function createUser({ tenantId, fullName, email, phone, password, roles, departmentId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ✅ Optional but important: ensure department belongs to same tenant
    if (departmentId) {
      const dep = await client.query(
        `SELECT 1 FROM departments WHERE id = $1 AND tenant_id = $2 LIMIT 1`,
        [departmentId, tenantId]
      );
      if (dep.rowCount === 0) {
        const err = new Error('Invalid departmentId');
        err.status = 400;
        throw err;
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const staffCode = await generateUniqueStaffCode(client, tenantId, fullName);

    const { rows: uRows } = await client.query(
      `
      INSERT INTO users (id, tenant_id, staff_code, full_name, email, phone, password_hash, is_active, created_at, department_id)
      VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, $6, true, now(), $7)
      RETURNING
        id,
        staff_code AS "staffCode",
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone,
        is_active AS "isActive",
        created_at AS "createdAt",
        department_id AS "departmentId"
      `,
      [tenantId, staffCode, fullName, email || null, phone || null, passwordHash, departmentId || null]
    );

    const user = uRows[0];

    const roleIds = await ensureRolesExist(tenantId, roles);

    for (const roleId of roleIds) {
      await client.query(
        `
        INSERT INTO user_roles (user_id, role_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
        `,
        [user.id, roleId]
      );
    }

    // ✅ tenant-scope roles for safety
    const rolesQ = await client.query(
      `
      SELECT r.name
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = $1
        AND r.tenant_id = $2
      ORDER BY r.name
      `,
      [user.id, tenantId]
    );

    await client.query('COMMIT');

    return {
      ...user,
      roles: rolesQ.rows.map((r) => r.name),
    };
  } catch (e) {
    try {
      await client.query('ROLLBACK');
    } catch {}
    throw e;
  } finally {
    client.release();
  }
}

async function setUserActive({ tenantId, userId, isActive }) {
  const { rowCount, rows } = await pool.query(
    `
    UPDATE users
    SET is_active = $1
    WHERE id = $2 AND tenant_id = $3
    RETURNING
      id,
      staff_code AS "staffCode",
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

  // ✅ tenant-scope roles for safety
  const rolesQ = await pool.query(
    `
    SELECT r.name
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = $1
      AND r.tenant_id = $2
    ORDER BY r.name
    `,
    [user.id, tenantId]
  );

  return { ...user, roles: rolesQ.rows.map((r) => r.name) };
}

module.exports = {
  listUsers,
  createUser,
  setUserActive,
};
