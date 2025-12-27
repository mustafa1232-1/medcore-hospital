// src/modules/patient_join_requests/patient_join_requests.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function submitByCode({ patientAccountId, code }) {
  if (!patientAccountId) throw new HttpError(401, 'Unauthorized');
  if (!code) throw new HttpError(400, 'code is required');

  // ✅ Find ACTIVE + not expired join code by code only
  // Deterministic: take latest created if ever duplicated (should not happen after global unique).
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
    [String(code).trim()]
  );

  if (q.rowCount === 0) throw new HttpError(400, 'Invalid code');

  const jc = q.rows[0];

  // Extra guards (safe)
  if (Number(jc.usedCount) >= Number(jc.maxUses)) {
    throw new HttpError(400, 'Code max uses reached');
  }

  // Prevent duplicate pending request from same patient for same tenant
  const dup = await pool.query(
    `
    SELECT id
    FROM patient_join_requests
    WHERE tenant_id = $1
      AND patient_account_id = $2
      AND status = 'PENDING'
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

  // Increment used_count (best effort)
  try {
    await pool.query(
      `
      UPDATE patient_join_codes
      SET used_count = used_count + 1
      WHERE id = $1
      `,
      [jc.id]
    );
  } catch (_) {
    // do not fail request creation
  }

  return {
    ok: true,
    data: {
      ...ins.rows[0],
      code: String(code).trim(),
    },
  };
}

async function listMine({ tenantId, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');

  const lim = Math.min(50, Math.max(1, Number(limit) || 20));
  const off = Math.max(0, Number(offset) || 0);

  // ✅ List PENDING requests for this tenant (Reception/Admin)
  const q = await pool.query(
    `
    SELECT
      r.id,
      r.tenant_id AS "tenantId",
      r.status,
      r.created_at AS "createdAt",
      r.decided_at AS "decidedAt",
      r.patient_account_id AS "patientAccountId",

      pa.full_name AS "patientFullName",
      pa.phone AS "patientPhone",

      jc.code AS "code",
      jc.expires_at AS "codeExpiresAt"
    FROM patient_join_requests r
    LEFT JOIN patient_accounts pa
      ON pa.id = r.patient_account_id
    LEFT JOIN patient_join_codes jc
      ON jc.id = r.join_code_id
    WHERE r.tenant_id = $1
      AND r.status = 'PENDING'
    ORDER BY r.created_at DESC
    LIMIT $2 OFFSET $3
    `,
    [tenantId, lim, off]
  );

  return { ok: true, data: { items: q.rows, limit: lim, offset: off } };
}

async function decide({ tenantId, id, action, staffUserId }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!id) throw new HttpError(400, 'id is required');
  if (action !== 'APPROVED' && action !== 'REJECTED') {
    throw new HttpError(400, 'Invalid action');
  }

  // Load request to get patient_account_id
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

  // Decide request
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

  // If APPROVED => upsert membership (tenant membership)
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
    } catch (_) {
      // do not fail decision if membership fails
    }
  }

  return { ok: true, data: q.rows[0] };
}

module.exports = { submitByCode, listMine, decide };
