const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const PATIENT_JWT_ACCESS_SECRET =
  process.env.PATIENT_JWT_ACCESS_SECRET || mustEnv('JWT_ACCESS_SECRET');
const PATIENT_JWT_EXPIRES_IN = process.env.PATIENT_JWT_EXPIRES_IN || '30d';

function signPatientAccessToken(payload) {
  return jwt.sign(payload, PATIENT_JWT_ACCESS_SECRET, {
    expiresIn: PATIENT_JWT_EXPIRES_IN,
  });
}

function normalizeEmail(v) {
  const s = String(v || '').trim().toLowerCase();
  return s || null;
}

function normalizePhone(v) {
  const s = String(v || '').trim();
  return s || null;
}

async function patientRegister({ fullName, email, phone, password }) {
  const safeName = String(fullName || '').trim();
  const safeEmail = normalizeEmail(email);
  const safePhone = normalizePhone(phone);

  if (!safeName) throw new HttpError(400, 'fullName is required');
  if (!password || String(password).length < 6)
    throw new HttpError(400, 'password must be at least 6 chars');
  if (!safeEmail && !safePhone)
    throw new HttpError(400, 'email or phone is required');

  // uniqueness check
  const existsQ = await pool.query(
    `
    SELECT id
    FROM patient_accounts
    WHERE ($1::text IS NOT NULL AND email = $1)
       OR ($2::text IS NOT NULL AND phone = $2)
    LIMIT 1
    `,
    [safeEmail, safePhone]
  );
  if (existsQ.rowCount > 0) throw new HttpError(409, 'Account already exists');

  const hash = await bcrypt.hash(String(password), 10);

  const ins = await pool.query(
    `
    INSERT INTO patient_accounts (
      full_name,
      email,
      phone,
      password_hash,
      created_at
    )
    VALUES ($1,$2,$3,$4, now())
    RETURNING
      id,
      full_name AS "fullName",
      email,
      phone,
      created_at AS "createdAt"
    `,
    [safeName, safeEmail, safePhone, hash]
  );

  const patient = ins.rows[0];

  const accessToken = signPatientAccessToken({
    sub: patient.id,
    kind: 'PATIENT',
  });

  return { ok: true, patient, accessToken };
}

async function patientLogin({ email, phone, password }) {
  if (!password) throw new HttpError(400, 'password is required');

  const safeEmail = normalizeEmail(email);
  const safePhone = normalizePhone(phone);

  if (!safeEmail && !safePhone) throw new HttpError(400, 'email or phone is required');

  const q = await pool.query(
    `
    SELECT
      id,
      password_hash AS "passwordHash",
      full_name AS "fullName",
      email,
      phone
    FROM patient_accounts
    WHERE ($1::text IS NOT NULL AND email = $1)
       OR ($2::text IS NOT NULL AND phone = $2)
    LIMIT 1
    `,
    [safeEmail, safePhone]
  );

  if (q.rowCount === 0) throw new HttpError(401, 'Invalid credentials');

  const p = q.rows[0];
  const ok = await bcrypt.compare(String(password), p.passwordHash);
  if (!ok) throw new HttpError(401, 'Invalid credentials');

  const accessToken = signPatientAccessToken({
    sub: p.id,
    kind: 'PATIENT',
  });

  return {
    ok: true,
    patient: { id: p.id, fullName: p.fullName, email: p.email, phone: p.phone },
    accessToken,
  };
}

async function patientMe({ patientAccountId }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  const q = await pool.query(
    `
    SELECT
      id,
      full_name AS "fullName",
      email,
      phone,
      created_at AS "createdAt"
    FROM patient_accounts
    WHERE id = $1
    LIMIT 1
    `,
    [patientAccountId]
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient account not found');
  return { ok: true, patient: q.rows[0] };
}

module.exports = {
  patientRegister,
  patientLogin,
  patientMe,
};
