// src/modules/roles/roles.service.js
const pool = require('../../db/pool');
const { getDefaultRolesForTenantType } = require('./roles.catalog');

async function getTenantType(tenantId, db = pool) {
  const q = await db.query(
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

async function ensureDefaultRolesForTenant(tenantId, db = pool) {
  const type = await getTenantType(tenantId, db);
  const roleNames = getDefaultRolesForTenantType(type);

  for (const name of roleNames) {
    await db.query(
      `
      INSERT INTO roles (tenant_id, name, created_at)
      VALUES ($1, $2, now())
      ON CONFLICT (tenant_id, name) DO NOTHING
      `,
      [tenantId, name]
    );
  }
}

module.exports = {
  ensureDefaultRolesForTenant,
};
