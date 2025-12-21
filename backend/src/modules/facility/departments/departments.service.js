// src/modules/facility/departments/departments.service.js
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

function toPosInt(v, def = 1) {
  const n = Number.parseInt(String(v ?? ''), 10);
  if (Number.isFinite(n) && n >= 1) return n;
  return def;
}

function normalizeRoles(raw) {
  const arr = Array.isArray(raw) ? raw : [];
  return arr
    .map(r => (typeof r === 'string' ? r : r?.name))
    .filter(Boolean)
    .map(x => String(x).toUpperCase().trim());
}

function hasRole(actorRoles, role) {
  const r = String(role).toUpperCase().trim();
  return normalizeRoles(actorRoles).includes(r);
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
    code && String(code).trim()
      ? String(code).trim()
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
    `SELECT id, tenant_id, code, name, is_active, created_at,
            system_department_id, rooms_count, beds_per_room
     FROM departments
     WHERE ${where}
     ORDER BY name ASC`,
    params
  );
  return rows;
}

async function getDepartment({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, tenant_id, code, name, is_active, created_at,
            system_department_id, rooms_count, beds_per_room
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
       RETURNING id, tenant_id, code, name, is_active, created_at,
                 system_department_id, rooms_count, beds_per_room`,
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
     RETURNING id, tenant_id, code, name, is_active, created_at,
               system_department_id, rooms_count, beds_per_room`,
    [tenantId, id]
  );
  return rows[0];
}

// ✅ Activate department + auto create rooms & beds (with defaults)
async function activateDepartmentFromSystemCatalog({
  tenantId,
  systemDepartmentId,
  roomsCount,
  bedsPerRoom,
}) {
  const rc = toPosInt(roomsCount, 1);
  const br = toPosInt(bedsPerRoom, 1);

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
       (tenant_id, system_department_id, code, name, rooms_count, beds_per_room, is_active, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, true, now())
       RETURNING id, tenant_id, code, name, is_active,
                 system_department_id, rooms_count, beds_per_room, created_at`,
      [
        tenantId,
        systemDepartmentId,
        String(sys.rows[0].code).toUpperCase().trim(),
        sys.rows[0].name_ar,
        rc,
        br,
      ]
    );

    const dep = depQ.rows[0];

    for (let r = 1; r <= rc; r++) {
      const roomCode = `${dep.code}-R${String(r).padStart(2, '0')}`;

      const roomQ = await client.query(
        `INSERT INTO rooms (tenant_id, department_id, code, name, is_active, created_at)
         VALUES ($1, $2, $3, $4, true, now())
         RETURNING id`,
        [tenantId, dep.id, roomCode, `Room ${r}`]
      );

      const roomId = roomQ.rows[0].id;

      for (let b = 1; b <= br; b++) {
        const bedCode = `${roomCode}-B${String(b).padStart(2, '0')}`;
        await client.query(
          `INSERT INTO beds (tenant_id, room_id, code, status, is_active, created_at)
           VALUES ($1, $2, $3, 'AVAILABLE'::bed_status, true, now())`,
          [tenantId, roomId, bedCode]
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

// =======================
// ✅ Department Overview
// =======================
async function listStaffByRole({ tenantId, departmentId, roleName }) {
  const roleUpper = String(roleName || '').toUpperCase().trim();

  const { rows } = await pool.query(
    `
    SELECT
      u.id,
      u.full_name AS "fullName",
      u.staff_code AS "staffCode",
      u.email,
      u.phone
    FROM users u
    WHERE u.tenant_id = $1
      AND u.is_active = true
      AND u.department_id = $2
      AND EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = u.id
          AND r.tenant_id = u.tenant_id
          AND UPPER(r.name) = $3
      )
    ORDER BY u.full_name ASC
    `,
    [tenantId, departmentId, roleUpper]
  );

  return rows;
}

async function listRoomsBedsOccupancy({ tenantId, departmentId }) {
  const { rows } = await pool.query(
    `
    SELECT
      r.id AS "roomId",
      r.code AS "roomCode",
      r.name AS "roomName",
      r.floor AS "roomFloor",

      b.id AS "bedId",
      b.code AS "bedCode",
      b.status AS "bedStatus",

      a.id AS "admissionId",
      a.status AS "admissionStatus",

      p.id AS "patientId",
      p.full_name AS "patientFullName",
      p.phone AS "patientPhone"
    FROM rooms r
    JOIN beds b
      ON b.room_id = r.id
      AND b.tenant_id = $1
      AND b.is_active = true
    LEFT JOIN admission_beds ab
      ON ab.bed_id = b.id
      AND ab.tenant_id = $1
      AND ab.is_active = true
    LEFT JOIN admissions a
      ON a.id = ab.admission_id
      AND a.tenant_id = $1
      AND a.status IN ('ACTIVE', 'PENDING')
    LEFT JOIN patients p
      ON p.id = a.patient_id
      AND p.tenant_id = $1
    WHERE r.tenant_id = $1
      AND r.department_id = $2
      AND r.is_active = true
    ORDER BY r.code ASC, b.code ASC
    `,
    [tenantId, departmentId]
  );

  const map = new Map();

  for (const x of rows) {
    if (!map.has(x.roomId)) {
      map.set(x.roomId, {
        id: x.roomId,
        code: x.roomCode,
        name: x.roomName,
        floor: x.roomFloor,
        beds: [],
      });
    }

    const room = map.get(x.roomId);
    room.beds.push({
      id: x.bedId,
      code: x.bedCode,
      status: x.bedStatus,
      occupant: x.patientId
        ? {
            admissionId: x.admissionId,
            admissionStatus: x.admissionStatus,
            patientId: x.patientId,
            patientFullName: x.patientFullName,
            patientPhone: x.patientPhone,
          }
        : null,
    });
  }

  return Array.from(map.values());
}

async function getDepartmentOverview({ tenantId, departmentId }) {
  const dep = await getDepartment({ tenantId, id: departmentId });

  const [doctors, nurses, rooms] = await Promise.all([
    listStaffByRole({ tenantId, departmentId, roleName: 'DOCTOR' }),
    listStaffByRole({ tenantId, departmentId, roleName: 'NURSE' }),
    listRoomsBedsOccupancy({ tenantId, departmentId }),
  ]);

  return {
    department: dep,
    staff: { doctors, nurses },
    rooms,
  };
}

// =======================
// ✅ NEW: Transfer / Remove staff with rules
// =======================
async function getUserRolesById({ tenantId, userId }) {
  const { rows } = await pool.query(
    `
    SELECT r.name
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = $1
      AND r.tenant_id = $2
    ORDER BY r.name
    `,
    [userId, tenantId]
  );
  return rows.map(x => String(x.name).toUpperCase().trim());
}

async function getUserOr404({ tenantId, userId }) {
  const { rows } = await pool.query(
    `
    SELECT id, tenant_id AS "tenantId", full_name AS "fullName",
           is_active AS "isActive", department_id AS "departmentId"
    FROM users
    WHERE tenant_id = $1 AND id = $2
    LIMIT 1
    `,
    [tenantId, userId]
  );
  if (!rows[0]) throw new HttpError(404, 'User not found');
  return rows[0];
}

function enforceStaffChangePolicy({ actor, targetRoles, targetUserId }) {
  const actorRoles = actor?.roles || [];
  const actorId = actor?.userId;

  const isAdmin = hasRole(actorRoles, 'ADMIN');
  if (isAdmin) return;

  const isDoctor = hasRole(actorRoles, 'DOCTOR');
  if (!isDoctor) throw new HttpError(403, 'Forbidden');

  // Doctor cannot change self
  if (actorId && actorId === targetUserId) {
    throw new HttpError(403, 'Doctor cannot change own department');
  }

  // Doctor can only move/remove nurses
  const targetIsNurse = (targetRoles || []).includes('NURSE');
  const targetIsDoctor = (targetRoles || []).includes('DOCTOR') || (targetRoles || []).includes('ADMIN');

  if (!targetIsNurse || targetIsDoctor) {
    throw new HttpError(403, 'Doctor can manage nurses only');
  }
}

async function transferStaffBetweenDepartments({
  tenantId,
  fromDepartmentId,
  staffUserId,
  toDepartmentId,
  actor,
}) {
  if (String(fromDepartmentId) === String(toDepartmentId)) {
    throw new HttpError(409, 'toDepartmentId must be different');
  }

  // ensure departments exist (and same tenant)
  await getDepartment({ tenantId, id: fromDepartmentId });
  await getDepartment({ tenantId, id: toDepartmentId });

  const user = await getUserOr404({ tenantId, userId: staffUserId });
  if (!user.isActive) throw new HttpError(409, 'User is inactive');

  // ensure user currently belongs to fromDepartmentId
  if (String(user.departmentId || '') !== String(fromDepartmentId)) {
    throw new HttpError(409, 'User is not assigned to this department');
  }

  const targetRoles = await getUserRolesById({ tenantId, userId: staffUserId });

  enforceStaffChangePolicy({
    actor,
    targetRoles,
    targetUserId: staffUserId,
  });

  const { rows } = await pool.query(
    `
    UPDATE users
    SET department_id = $1
    WHERE tenant_id = $2 AND id = $3
    RETURNING id, department_id AS "departmentId"
    `,
    [toDepartmentId, tenantId, staffUserId]
  );

  return {
    ok: true,
    staffUserId,
    fromDepartmentId,
    toDepartmentId,
    updated: rows[0] || null,
  };
}

async function removeStaffFromDepartment({
  tenantId,
  departmentId,
  staffUserId,
  actor,
}) {
  await getDepartment({ tenantId, id: departmentId });

  const user = await getUserOr404({ tenantId, userId: staffUserId });
  if (!user.isActive) throw new HttpError(409, 'User is inactive');

  if (String(user.departmentId || '') !== String(departmentId)) {
    throw new HttpError(409, 'User is not assigned to this department');
  }

  const targetRoles = await getUserRolesById({ tenantId, userId: staffUserId });

  enforceStaffChangePolicy({
    actor,
    targetRoles,
    targetUserId: staffUserId,
  });

  const { rows } = await pool.query(
    `
    UPDATE users
    SET department_id = NULL
    WHERE tenant_id = $1 AND id = $2
    RETURNING id, department_id AS "departmentId"
    `,
    [tenantId, staffUserId]
  );

  return {
    ok: true,
    staffUserId,
    departmentId,
    updated: rows[0] || null,
  };
}

module.exports = {
  createDepartment,
  listDepartments,
  getDepartment,
  updateDepartment,
  softDeleteDepartment,
  activateDepartmentFromSystemCatalog,

  getDepartmentOverview,

  // ✅ new staff actions
  transferStaffBetweenDepartments,
  removeStaffFromDepartment,
};
