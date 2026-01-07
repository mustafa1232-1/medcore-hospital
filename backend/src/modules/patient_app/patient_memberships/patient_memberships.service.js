const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

async function listMyMemberships({ patientAccountId }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');

  const q = await pool.query(
    `
    SELECT
      m.id,
      m.tenant_id AS "tenantId",
      m.patient_account_id AS "patientAccountId",
      m.status,
      m.requested_at AS "requestedAt",
      m.reviewed_at AS "reviewedAt",
      m.reviewed_by_user_id AS "reviewedByUserId",
      m.tenant_patient_id AS "tenantPatientId",
      m.left_at AS "leftAt",

      t.name AS "tenantName",
      t.type AS "tenantType",
      t.code AS "tenantCode"
    FROM patient_memberships m
    JOIN tenants t ON t.id = m.tenant_id
    WHERE m.patient_account_id = $1
    ORDER BY m.reviewed_at DESC NULLS LAST, m.requested_at DESC NULLS LAST
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
