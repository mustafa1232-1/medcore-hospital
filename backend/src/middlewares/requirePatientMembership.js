const pool = require('../db/pool');
const { HttpError } = require('../utils/httpError');

function patientAccountId(req) {
  return req.patientUser?.sub || null; // only from patient token
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
        tenant_patient_id AS "tenantPatientId",
        left_at AS "leftAt"
      FROM patient_memberships
      WHERE tenant_id = $1 AND patient_account_id = $2
      LIMIT 1
      `,
      [tenantId, paId]
    );

    const m = rows[0];
    if (!m) throw new HttpError(403, 'No membership for this facility');

    // ✅ must be approved and not left
    if (m.status !== 'APPROVED') throw new HttpError(403, 'Membership not approved');
    if (m.leftAt) throw new HttpError(403, 'Membership is not active');

    if (!m.tenantPatientId) {
      throw new HttpError(409, 'Membership approved but tenant_patient_id is missing');
    }

    req.patient = {
      tenantId,
      patientAccountId: paId,
      tenantPatientId: m.tenantPatientId,
      membershipId: m.id,
    };

    return next();
  } catch (e) {
    return next(e);
  }
}

module.exports = { requirePatientMembership };
