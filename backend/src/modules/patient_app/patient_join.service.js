const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');
const { sha256 } = require('../patients/patient_link.service');

async function joinFacility({ patientAccountId, tenantId, patientId, joinCode }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!patientId) throw new HttpError(400, 'patientId is required');
  if (!joinCode) throw new HttpError(400, 'joinCode is required');

  // تحقق من الكود داخل patients في ذلك tenant
  const hash = sha256(`${tenantId}:${patientId}:${joinCode}`);

  const q = await pool.query(
    `
    SELECT id, join_code_hash AS "joinCodeHash", join_code_expires_at AS "joinCodeExpiresAt"
    FROM patients
    WHERE tenant_id = $1 AND id = $2
    LIMIT 1
    `,
    [tenantId, patientId]
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found in this facility');

  const row = q.rows[0];
  if (!row.joinCodeHash || !row.joinCodeExpiresAt) {
    throw new HttpError(400, 'Join code is not issued');
  }

  const exp = new Date(row.joinCodeExpiresAt).getTime();
  if (Number.isNaN(exp) || exp < Date.now()) throw new HttpError(400, 'Join code expired');

  if (String(row.joinCodeHash) !== String(hash)) throw new HttpError(400, 'Invalid join code');

  // ✅ Auto-approve: upsert membership
  const up = await pool.query(
    `
    INSERT INTO patient_memberships (
      patient_account_id,
      tenant_id,
      status,
      requested_at,
      reviewed_at,
      reviewed_by_user_id,
      tenant_patient_id,
      left_at
    )
    VALUES ($1,$2,'APPROVED'::membership_status, now(), now(), NULL, $3, NULL)
    ON CONFLICT (patient_account_id, tenant_id)
    DO UPDATE SET
      status = 'APPROVED'::membership_status,
      reviewed_at = now(),
      reviewed_by_user_id = NULL,
      tenant_patient_id = EXCLUDED.tenant_patient_id,
      left_at = NULL
    RETURNING
      id,
      tenant_id AS "tenantId",
      status,
      tenant_patient_id AS "tenantPatientId",
      left_at AS "leftAt",
      reviewed_at AS "reviewedAt"
    `,
    [patientAccountId, tenantId, patientId]
  );

  // 🔒 optional: نقدر نمسح join_code_hash بعد نجاح الانضمام لمنع إعادة استخدامه
  await pool.query(
    `
    UPDATE patients
    SET join_code_hash = NULL,
        join_code_expires_at = NULL
    WHERE tenant_id = $1 AND id = $2
    `,
    [tenantId, patientId]
  );

  return { ok: true, membership: up.rows[0] };
}

async function leaveFacility({ patientAccountId, tenantId }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');
  if (!tenantId) throw new HttpError(400, 'tenantId is required');

  const q = await pool.query(
    `
    UPDATE patient_memberships
    SET status = 'REVOKED'::membership_status,
        left_at = now(),
        reviewed_at = COALESCE(reviewed_at, now())
    WHERE patient_account_id = $1 AND tenant_id = $2
      AND status = 'APPROVED'::membership_status
      AND left_at IS NULL
    RETURNING
      id,
      tenant_id AS "tenantId",
      status,
      tenant_patient_id AS "tenantPatientId",
      left_at AS "leftAt"
    `,
    [patientAccountId, tenantId]
  );

  if (q.rowCount === 0) {
    // لا نعتبرها خطأ كبير — يمكن العضوية ليست فعالة
    return { ok: true, changed: false };
  }

  return { ok: true, changed: true, membership: q.rows[0] };
}

module.exports = { joinFacility, leaveFacility };
