const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function listBedHistory({ tenantId, bedId, limit = 50, offset = 0 }) {
  const lim = Math.min(Math.max(parseInt(limit, 10) || 50, 1), 200);
  const off = Math.max(parseInt(offset, 10) || 0, 0);

  const { rows } = await pool.query(
    `
    SELECT
      bh.id,
      bh.tenant_id AS "tenantId",
      bh.bed_id AS "bedId",
      bh.room_id AS "roomId",
      bh.department_id AS "departmentId",
      bh.admission_id AS "admissionId",
      bh.patient_id AS "patientId",
      bh.assigned_at AS "assignedAt",
      bh.released_at AS "releasedAt",
      bh.reason,
      bh.actor_user_id AS "actorUserId",
      bh.notes,
      bh.created_at AS "createdAt",

      b.code AS "bedCode",
      r.code AS "roomCode",
      d.code AS "departmentCode"
    FROM bed_history bh
    LEFT JOIN beds b ON b.id = bh.bed_id
    LEFT JOIN rooms r ON r.id = bh.room_id
    LEFT JOIN departments d ON d.id = bh.department_id
    WHERE bh.tenant_id = $1 AND bh.bed_id = $2
    ORDER BY bh.assigned_at DESC
    LIMIT $3 OFFSET $4
    `,
    [tenantId, bedId, lim, off]
  );

  return { items: rows, meta: { limit: lim, offset: off } };
}

async function getBedHistoryEntry({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      bh.id,
      bh.tenant_id AS "tenantId",
      bh.bed_id AS "bedId",
      bh.room_id AS "roomId",
      bh.department_id AS "departmentId",
      bh.admission_id AS "admissionId",
      bh.patient_id AS "patientId",
      bh.assigned_at AS "assignedAt",
      bh.released_at AS "releasedAt",
      bh.reason,
      bh.actor_user_id AS "actorUserId",
      bh.notes,
      bh.created_at AS "createdAt"
    FROM bed_history bh
    WHERE bh.tenant_id = $1 AND bh.id = $2
    `,
    [tenantId, id]
  );

  if (!rows[0]) throw new HttpError(404, 'Bed history entry not found');
  return rows[0];
}

module.exports = { listBedHistory, getBedHistoryEntry };
