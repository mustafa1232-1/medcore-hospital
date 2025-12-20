// src/modules/patients/patients.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function listPatients({ tenantId, q }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const search = q ? `%${String(q).toLowerCase()}%` : null;

  const params = [tenantId];
  let where = 'p.tenant_id = $1';

  if (search) {
    params.push(search);
    where += ` AND (
      LOWER(p.full_name) LIKE $${params.length}
      OR p.phone LIKE $${params.length}
    )`;
  }

  const sql = `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.is_active AS "isActive",
      p.created_at AS "createdAt"
    FROM patients p
    WHERE ${where}
    ORDER BY p.created_at DESC
    LIMIT 100
  `;

  const { rows } = await pool.query(sql, params);
  return rows;
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
    // Unique violation
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
  let i = 1;

  for (const [key, val] of Object.entries(data)) {
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
    fields.push(`${col} = $${i++}`);
    values.push(val);
  }

  if (fields.length === 0) throw new HttpError(400, 'No fields to update');

  values.push(patientId, tenantId);

  const q = await pool.query(
    `
    UPDATE patients
    SET ${fields.join(', ')}
    WHERE id = $${i++} AND tenant_id = $${i}
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

/**
 * ✅ مهم جداً:
 * لازم يكون export بهذا الشكل، وإلا سيظهر عندك createPatient is not a function
 */
module.exports = {
  listPatients,
  createPatient,
  getPatientById,
  updatePatient,
};
