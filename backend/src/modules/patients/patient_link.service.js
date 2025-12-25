const crypto = require('crypto');
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function sha256(s) {
  return crypto.createHash('sha256').update(String(s)).digest('hex');
}

function makeCode() {
  // كود قصير سهل إدخال/QR
  // مثال: 8 حروف/أرقام
  return crypto.randomBytes(5).toString('base64url').slice(0, 8).toUpperCase();
}

async function issueJoinCode({ tenantId, patientId, ttlMinutes = 30 }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!patientId) throw new HttpError(400, 'Missing patientId');

  // تأكد المريض ضمن نفس المنشأة
  const check = await pool.query(
    `SELECT id FROM patients WHERE tenant_id = $1 AND id = $2 LIMIT 1`,
    [tenantId, patientId]
  );
  if (check.rowCount === 0) throw new HttpError(404, 'Patient not found');

  const code = makeCode();
  const hash = sha256(`${tenantId}:${patientId}:${code}`);

  const expiresAt = new Date(Date.now() + Math.max(5, ttlMinutes) * 60 * 1000);

  await pool.query(
    `
    UPDATE patients
    SET join_code_hash = $1,
        join_code_expires_at = $2
    WHERE tenant_id = $3 AND id = $4
    `,
    [hash, expiresAt.toISOString(), tenantId, patientId]
  );

  return {
    ok: true,
    tenantId,
    patientId,
    joinCode: code,
    expiresAt,
    // payload جاهز للـ QR
    qrPayload: { tenantId, patientId, joinCode: code },
  };
}

async function getExternalHistory({ tenantId, patientId }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!patientId) throw new HttpError(400, 'Missing patientId');

  // لازم نعرف patient_account_id عبر membership الخاصة بهذا tenant_patient_id
  const mQ = await pool.query(
    `
    SELECT patient_account_id AS "patientAccountId"
    FROM patient_memberships
    WHERE tenant_id = $1 AND tenant_patient_id = $2
    LIMIT 1
    `,
    [tenantId, patientId]
  );
  const paId = mQ.rows[0]?.patientAccountId;
  if (!paId) {
    // معنى هذا: المريض لم يربط حسابه بعد عبر التطبيق
    return {
      ok: true,
      linked: false,
      patientAccountId: null,
      facilities: [],
    };
  }

  // نجيب كل المنشآت التي انضم لها (approved أو حتى revoked) لنفس الحساب
  const { rows } = await pool.query(
    `
    SELECT
      pm.tenant_id AS "tenantId",
      pm.status,
      pm.requested_at AS "requestedAt",
      pm.reviewed_at AS "reviewedAt",
      pm.left_at AS "leftAt",
      pm.tenant_patient_id AS "tenantPatientId",

      fd.name AS "facilityName",
      fd.type AS "facilityType",
      fd.city AS "city",
      fd.area AS "area",

      -- ملخص سريع: آخر admission بتاريخ داخل تلك المنشأة (إن وجد)
      (
        SELECT a.created_at
        FROM admissions a
        WHERE a.tenant_id = pm.tenant_id
          AND a.patient_id = pm.tenant_patient_id
        ORDER BY a.created_at DESC
        LIMIT 1
      ) AS "lastAdmissionAt"
    FROM patient_memberships pm
    LEFT JOIN facilities_directory fd ON fd.id = pm.tenant_id
    WHERE pm.patient_account_id = $1
    ORDER BY COALESCE(pm.left_at, pm.reviewed_at, pm.requested_at) DESC
    `,
    [paId]
  );

  return {
    ok: true,
    linked: true,
    patientAccountId: paId,
    facilities: rows,
  };
}

module.exports = {
  issueJoinCode,
  getExternalHistory,
  sha256, // exported لأن patient join سيحتاج نفس الهاش
};
