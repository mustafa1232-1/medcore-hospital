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
    .replace(/[\u0600-\u06FF]/g, '') // remove Arabic from codes to normalize
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return s || 'X';
}

async function getTenantCode(tenantId) {
  const { rows } = await pool.query(`SELECT code FROM tenants WHERE id = $1 LIMIT 1`, [tenantId]);
  const code = rows[0]?.code;
  return (code ? String(code).toUpperCase().trim() : 'TENANT');
}

async function generateDepartmentCode({ tenantId, systemCode }) {
  const tenantCode = await getTenantCode(tenantId);
  const base = `${tenantCode}-DEP-${slugify(systemCode).slice(0, 20)}`;

  // try base then base-2 base-3...
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

async function getSystemDepartment({ systemDepartmentId, systemDepartmentCode }) {
  if (systemDepartmentId) {
    const { rows } = await pool.query(
      `SELECT id, code, name_ar, name_en, is_active
       FROM system_departments
       WHERE id = $1
       LIMIT 1`,
      [systemDepartmentId]
    );
    return rows[0];
  }
  if (systemDepartmentCode) {
    const code = String(systemDepartmentCode).trim().toUpperCase();
    const { rows } = await pool.query(
      `SELECT id, code, name_ar, name_en, is_active
       FROM system_departments
       WHERE code = $1
       LIMIT 1`,
      [code]
    );
    return rows[0];
  }
  return null;
}

async function createRoomsAndBedsTx({ client, tenantId, departmentId, departmentCode, roomsCount, bedsPerRoom }) {
  const pad2 = (n) => String(n).padStart(2, '0');

  for (let i = 1; i <= roomsCount; i++) {
    const roomCode = `${departmentCode}-R${pad2(i)}`;
    const roomName = `غرفة ${i}`;
    const roomRes = await client.query(
      `INSERT INTO rooms (tenant_id, department_id, code, name, floor, is_active)
       VALUES ($1, $2, $3, $4, NULL, true)
       RETURNING id`,
      [tenantId, departmentId, roomCode, roomName]
    );
    const roomId = roomRes.rows[0].id;

    for (let j = 1; j <= bedsPerRoom; j++) {
      const bedCode = `${roomCode}-B${pad2(j)}`;
      await client.query(
        `INSERT INTO beds (tenant_id, room_id, code, status, notes, is_active)
         VALUES ($1, $2, $3, 'AVAILABLE', NULL, true)`,
        [tenantId, roomId, bedCode]
      );
    }
  }
}

// ---- main
// Activates a department from the fixed system catalog.
// Creates rooms + beds automatically (transactional).
async function createDepartment({ tenantId, systemDepartmentId, systemDepartmentCode, roomsCount, bedsPerRoom, isActive }) {
  const sys = await getSystemDepartment({ systemDepartmentId, systemDepartmentCode });
  if (!sys) throw new HttpError(400, 'Invalid system department');
  if (sys.is_active === false) throw new HttpError(400, 'System department is disabled');

  const finalCode = await generateDepartmentCode({ tenantId, systemCode: sys.code });
  const finalName = sys.name_ar;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // prevent duplicate activation per tenant
    const dup = await client.query(
      `SELECT 1 FROM departments WHERE tenant_id = $1 AND system_department_id = $2 LIMIT 1`,
      [tenantId, sys.id]
    );
    if (dup.rowCount > 0) {
      throw new HttpError(409, 'Department already activated');
    }

    const ins = await client.query(
      `INSERT INTO departments (tenant_id, system_department_id, code, name, is_active, rooms_count, beds_per_room)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, tenant_id, system_department_id, code, name, is_active, rooms_count, beds_per_room, created_at`,
      [tenantId, sys.id, finalCode, finalName, isActive, roomsCount, bedsPerRoom]
    );
    const dep = ins.rows[0];

    await createRoomsAndBedsTx({
      client,
      tenantId,
      departmentId: dep.id,
      departmentCode: dep.code,
      roomsCount,
      bedsPerRoom,
    });

    await client.query('COMMIT');
    return dep;
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    if (e instanceof HttpError) throw e;
    if (isUniqueViolation(e)) throw new HttpError(409, 'Department code already exists');
    throw e;
  } finally {
    client.release();
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
    `SELECT d.id,
            d.tenant_id,
            d.system_department_id,
            d.code,
            d.name,
            d.is_active,
            d.rooms_count,
            d.beds_per_room,
            d.created_at,
            sd.code AS system_code,
            sd.name_ar AS system_name_ar
     FROM departments d
     LEFT JOIN system_departments sd ON sd.id = d.system_department_id
     WHERE ${where}
     ORDER BY d.name ASC`,
    params
  );
  return rows;
}

async function getDepartment({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT d.id,
            d.tenant_id,
            d.system_department_id,
            d.code,
            d.name,
            d.is_active,
            d.rooms_count,
            d.beds_per_room,
            d.created_at,
            sd.code AS system_code,
            sd.name_ar AS system_name_ar
     FROM departments d
     LEFT JOIN system_departments sd ON sd.id = d.system_department_id
     WHERE d.tenant_id = $1 AND d.id = $2`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Department not found');
  return rows[0];
}

async function updateDepartment({ tenantId, id, patch }) {
  await getDepartment({ tenantId, id });

  // In the fixed-catalog design, code/name are derived. Prevent mutation for safety.
  if (patch.code !== undefined || patch.name !== undefined) {
    throw new HttpError(400, 'Department code/name are managed by system catalog');
  }

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.isActive !== undefined) { values.push(patch.isActive); set.push(`is_active = $${++i}`); }
  if (patch.roomsCount !== undefined) { values.push(patch.roomsCount); set.push(`rooms_count = $${++i}`); }
  if (patch.bedsPerRoom !== undefined) { values.push(patch.bedsPerRoom); set.push(`beds_per_room = $${++i}`); }

  if (set.length === 0) return getDepartment({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `UPDATE departments
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING id, tenant_id, system_department_id, code, name, is_active, rooms_count, beds_per_room, created_at`,
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
