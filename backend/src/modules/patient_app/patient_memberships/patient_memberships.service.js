const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

async function listMyMemberships({ patientAccountId }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  const q = await pool.query(
    `
    SELECT
      id,
      tenant_id AS "tenantId",
      patient_account_id AS "patientAccountId",
      status,
      requested_at AS "requestedAt",
      reviewed_at AS "reviewedAt",
      reviewed_by_user_id AS "reviewedByUserId",
      tenant_patient_id AS "tenantPatientId",
      left_at AS "leftAt"
    FROM patient_memberships
    WHERE patient_account_id = $1
    ORDER BY reviewed_at DESC NULLS LAST, requested_at DESC NULLS LAST
    `,
    [patientAccountId]
  );

  return { ok: true, data: { items: q.rows } };
}

async function listMyJoinRequests({ patientAccountId, limit, offset }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  const q = await pool.query(
    `
    SELECT
      r.id,
      r.tenant_id AS "tenantId",
      r.status,
      r.created_at AS "createdAt",
      r.decided_at AS "decidedAt",
      jc.code AS "code"
    FROM patient_join_requests r
    LEFT JOIN patient_join_codes jc ON jc.id = r.join_code_id
    WHERE r.patient_account_id = $1
    ORDER BY r.created_at DESC
    LIMIT $2 OFFSET $3
    `,
    [patientAccountId, limit, offset]
  );

  return { ok: true, data: { items: q.rows, limit, offset } };
}

module.exports = { listMyMemberships, listMyJoinRequests };
