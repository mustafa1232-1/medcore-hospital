// src/modules/patients/patients.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function toBool(v) {
  if (v === undefined || v === null || v === '') return undefined;
  if (typeof v === 'boolean') return v;
  const s = String(v).toLowerCase();
  if (s === 'true') return true;
  if (s === 'false') return false;
  return undefined;
}

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

async function listPatients(input) {
  const {
    tenantId,

    // ✅ الجديد
    query,

    // ✅ القديم (للتوافق وعدم كسر أي استدعاء قديم)
    q: qOld,
    phone: phoneOld,
    gender: genderOld,
    isActive: isActiveOld,
    dobFrom: dobFromOld,
    dobTo: dobToOld,
    createdFrom: createdFromOld,
    createdTo: createdToOld,
    limit: limitOld,
    offset: offsetOld,
  } = input || {};

  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  // ✅ مصدر القيم: query أولاً، وإذا غير موجود نرجع للقديم
  const q = query?.q ?? qOld;
  const phone = query?.phone ?? phoneOld;
  const gender = query?.gender ?? genderOld;
  const isActive = query?.isActive ?? isActiveOld;
  const dobFrom = query?.dobFrom ?? dobFromOld;
  const dobTo = query?.dobTo ?? dobToOld;
  const createdFrom = query?.createdFrom ?? createdFromOld;
  const createdTo = query?.createdTo ?? createdToOld;
  const limit = query?.limit ?? limitOld;
  const offset = query?.offset ?? offsetOld;

  const where = ['p.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  // q: search by name or phone (case-insensitive)
  if (q) {
    params.push(`%${String(q).toLowerCase()}%`);
    where.push(`(LOWER(p.full_name) LIKE $${i} OR p.phone LIKE $${i})`);
    i++;
  }

  // phone contains
  if (phone) {
    params.push(`%${String(phone)}%`);
    where.push(`p.phone LIKE $${i}`);
    i++;
  }

  // gender exact
  if (gender) {
    params.push(String(gender));
    where.push(`p.gender = $${i}`);
    i++;
  }

  // isActive exact
  const activeBool = toBool(isActive);
  if (activeBool !== undefined) {
    params.push(activeBool);
    where.push(`p.is_active = $${i}`);
    i++;
  }

  // date_of_birth range
  if (dobFrom) {
    params.push(dobFrom);
    where.push(`p.date_of_birth >= $${i}::date`);
    i++;
  }
  if (dobTo) {
    params.push(dobTo);
    where.push(`p.date_of_birth <= $${i}::date`);
    i++;
  }

  // created_at range
  if (createdFrom) {
    params.push(createdFrom);
    where.push(`p.created_at >= $${i}::timestamptz`);
    i++;
  }
  if (createdTo) {
    params.push(createdTo);
    where.push(`p.created_at <= $${i}::timestamptz`);
    i++;
  }

  const safeLimit = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  // count
  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM patients p WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  // list
  params.push(safeLimit, safeOffset);

  const listSql = `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.national_id AS "nationalId",
      p.address,
      p.notes,
      p.is_active AS "isActive",
      p.created_at AS "createdAt"
    FROM patients p
    WHERE ${where.join(' AND ')}
    ORDER BY p.created_at DESC
    LIMIT $${i} OFFSET $${i + 1}
  `;

  const { rows } = await pool.query(listSql, params);

  return {
    items: rows,
    meta: {
      total,
      limit: safeLimit,
      offset: safeOffset,
    },
  };
}

async function createPatient(tenantId, data) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const {
    fullName,
    phone,
    email,
    gender,
    dateOfBirth,
    nationalId,
    address,
    notes,
  } = data;

  try {
    const q = await pool.query(
      `
      INSERT INTO patients (
        tenant_id,
        full_name,
        phone,
        email,
        gender,
        date_of_birth,
        national_id,
        address,
        notes,
        created_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,now())
      RETURNING
        id,
        full_name AS "fullName",
        phone,
        email,
        gender,
        date_of_birth AS "dateOfBirth",
        national_id AS "nationalId",
        address,
        notes,
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      [
        tenantId,
        fullName,
        phone || null,
        email || null,
        gender || null,
        dateOfBirth || null,
        nationalId || null,
        address || null,
        notes || null,
      ]
    );

    return q.rows[0];
  } catch (err) {
    if (err && err.code === '23505') {
      throw new HttpError(409, 'Patient already exists');
    }
    throw err;
  }
}

async function getPatientById(tenantId, patientId) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const q = await pool.query(
    `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.national_id AS "nationalId",
      p.address,
      p.notes,
      p.is_active AS "isActive",
      p.created_at AS "createdAt"
    FROM patients p
    WHERE p.id = $1 AND p.tenant_id = $2
    LIMIT 1
    `,
    [patientId, tenantId]
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found');
  return q.rows[0];
}

async function updatePatient(tenantId, patientId, data) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const fields = [];
  const values = [];
  let idx = 1;

  for (const [key, value] of Object.entries(data)) {
    let col;
    switch (key) {
      case 'fullName':
        col = 'full_name';
        break;
      case 'dateOfBirth':
        col = 'date_of_birth';
        break;
      case 'nationalId':
        col = 'national_id';
        break;
      default:
        col = key;
    }

    fields.push(`${col} = $${idx++}`);
    values.push(value);
  }

  if (fields.length === 0) throw new HttpError(400, 'No fields to update');

  values.push(patientId, tenantId);

  const q = await pool.query(
    `
    UPDATE patients
    SET ${fields.join(', ')}
    WHERE id = $${idx++} AND tenant_id = $${idx}
    RETURNING
      id,
      full_name AS "fullName",
      phone,
      email,
      gender,
      date_of_birth AS "dateOfBirth",
      national_id AS "nationalId",
      address,
      notes,
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    values
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found');
  return q.rows[0];
}

module.exports = {
  listPatients,
  createPatient,
  getPatientById,
  updatePatient,
};
