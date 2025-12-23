const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const PATIENT_JWT_ACCESS_SECRET = process.env.PATIENT_JWT_ACCESS_SECRET || mustEnv('JWT_ACCESS_SECRET');
const PATIENT_JWT_EXPIRES_IN = process.env.PATIENT_JWT_EXPIRES_IN || '30d';

function signPatientAccessToken(payload) {
  return jwt.sign(payload, PATIENT_JWT_ACCESS_SECRET, { expiresIn: PATIENT_JWT_EXPIRES_IN });
}

async function patientLogin({ email, phone, password }) {
  if (!password) throw new HttpError(400, 'password is required');
  if (!email && !phone) throw new HttpError(400, 'email or phone is required');

  const q = await pool.query(
    `
    SELECT id, password_hash AS "passwordHash", full_name AS "fullName"
    FROM patient_accounts
    WHERE ($1::text IS NOT NULL AND email = $1)
       OR ($2::text IS NOT NULL AND phone = $2)
    LIMIT 1
    `,
    [email || null, phone || null]
  );

  if (q.rowCount === 0) throw new HttpError(401, 'Invalid credentials');

  const p = q.rows[0];
  const ok = await bcrypt.compare(password, p.passwordHash);
  if (!ok) throw new HttpError(401, 'Invalid credentials');

  const accessToken = signPatientAccessToken({
    sub: p.id,
    kind: 'PATIENT',
  });

  return {
    ok: true,
    patient: { id: p.id, fullName: p.fullName },
    accessToken,
  };
}

module.exports = { patientLogin };
