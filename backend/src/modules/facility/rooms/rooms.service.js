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

// ✅ Room used once if any bed in it ever appeared in admission_beds
async function roomUsedOnce({ tenantId, roomId }) {
  const q = await pool.query(
    `
    SELECT 1
    FROM beds b
    JOIN admission_beds ab
      ON ab.bed_id = b.id
     AND ab.tenant_id = $1
    WHERE b.tenant_id = $1
      AND b.room_id = $2
    LIMIT 1
    `,
    [tenantId, roomId]
  );
  return q.rowCount > 0;
}

async function generateRoomCode({ tenantId, departmentId }) {
  const dep = await ensureDepartment({ tenantId, departmentId });
  const depCode = String(dep.code).toUpperCase().trim();
  const base = `${depCode}-R`;

  // keep your approach (recent scan), but it works.
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

  const finalCode =
    code && String(code).trim()
      ? String(code).trim()
      : await generateRoomCode({ tenantId, departmentId });

  try {
    const { rows } = await pool.query(
      `INSERT INTO rooms (tenant_id, department_id, code, name, floor, is_active)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
      [tenantId, departmentId, finalCode, name, floor, isActive]
    );

    const usedOnce = false;
    return { ...rows[0], usedOnce, canEdit: true, canDelete: true };
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Room code already exists');
    throw e;
  }
}

async function listRooms({ tenantId, departmentId, q, active }) {
  const params = [tenantId];
  let where = `r.tenant_id = $1`;

  if (departmentId) {
    params.push(departmentId);
    where += ` AND r.department_id = $${params.length}`;
  }
  if (q) {
    params.push(`%${q}%`);
    where += ` AND (r.code ILIKE $${params.length} OR r.name ILIKE $${params.length})`;
  }
  if (active !== undefined) {
    params.push(active);
    where += ` AND r.is_active = $${params.length}`;
  }

  const { rows } = await pool.query(
    `
    SELECT
      r.id, r.tenant_id, r.department_id, r.code, r.name, r.floor, r.is_active, r.created_at,
      EXISTS (
        SELECT 1
        FROM beds b
        JOIN admission_beds ab
          ON ab.bed_id = b.id
         AND ab.tenant_id = $1
        WHERE b.tenant_id = $1
          AND b.room_id = r.id
        LIMIT 1
      ) AS "usedOnce"
    FROM rooms r
    WHERE ${where}
    ORDER BY r.name ASC
    `,
    params
  );

  return rows.map((r) => ({
    ...r,
    canEdit: !r.usedOnce,
    canDelete: !r.usedOnce,
  }));
}

async function getRoom({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, tenant_id, department_id, code, name, floor, is_active, created_at
     FROM rooms
     WHERE tenant_id = $1 AND id = $2`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Room not found');

  const usedOnce = await roomUsedOnce({ tenantId, roomId: id });
  return { ...rows[0], usedOnce, canEdit: !usedOnce, canDelete: !usedOnce };
}

async function updateRoom({ tenantId, id, patch }) {
  await getRoom({ tenantId, id });

  // ✅ safety: block updates if used once (even if only changing isActive/name/floor/code/department)
  const usedOnce = await roomUsedOnce({ tenantId, roomId: id });
  if (usedOnce) throw new HttpError(403, 'Room cannot be modified because it was used before');

  if (patch.departmentId) {
    await ensureDepartment({ tenantId, departmentId: patch.departmentId });
  }

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.departmentId !== undefined) {
    values.push(patch.departmentId);
    set.push(`department_id = $${++i}`);
  }
  if (patch.code !== undefined) {
    values.push(patch.code);
    set.push(`code = $${++i}`);
  }
  if (patch.name !== undefined) {
    values.push(patch.name);
    set.push(`name = $${++i}`);
  }
  if (patch.floor !== undefined) {
    values.push(patch.floor);
    set.push(`floor = $${++i}`);
  }
  if (patch.isActive !== undefined) {
    values.push(patch.isActive);
    set.push(`is_active = $${++i}`);
  }

  if (set.length === 0) {
    const r = await getRoom({ tenantId, id });
    return r;
  }

  try {
    const { rows } = await pool.query(
      `UPDATE rooms
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
      values
    );
    return { ...rows[0], usedOnce: false, canEdit: true, canDelete: true };
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Room code already exists');
    throw e;
  }
}

async function softDeleteRoom({ tenantId, id }) {
  await getRoom({ tenantId, id });

  // ✅ safety: block delete if used once
  const usedOnce = await roomUsedOnce({ tenantId, roomId: id });
  if (usedOnce) throw new HttpError(403, 'Room cannot be deleted because it was used before');

  // (optional) also block delete if it still has beds (even unused) – recommended
  const hasBeds = await pool.query(
    `SELECT 1 FROM beds WHERE tenant_id = $1 AND room_id = $2 LIMIT 1`,
    [tenantId, id]
  );
  if (hasBeds.rowCount > 0) {
    throw new HttpError(403, 'Room cannot be deleted because it still has beds');
  }

  const { rows } = await pool.query(
    `UPDATE rooms
     SET is_active = false
     WHERE tenant_id = $1 AND id = $2
     RETURNING id, tenant_id, department_id, code, name, floor, is_active, created_at`,
    [tenantId, id]
  );
  return { ...rows[0], usedOnce: false, canEdit: true, canDelete: true };
}

module.exports = { createRoom, listRooms, getRoom, updateRoom, softDeleteRoom };
