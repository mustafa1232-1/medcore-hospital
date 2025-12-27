// src/modules/patient_join_requests/patient_join_requests.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function submitByCode({ patientAccountId, code }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');
  if (!code) throw new HttpError(400, 'code is required');

  // Find active join code (code only)
  const q = await pool.query(
    `
    SELECT
      id,
      tenant_id AS "tenantId",
      status,
      max_uses AS "maxUses",
      used_count AS "usedCount",
      expires_at AS "expiresAt"
    FROM patient_join_codes
    WHERE code = $1
    LIMIT 1
    `,
    [code]
  );

  if (q.rowCount === 0) throw new HttpError(400, 'Invalid code');

  const jc = q.rows[0];

  if (String(jc.status) !== 'ACTIVE') throw new HttpError(400, 'Code is not active');

  if (jc.expiresAt && new Date(jc.expiresAt).getTime() < Date.now()) {
    // mark expired (best effort)
    await pool.query(`UPDATE patient_join_codes SET status='EXPIRED' WHERE id=$1`, [jc.id]);
    throw new HttpError(400, 'Code expired');
  }

  if (Number(jc.usedCount) >= Number(jc.maxUses)) {
    throw new HttpError(400, 'Code max uses reached');
  }

  // Prevent duplicate pending request from same patient for same tenant
  const dup = await pool.query(
    `
    SELECT id
    FROM patient_join_requests
    WHERE tenant_id = $1 AND patient_account_id = $2 AND status = 'PENDING'
    LIMIT 1
    `,
    [jc.tenantId, patientAccountId]
  );

  if (dup.rowCount > 0) {
    return {
      ok: true,
      data: { id: dup.rows[0].id, status: 'PENDING', alreadyPending: true },
    };
  }

  // Create request
  const ins = await pool.query(
    `
    INSERT INTO patient_join_requests (
      tenant_id,
      join_code_id,
      patient_account_id,
      status,
      created_at
    )
    VALUES ($1,$2,$3,'PENDING', now())
    RETURNING
      id,
      tenant_id AS "tenantId",
      status,
      created_at AS "createdAt"
    `,
    [jc.tenantId, jc.id, patientAccountId]
  );

  // Increment used_count (best effort; if it fails we still keep request created)
  await pool.query(
    `
    UPDATE patient_join_codes
    SET used_count = used_count + 1
    WHERE id = $1
    `,
    [jc.id]
  );

  return {
    ok: true,
    data: {
      ...ins.rows[0],
      code,
    },
  };
}

async function listMine({ tenantId, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');

  // داخل submitByCode (service)
const q = await pool.query(
  `
  SELECT
    id,
    tenant_id AS "tenantId",
    status,
    max_uses AS "maxUses",
    used_count AS "usedCount",
    expires_at AS "expiresAt"
  FROM patient_join_codes
  WHERE code = $1
    AND status = 'ACTIVE'
    AND (expires_at IS NULL OR expires_at > now())
  ORDER BY created_at DESC
  LIMIT 1
  `,
  [code]
);

if (q.rowCount === 0) throw new HttpError(400, 'Invalid code');


  return { ok: true, data: { items: q.rows, limit, offset } };
}

async function decide({ tenantId, id, action, staffUserId }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!id) throw new HttpError(400, 'id is required');
  if (action !== 'APPROVED' && action !== 'REJECTED') {
    throw new HttpError(400, 'Invalid action');
  }

  // 1) Load request to get patient_account_id (so we can create membership on approve)
  const rq = await pool.query(
    `
    SELECT
      id,
      tenant_id AS "tenantId",
      patient_account_id AS "patientAccountId",
      status
    FROM patient_join_requests
    WHERE id = $1 AND tenant_id = $2
    LIMIT 1
    `,
    [id, tenantId]
  );

  if (rq.rowCount === 0) throw new HttpError(404, 'Request not found');

  const reqRow = rq.rows[0];
  if (String(reqRow.status) !== 'PENDING') {
    throw new HttpError(409, 'Request already decided');
  }

  // 2) Decide request
  const q = await pool.query(
    `
    UPDATE patient_join_requests
    SET status = $3,
        decided_at = now(),
        decided_by_user_id = $4
    WHERE id = $1 AND tenant_id = $2 AND status = 'PENDING'
    RETURNING
      id,
      tenant_id AS "tenantId",
      status,
      decided_at AS "decidedAt"
    `,
    [id, tenantId, action, staffUserId]
  );

  if (q.rowCount === 0) {
    throw new HttpError(404, 'Request not found (or already decided)');
  }

  // 3) ✅ If APPROVED => upsert membership (facility membership)
  // NOTE: tenant_patient_id is unknown in this flow; leave it NULL.
  if (action === 'APPROVED') {
    try {
      await pool.query(
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
        VALUES (
          $1,
          $2,
          'APPROVED'::membership_status,
          now(),
          now(),
          $3,
          NULL,
          NULL
        )
        ON CONFLICT (patient_account_id, tenant_id)
        DO UPDATE SET
          status = 'APPROVED'::membership_status,
          reviewed_at = now(),
          reviewed_by_user_id = EXCLUDED.reviewed_by_user_id,
          left_at = NULL
        `,
        [reqRow.patientAccountId, tenantId, staffUserId]
      );
    } catch (e) {
      // Important: do not fail decision if membership upsert fails
      // because the receptionist already "approved" the request.
      // You can log e if needed.
    }
  }

  return { ok: true, data: q.rows[0] };
}

module.exports = { submitByCode, listMine, decide };
