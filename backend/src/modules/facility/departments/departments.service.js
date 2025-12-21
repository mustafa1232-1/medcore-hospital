const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function isUniqueViolation(e) {
  return e && e.code === '23505';
}

function slugify(input) {
  const s = String(input || '')
    .trim()
    .toUpperCase()
    .replace(/[\u0600-\u06FF]/g, '')
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return s || 'DEP';
}

async function getTenantCode(tenantId) {
  const { rows } = await pool.query(
    `SELECT code FROM tenants WHERE id = $1 LIMIT 1`,
    [tenantId]
  );
  return rows[0]?.code?.toUpperCase() || 'TENANT';
}

async function generateDepartmentCode({ tenantId, name }) {
  const tenantCode = await getTenantCode(tenantId);
  const base = `${tenantCode}-DEP-${slugify(name).slice(0, 20)}`;

  for (let i = 0; i < 50; i++) {
    const code = i === 0 ? base : `${base}-${i + 1}`;
    const chk = await pool.query(
      `SELECT 1 FROM departments WHERE tenant_id = $1 AND code = $2`,
      [tenantId, code]
    );
    if (chk.rowCount === 0) return code;
  }

  return `${base}-${Date.now()}`;
}

async function createDepartment({ tenantId, code, name, isActive }) {
  const finalCode =
    code && code.trim()
      ? code.trim()
      : await generateDepartmentCode({ tenantId, name });

  try {
    const { rows } = await pool.query(
      `INSERT INTO departments (tenant_id, code, name, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, tenant_id, code, name, is_active, created_at`,
      [tenantId, finalCode, name, isActive]
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) {
      throw new HttpError(409, 'Department code already exists');
    }
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
    `SELECT * FROM departments WHERE tenant_id = $1 AND id = $2`,
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

  if (patch.code !== undefined) {
    values.push(patch.code);
    set.push(`code = $${++i}`);
  }
  if (patch.name !== undefined) {
    values.push(patch.name);
    set.push(`name = $${++i}`);
  }
  if (patch.isActive !== undefined) {
    values.push(patch.isActive);
    set.push(`is_active = $${++i}`);
  }

  if (!set.length) return getDepartment({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `UPDATE departments
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING *`,
      values
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) {
      throw new HttpError(409, 'Department code already exists');
    }
    throw e;
  }
}

async function softDeleteDepartment({ tenantId, id }) {
  await getDepartment({ tenantId, id });
  const { rows } = await pool.query(
    `UPDATE departments
     SET is_active = false
     WHERE tenant_id = $1 AND id = $2
     RETURNING *`,
    [tenantId, id]
  );
  return rows[0];
}

// ✅ NEW: activate department + auto create rooms & beds
async function activateDepartmentFromSystemCatalog({
  tenantId,
  systemDepartmentId,
  roomsCount,
  bedsPerRoom,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const sys = await client.query(
      `SELECT id, code, name_ar
       FROM system_departments
       WHERE id = $1 AND is_active = true`,
      [systemDepartmentId]
    );

    if (!sys.rows[0]) {
      throw new HttpError(404, 'System department not found');
    }

    const exists = await client.query(
      `SELECT 1 FROM departments
       WHERE tenant_id = $1 AND system_department_id = $2`,
      [tenantId, systemDepartmentId]
    );
    if (exists.rowCount) {
      throw new HttpError(409, 'Department already activated');
    }

    const depQ = await client.query(
      `INSERT INTO departments
       (tenant_id, system_department_id, code, name, rooms_count, beds_per_room)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, code, name`,
      [
        tenantId,
        systemDepartmentId,
        sys.rows[0].code,
        sys.rows[0].name_ar,
        roomsCount,
        bedsPerRoom,
      ]
    );

    const dep = depQ.rows[0];

    for (let r = 1; r <= roomsCount; r++) {
      const roomCode = `${dep.code}-R${String(r).padStart(2, '0')}`;
      const room = await client.query(
        `INSERT INTO rooms (tenant_id, department_id, code, name)
         VALUES ($1, $2, $3, $4)
         RETURNING id`,
        [tenantId, dep.id, roomCode, `Room ${r}`]
      );

      for (let b = 1; b <= bedsPerRoom; b++) {
        const bedCode = `${roomCode}-B${String(b).padStart(2, '0')}`;
        await client.query(
          `INSERT INTO beds (tenant_id, room_id, code)
           VALUES ($1, $2, $3)`,
          [tenantId, room.rows[0].id, bedCode]
        );
      }
    }

    await client.query('COMMIT');
    return dep;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = {
  createDepartment,
  listDepartments,
  getDepartment,
  updateDepartment,
  softDeleteDepartment,
  activateDepartmentFromSystemCatalog,
};
