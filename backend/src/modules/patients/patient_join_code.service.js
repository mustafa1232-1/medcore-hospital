// src/modules/patients/patient_join_code.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');
const { randomCode } = require('../../utils/joinCode');
const { sha256 } = require('./patient_link.service');

async function issueJoinCode({ tenantId, patientId, ttlMinutes = 30, len = 6 }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!patientId) throw new HttpError(400, 'patientId is required');

  const safeLen = Math.max(4, Math.min(10, Number(len) || 6));
  const safeTtl = Math.max(3, Math.min(24 * 60, Number(ttlMinutes) || 30));

  // Ensure patient exists
  const q = await pool.query(
    `
    SELECT id
    FROM patients
    WHERE tenant_id = $1 AND id = $2
    LIMIT 1
    `,
    [tenantId, patientId]
  );
  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found in this facility');

  const joinCode = randomCode(safeLen);
  const hash = sha256(`${tenantId}:${patientId}:${joinCode}`);

  const up = await pool.query(
    `
    UPDATE patients
    SET join_code_hash = $3,
        join_code_expires_at = now() + ($4::int * interval '1 minute')
    WHERE tenant_id = $1 AND id = $2
    RETURNING
      id,
      tenant_id AS "tenantId",
      join_code_expires_at AS "expiresAt"
    `,
    [tenantId, patientId, hash, safeTtl]
  );

  const payload = {
    tenantId: String(tenantId),
    patientId: String(patientId),
    joinCode,
  };

  return {
    ok: true,
    data: {
      tenantId: payload.tenantId,
      patientId: payload.patientId,
      joinCode: payload.joinCode,
      expiresAt: up.rows[0]?.expiresAt,
      qrPayload: payload,
    },
  };
}

async function revokeJoinCode({ tenantId, patientId }) {
  if (!tenantId) throw new HttpError(400, 'tenantId is required');
  if (!patientId) throw new HttpError(400, 'patientId is required');

  await pool.query(
    `
    UPDATE patients
    SET join_code_hash = NULL,
        join_code_expires_at = NULL
    WHERE tenant_id = $1 AND id = $2
    `,
    [tenantId, patientId]
  );

  return { ok: true };
}

module.exports = { issueJoinCode, revokeJoinCode };
