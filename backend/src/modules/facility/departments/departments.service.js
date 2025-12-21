const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function isUniqueViolation(e) {
  return e && e.code === '23505';
}

// ---- helpers
function slugify(input) {
  const s = String(input || '')
    .trim()
    .toUpperCase()
    .replace(/[\u0600-\u06FF]/g, '') // إزالة العربية من الكود (اختياري) لتوحيد الأكواد
    .replace(/[^A-Z0-9]+/g, '-')     // غير الحروف/الأرقام إلى "-"
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

  return s || 'DEP';
}

async function getTenantCode(tenantId) {
  const { rows } = await pool.query(`SELECT code FROM tenants WHERE id = $1 LIMIT 1`, [tenantId]);
  const code = rows[0]?.code;
  return (code ? String(code).toUpperCase().trim() : 'TENANT');
}

async function generateDepartmentCode({ tenantId, name }) {
  const tenantCode = await getTenantCode(tenantId);
  const base = `${tenantCode}-DEP-${slugify(name).slice(0, 20)}`;

  // جرّب base ثم base-2 base-3...
  for (let n = 0; n < 50; n++) {
    const code = n === 0 ? base : `${base}-${n + 1}`;
    const { rows } = await pool.query(
      `SELECT 1 FROM departments WHERE tenant_id = $1 AND code = $2 LIMIT 1`,
      [tenantId, code]
    );
    if (!rows[0]) return code;
  }
  // fallback نادر
  return `${base}-${Date.now()}`;
}

// ---- main
async function createDepartment({ tenantId, code, name, isActive }) {
  const finalCode = (code && String(code).trim()) ? String(code).trim() : await generateDepartmentCode({ tenantId, name });

  try {
    const { rows } = await pool.query(
      `INSERT INTO departments (tenant_id, code, name, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, tenant_id, code, name, is_active, created_at`,
      [tenantId, finalCode, name, isActive]
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
