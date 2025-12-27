const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function pid(req) {
  return req.patientUser?.sub || null;
}

async function getOrCreateProfile({ patientAccountId }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  const q = await pool.query(
    `
    SELECT
      patient_account_id AS "patientAccountId",
      full_name AS "fullName",
      date_of_birth AS "dateOfBirth",
      gender,
      marital_status AS "maritalStatus",
      children_count AS "childrenCount",
      phone,
      emergency_phone AS "emergencyPhone",
      emergency_relation AS "emergencyRelation",
      emergency_contact_name AS "emergencyContactName",
      chronic_conditions AS "chronicConditions",
      chronic_medications AS "chronicMedications",
      drug_allergies AS "drugAllergies",
      governorate,
      area,
      address_details AS "addressDetails",
      location_lat AS "locationLat",
      location_lng AS "locationLng",
      primary_doctor_name AS "primaryDoctorName",
      primary_doctor_phone AS "primaryDoctorPhone",
      blood_type AS "bloodType",
      height_cm AS "heightCm",
      weight_kg AS "weightKg",
      created_at AS "createdAt",
      updated_at AS "updatedAt"
    FROM patient_profiles
    WHERE patient_account_id = $1
    LIMIT 1
    `,
    [patientAccountId]
  );

  if (q.rowCount > 0) return q.rows[0];

  // Create empty profile; we also try to seed name/phone/email from patient_accounts if exists
  const seed = await pool.query(
    `
    SELECT full_name AS "fullName", phone
    FROM patient_accounts
    WHERE id = $1
    LIMIT 1
    `,
    [patientAccountId]
  );

  const fullName = seed.rows[0]?.fullName || null;
  const phone = seed.rows[0]?.phone || null;

  const ins = await pool.query(
    `
    INSERT INTO patient_profiles (
      patient_account_id,
      full_name,
      phone,
      created_at,
      updated_at
    )
    VALUES ($1,$2,$3, now(), now())
    RETURNING
      patient_account_id AS "patientAccountId",
      full_name AS "fullName",
      date_of_birth AS "dateOfBirth",
      gender,
      marital_status AS "maritalStatus",
      children_count AS "childrenCount",
      phone,
      emergency_phone AS "emergencyPhone",
      emergency_relation AS "emergencyRelation",
      emergency_contact_name AS "emergencyContactName",
      chronic_conditions AS "chronicConditions",
      chronic_medications AS "chronicMedications",
      drug_allergies AS "drugAllergies",
      governorate,
      area,
      address_details AS "addressDetails",
      location_lat AS "locationLat",
      location_lng AS "locationLng",
      primary_doctor_name AS "primaryDoctorName",
      primary_doctor_phone AS "primaryDoctorPhone",
      blood_type AS "bloodType",
      height_cm AS "heightCm",
      weight_kg AS "weightKg",
      created_at AS "createdAt",
      updated_at AS "updatedAt"
    `,
    [patientAccountId, fullName, phone]
  );

  return ins.rows[0];
}

function _jsonArr(v) {
  if (v === undefined) return undefined;
  if (v === null) return [];
  if (Array.isArray(v)) return v;
  return [];
}

async function patchProfile({ patientAccountId, patch }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  // Ensure exists
  await getOrCreateProfile({ patientAccountId });

  const fields = [];
  const values = [];
  let i = 1;

  const map = {
    fullName: 'full_name',
    dateOfBirth: 'date_of_birth',
    maritalStatus: 'marital_status',
    childrenCount: 'children_count',
    emergencyPhone: 'emergency_phone',
    emergencyRelation: 'emergency_relation',
    emergencyContactName: 'emergency_contact_name',
    chronicConditions: 'chronic_conditions',
    chronicMedications: 'chronic_medications',
    drugAllergies: 'drug_allergies',
    addressDetails: 'address_details',
    locationLat: 'location_lat',
    locationLng: 'location_lng',
    primaryDoctorName: 'primary_doctor_name',
    primaryDoctorPhone: 'primary_doctor_phone',
    bloodType: 'blood_type',
    heightCm: 'height_cm',
    weightKg: 'weight_kg',
  };

  for (const [k, vRaw] of Object.entries(patch || {})) {
    const col = map[k] || k;
    let v = vRaw;

    // normalize empties to null
    if (typeof v === 'string' && v.trim() === '') v = null;

    // json arrays
    if (k === 'chronicConditions') v = JSON.stringify(_jsonArr(v));
    if (k === 'chronicMedications') v = JSON.stringify(_jsonArr(v));
    if (k === 'drugAllergies') v = JSON.stringify(_jsonArr(v));

    if (k === 'chronicConditions' || k === 'chronicMedications' || k === 'drugAllergies') {
      fields.push(`${col} = $${i++}::jsonb`);
      values.push(v);
      continue;
    }

    fields.push(`${col} = $${i++}`);
    values.push(v);
  }

  if (fields.length === 0) throw new HttpError(400, 'No fields to update');

  values.push(patientAccountId);

  const q = await pool.query(
    `
    UPDATE patient_profiles
    SET ${fields.join(', ')},
        updated_at = now()
    WHERE patient_account_id = $${i}
    RETURNING
      patient_account_id AS "patientAccountId",
      full_name AS "fullName",
      date_of_birth AS "dateOfBirth",
      gender,
      marital_status AS "maritalStatus",
      children_count AS "childrenCount",
      phone,
      emergency_phone AS "emergencyPhone",
      emergency_relation AS "emergencyRelation",
      emergency_contact_name AS "emergencyContactName",
      chronic_conditions AS "chronicConditions",
      chronic_medications AS "chronicMedications",
      drug_allergies AS "drugAllergies",
      governorate,
      area,
      address_details AS "addressDetails",
      location_lat AS "locationLat",
      location_lng AS "locationLng",
      primary_doctor_name AS "primaryDoctorName",
      primary_doctor_phone AS "primaryDoctorPhone",
      blood_type AS "bloodType",
      height_cm AS "heightCm",
      weight_kg AS "weightKg",
      created_at AS "createdAt",
      updated_at AS "updatedAt"
    `,
    values
  );

  return q.rows[0];
}

async function buildProfileSnapshot({ patientAccountId }) {
  // snapshot content used during join
  const q = await pool.query(
    `
    SELECT
      pa.id AS "patientAccountId",
      pa.full_name AS "accountFullName",
      pa.email AS "accountEmail",
      pa.phone AS "accountPhone",
      pp.full_name AS "fullName",
      pp.date_of_birth AS "dateOfBirth",
      pp.gender,
      pp.marital_status AS "maritalStatus",
      pp.children_count AS "childrenCount",
      pp.phone,
      pp.emergency_phone AS "emergencyPhone",
      pp.emergency_relation AS "emergencyRelation",
      pp.emergency_contact_name AS "emergencyContactName",
      pp.chronic_conditions AS "chronicConditions",
      pp.chronic_medications AS "chronicMedications",
      pp.drug_allergies AS "drugAllergies",
      pp.governorate,
      pp.area,
      pp.address_details AS "addressDetails",
      pp.location_lat AS "locationLat",
      pp.location_lng AS "locationLng",
      pp.primary_doctor_name AS "primaryDoctorName",
      pp.primary_doctor_phone AS "primaryDoctorPhone",
      pp.blood_type AS "bloodType",
      pp.height_cm AS "heightCm",
      pp.weight_kg AS "weightKg",
      pp.updated_at AS "profileUpdatedAt"
    FROM patient_accounts pa
    LEFT JOIN patient_profiles pp
      ON pp.patient_account_id = pa.id
    WHERE pa.id = $1
    LIMIT 1
    `,
    [patientAccountId]
  );

  return q.rows[0] || { patientAccountId };
}

module.exports = {
  getOrCreateProfile,
  patchProfile,
  buildProfileSnapshot,
  pid,
};
