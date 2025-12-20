const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function isUniqueViolation(e) {
  return e && e.code === '23505';
}

async function createDepartment({ tenantId, code, name, isActive }) {
  try {
    const { rows } = await pool.query(
      `INSERT INTO departments (tenant_id, code, name, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, tenant_id, code, name, is_active, created_at`,
      [tenantId, code, name, isActive]
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Department code already exists');
    throw e;
  }
}

async function listDepartments({ tenantId, q, active }) {
  const params = [tenantId];
  let where = `tenant_id = $1`;

  if (q) {
    params.push(`%${q}%`);
    where += ` AND (code ILIKE $${params.length} OR name ILIKE $${params.length})`;
  }
  if (active !== undefined) {
    params.push(active);
    where += ` AND is_active = $${params.length}`;
  }

  const { rows } = await pool.query(
    `SELECT id, tenant_id, code, name, is_active, created_at
     FROM departments
     WHERE ${where}
     ORDER BY name ASC`,
    params
  );
  return rows;
}

async function getDepartment({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, tenant_id, code, name, is_active, created_at
     FROM departments
     WHERE tenant_id = $1 AND id = $2`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Department not found');
  return rows[0];
}

async function updateDepartment({ tenantId, id, patch }) {
  await getDepartment({ tenantId, id });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.code !== undefined) { values.push(patch.code); set.push(`code = $${++i}`); }
  if (patch.name !== undefined) { values.push(patch.name); set.push(`name = $${++i}`); }
  if (patch.isActive !== undefined) { values.push(patch.isActive); set.push(`is_active = $${++i}`); }

  if (set.length === 0) return getDepartment({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `UPDATE departments
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING id, tenant_id, code, name, is_active, created_at`,
      values
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Department code already exists');
    throw e;
  }
}

async function softDeleteDepartment({ tenantId, id }) {
  await getDepartment({ tenantId, id });
  const { rows } = await pool.query(
    `UPDATE departments
     SET is_active = false
     WHERE tenant_id = $1 AND id = $2
     RETURNING id, tenant_id, code, name, is_active, created_at`,
    [tenantId, id]
  );
  return rows[0];
}

module.exports = {
  createDepartment,
  listDepartments,
  getDepartment,
  updateDepartment,
  softDeleteDepartment,
};
