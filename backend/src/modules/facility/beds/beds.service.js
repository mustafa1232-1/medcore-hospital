const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function isUniqueViolation(e) {
  return e && e.code === '23505';
}

const allowedTransitions = {
  AVAILABLE: new Set(['OCCUPIED', 'CLEANING', 'MAINTENANCE', 'RESERVED', 'OUT_OF_SERVICE']),
  OCCUPIED: new Set(['CLEANING', 'MAINTENANCE', 'OUT_OF_SERVICE']),
  CLEANING: new Set(['AVAILABLE', 'MAINTENANCE', 'OUT_OF_SERVICE']),
  MAINTENANCE: new Set(['AVAILABLE', 'OUT_OF_SERVICE']),
  RESERVED: new Set(['AVAILABLE', 'OCCUPIED', 'OUT_OF_SERVICE']),
  OUT_OF_SERVICE: new Set(['AVAILABLE', 'MAINTENANCE']),
};

function pad2(n) {
  return String(n).padStart(2, '0');
}

async function ensureRoom({ tenantId, roomId }) {
  const { rows } = await pool.query(
    `SELECT id, code FROM rooms WHERE tenant_id = $1 AND id = $2 AND is_active = true`,
    [tenantId, roomId]
  );
  if (!rows[0]) throw new HttpError(400, 'Invalid roomId');
  return rows[0]; // { id, code }
}

async function generateBedCode({ tenantId, roomId }) {
  const room = await ensureRoom({ tenantId, roomId });
  const roomCode = String(room.code).toUpperCase().trim();
  const base = `${roomCode}-B`;

  const { rows } = await pool.query(
    `
    SELECT code
    FROM beds
    WHERE tenant_id = $1 AND room_id = $2
      AND code LIKE $3
    ORDER BY created_at DESC
    LIMIT 300
    `,
    [tenantId, roomId, `${base}%`]
  );

  let max = 0;
  for (const r of rows) {
    const c = String(r.code || '');
    const m = c.match(/-B(\d{2,})$/);
    if (m) {
      const v = parseInt(m[1], 10);
      if (!Number.isNaN(v)) max = Math.max(max, v);
    }
  }

  for (let step = 1; step <= 50; step++) {
    const code = `${base}${pad2(max + step)}`;
    const ex = await pool.query(
      `SELECT 1 FROM beds WHERE tenant_id = $1 AND code = $2 LIMIT 1`,
      [tenantId, code]
    );
    if (!ex.rows[0]) return code;
  }

  return `${base}${Date.now()}`;
}

async function createBed({ tenantId, roomId, code, status, notes, isActive }) {
  await ensureRoom({ tenantId, roomId });

  const finalCode = (code && String(code).trim())
    ? String(code).trim()
    : await generateBedCode({ tenantId, roomId });

  try {
    const { rows } = await pool.query(
      `INSERT INTO beds (tenant_id, room_id, code, status, notes, is_active)
       VALUES ($1, $2, $3, $4::bed_status, $5, $6)
       RETURNING id, tenant_id, room_id, code, status, notes, is_active, created_at`,
      [tenantId, roomId, finalCode, status, notes, isActive]
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Bed code already exists');
    throw e;
  }
}

async function listBeds({ tenantId, roomId, departmentId, status, active }) {
  const params = [tenantId];
  let where = `b.tenant_id = $1`;

  if (roomId) { params.push(roomId); where += ` AND b.room_id = $${params.length}`; }
  if (status) { params.push(status); where += ` AND b.status = $${params.length}::bed_status`; }
  if (active !== undefined) { params.push(active); where += ` AND b.is_active = $${params.length}`; }

  let join = `JOIN rooms r ON r.id = b.room_id`;
  if (departmentId) {
    params.push(departmentId);
    where += ` AND r.department_id = $${params.length}`;
  }

  const { rows } = await pool.query(
    `SELECT
        b.id, b.tenant_id, b.room_id, b.code, b.status, b.notes, b.is_active, b.created_at,
        r.department_id
     FROM beds b
     ${join}
     WHERE ${where}
     ORDER BY b.code ASC`,
    params
  );
  return rows;
}

async function getBed({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT b.id, b.tenant_id, b.room_id, b.code, b.status, b.notes, b.is_active, b.created_at,
            r.department_id
     FROM beds b
     JOIN rooms r ON r.id = b.room_id
     WHERE b.tenant_id = $1 AND b.id = $2`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Bed not found');
  return rows[0];
}

async function updateBed({ tenantId, id, patch }) {
  await getBed({ tenantId, id });
  if (patch.roomId) await ensureRoom({ tenantId, roomId: patch.roomId });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.roomId !== undefined) { values.push(patch.roomId); set.push(`room_id = $${++i}`); }
  if (patch.code !== undefined) { values.push(patch.code); set.push(`code = $${++i}`); }
  if (patch.notes !== undefined) { values.push(patch.notes); set.push(`notes = $${++i}`); }
  if (patch.isActive !== undefined) { values.push(patch.isActive); set.push(`is_active = $${++i}`); }

  if (set.length === 0) return getBed({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `UPDATE beds
       SET ${set.join(', ')}
       WHERE tenant_id = $1 AND id = $2
       RETURNING id, tenant_id, room_id, code, status, notes, is_active, created_at`,
      values
    );
    return rows[0];
  } catch (e) {
    if (isUniqueViolation(e)) throw new HttpError(409, 'Bed code already exists');
    throw e;
  }
}

async function changeBedStatus({ tenantId, id, nextStatus }) {
  const bed = await getBed({ tenantId, id });
  const current = bed.status;

  if (current === nextStatus) return bed;

  const allowed = allowedTransitions[current] || new Set();
  if (!allowed.has(nextStatus)) {
    throw new HttpError(409, `Invalid transition: ${current} -> ${nextStatus}`);
  }

  // ✅ منع جعل السرير AVAILABLE إذا كان عليه تعيين فعّال
  if (nextStatus === 'AVAILABLE') {
    const activeAssign = await pool.query(
      `
      SELECT 1
      FROM admission_beds ab
      WHERE ab.tenant_id = $1
        AND ab.bed_id = $2
        AND ab.is_active = true
      LIMIT 1
      `,
      [tenantId, id]
    );
    if (activeAssign.rows[0]) {
      throw new HttpError(409, 'لا يمكن جعل السرير AVAILABLE لأنه مرتبط بتنويم فعّال');
    }
  }

  const { rows } = await pool.query(
    `UPDATE beds
     SET status = $3::bed_status
     WHERE tenant_id = $1 AND id = $2
     RETURNING id, tenant_id, room_id, code, status, notes, is_active, created_at`,
    [tenantId, id, nextStatus]
  );
  return rows[0];
}

async function softDeleteBed({ tenantId, id }) {
  await getBed({ tenantId, id });
  const { rows } = await pool.query(
    `UPDATE beds
     SET is_active = false
     WHERE tenant_id = $1 AND id = $2
     RETURNING id, tenant_id, room_id, code, status, notes, is_active, created_at`,
    [tenantId, id]
  );
  return rows[0];
}

module.exports = {
  createBed,
  listBeds,
  getBed,
  updateBed,
  changeBedStatus,
  softDeleteBed,
};
