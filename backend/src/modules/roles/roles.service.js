// src/modules/roles/roles.service.js
const pool = require('../../db/pool');
const { getDefaultRolesForTenantType } = require('./roles.catalog');

async function getTenantType(tenantId) {
  const q = await pool.query(
    `
    SELECT type
    FROM tenants
    WHERE id = $1
    LIMIT 1
    `,
    [tenantId]
  );

  if (q.rowCount === 0) {
    const err = new Error('Tenant not found');
    err.status = 404;
    throw err;
  }

  return q.rows[0].type;
}

async function ensureDefaultRolesForTenant(tenantId) {
  const type = await getTenantType(tenantId);
  const roleNames = getDefaultRolesForTenantType(type);

  // idempotent insert (unique tenant_id, name already exists)
  for (const name of roleNames) {
    await pool.query(
      `
      INSERT INTO roles (tenant_id, name, created_at)
      VALUES ($1, $2, now())
      ON CONFLICT (tenant_id, name) DO NOTHING
      `,
      [tenantId, name]
    );
  }

  return roleNames;
}

async function listRoles(tenantId) {
  // ensure roles exist first (safe to call many times)
  await ensureDefaultRolesForTenant(tenantId);

  const rolesQ = await pool.query(
    `
    SELECT id, name
    FROM roles
    WHERE tenant_id = $1
    ORDER BY name
    `,
    [tenantId]
  );

  return rolesQ.rows;
}

module.exports = {
  listRoles,
  ensureDefaultRolesForTenant,
};
