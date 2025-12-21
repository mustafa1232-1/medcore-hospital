const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function isUniqueViolation(e) {
  return e && e.code === '23505';
}

async function ensureDepartment({ tenantId, departmentId }) {
  const { rows } = await pool.query(
    `SELECT id, code FROM departments WHERE tenant_id = $1 AND id = $2 AND is_active = true`,
    [tenantId, departmentId]
  );
  if (!rows[0]) throw new HttpError(400, 'Invalid departmentId');
  return rows[0]; // { id, code }
}

function pad2(n) {
  return String(n).padStart(2, '0');
}

async function generateRoomCode({ tenantId, departmentId }) {
  const dep = await ensureDepartment({ tenantId, departmentId });
  const depCode = String(dep.code).toUpperCase().trim();
  const base = `${depCode}-R`;

  // ابحث عن أعلى رقم موجود ضمن نفس القسم
  const { rows } = await pool.query(
    `
    SELECT code
    FROM rooms
    WHERE tenant_id = $1 AND department_id = $2
      AND code LIKE $3
    ORDER BY created_at DESC
    LIMIT 200
    `,
    [tenantId, departmentId, `${base}%`]
  );

  let max = 0;
  for (const r of rows) {
    const c = String(r.code || '');
    const m = c.match(/-R(\d{2,})$/);
    if (m) {
      const v = parseInt(m[1], 10);
      if (!Number.isNaN(v)) max = Math.max(max, v);
    }
  }

  // جرّب max+1، وإذا حصل تعارض (نادر) نزيد ونكرر
  for (let step = 1; step <= 50; step++) {
    const code = `${base}${pad2(max + step)}`;
    const ex = await pool.query(
      `SELECT 1 FROM rooms WHERE tenant_id = $1 AND code = $2 LIMIT 1`,
      [tenantId, code]
    );
    if (!ex.rows[0]) return code;
  }

  return `${base}${Date.now()}`;
}

async function createRoom({ tenantId, departmentId, code, name, floor, isActive }) {
  await ensureDepartment({ tenantId, departmentId });

  const finalCode = (code && String(code).trim())
    ? String(code).trim()
    : await generateRoomCode({ tenantId, departmentId });

  try {
    const { rows } = await pool.query(
      `INSERT INTO rooms (tenant_id, department_id, code, name, floor, is_active)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
      [tenantId, departmentId, finalCode, name, floor, isActive]
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Room code already exists');
    throw e;
  }
}

async function listRooms({ tenantId, departmentId, q, active }) {
  const params = [tenantId];
  let where = `tenant_id = $1`;

  if (departmentId) { params.push(departmentId); where += ` AND department_id = $${params.length}`; }
  if (q) { params.push(`%${q}%`); where += ` AND (code ILIKE $${params.length} OR name ILIKE $${params.length})`; }
  if (active !== undefined) { params.push(active); where += ` AND is_active = $${params.length}`; }

  const { rows } = await pool.query(
    `SELECT id, tenant_id, department_id, code, name, floor, is_active, created_at
     FROM rooms
     WHERE ${where}
     ORDER BY name ASC`,
    params
  );
  return rows;
}

async function getRoom({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, tenant_id, department_id, code, name, floor, is_active, created_at
     FROM rooms
     WHERE tenant_id = $1 AND id = $2`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Room not found');
  return rows[0];
}

async function updateRoom({ tenantId, id, patch }) {
  await getRoom({ tenantId, id });
  if (patch.departmentId) await ensureDepartment({ tenantId, departmentId: patch.departmentId });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.departmentId !== undefined) { values.push(patch.departmentId); set.push(`department_id = $${++i}`); }
  if (patch.code !== undefined) { values.push(patch.code); set.push(`code = $${++i}`); }
  if (patch.name !== undefined) { values.push(patch.name); set.push(`name = $${++i}`); }
  if (patch.floor !== undefined) { values.push(patch.floor); set.push(`floor = $${++i}`); }
  if (patch.isActive !== undefined) { values.push(patch.isActive); set.push(`is_active = $${++i}`); }

  if (set.length === 0) return getRoom({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `UPDATE rooms
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
      values
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Room code already exists');
    throw e;
  }
}

async function softDeleteRoom({ tenantId, id }) {
  await getRoom({ tenantId, id });
  const { rows } = await pool.query(
    `UPDATE rooms
     SET is_active = false
     WHERE tenant_id = $1 AND id = $2
     RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
    [tenantId, id]
  );
  return rows[0];
}

module.exports = { createRoom, listRooms, getRoom, updateRoom, softDeleteRoom };
