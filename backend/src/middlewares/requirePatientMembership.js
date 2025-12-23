const pool = require('../db/pool');
const { HttpError } = require('../utils/httpError');

function patientAccountId(req) {
  // ✅ ONLY from patient token payload
  return req.patientUser?.sub || null;
}


async function requirePatientMembership(req, _res, next) {
  try {
    const tenantId = req.params.tenantId;
    const paId = patientAccountId(req);

    if (!tenantId) throw new HttpError(400, 'Missing tenantId');
    if (!paId) throw new HttpError(401, 'Unauthorized');

    const { rows } = await pool.query(
      `
      SELECT
        id,
        tenant_id AS "tenantId",
        patient_account_id AS "patientAccountId",
        status,
        tenant_patient_id AS "tenantPatientId"
      FROM patient_memberships
      WHERE tenant_id = $1 AND patient_account_id = $2
      LIMIT 1
      `,
      [tenantId, paId]
    );

    const m = rows[0];
    if (!m) throw new HttpError(403, 'No membership for this facility');
    if (m.status !== 'APPROVED') throw new HttpError(403, 'Membership not approved');
    if (!m.tenantPatientId) throw new HttpError(409, 'Membership approved but tenant_patient_id is missing');

    // ✅ نثبّت الهوية داخل هذا الـ tenant
    req.patient = {
      tenantId,
      patientAccountId: paId,
      tenantPatientId: m.tenantPatientId,
    };

    return next();
  } catch (e) {
    return next(e);
  }
}

module.exports = { requirePatientMembership };
