const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function ensurePatient({ tenantId, patientId }) {
  const q = await pool.query(
    `SELECT id FROM patients WHERE tenant_id = $1 AND id = $2 LIMIT 1`,
    [tenantId, patientId]
  );
  if (!q.rows[0]) throw new HttpError(404, 'Patient not found');
  return true;
}

async function listPatientLog({ tenantId, patientId, admissionId, limit = 50, offset = 0 }) {
  await ensurePatient({ tenantId, patientId });

  const lim = Math.min(Math.max(parseInt(limit, 10) || 50, 1), 200);
  const off = Math.max(parseInt(offset, 10) || 0, 0);

  const params = [tenantId, patientId];
  let i = 3;
  let where = `pl.tenant_id = $1 AND pl.patient_id = $2`;

  if (admissionId) {
    params.push(admissionId);
    where += ` AND pl.admission_id = $${i++}`;
  }

  params.push(lim, off);

  const { rows } = await pool.query(
    `
    SELECT
      pl.id,
      pl.tenant_id AS "tenantId",
      pl.patient_id AS "patientId",
      pl.admission_id AS "admissionId",
      pl.event_type AS "eventType",
      pl.message,
      pl.meta,
      pl.actor_user_id AS "actorUserId",
      pl.created_at AS "createdAt",

      u.name AS "actorName",
      u.email AS "actorEmail",
      u.staff_code AS "actorStaffCode"
    FROM patient_log pl
    LEFT JOIN users u
      ON u.id = pl.actor_user_id AND u.tenant_id = pl.tenant_id
    WHERE ${where}
    ORDER BY pl.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { limit: lim, offset: off } };
}

async function createPatientLog({ tenantId, patientId, admissionId, actorUserId, eventType, message, meta }) {
  await ensurePatient({ tenantId, patientId });

  const { rows } = await pool.query(
    `
    INSERT INTO patient_log (
      tenant_id, patient_id, admission_id,
      actor_user_id, event_type, message, meta, created_at
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb, now())
    RETURNING
      id,
      tenant_id AS "tenantId",
      patient_id AS "patientId",
      admission_id AS "admissionId",
      actor_user_id AS "actorUserId",
      event_type AS "eventType",
      message,
      meta,
      created_at AS "createdAt"
    `,
    [
      tenantId,
      patientId,
      admissionId || null,
      actorUserId || null,
      eventType,
      message || null,
      JSON.stringify(meta || {}),
    ]
  );

  return rows[0];
}

async function getPatientLogEntry({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      pl.id,
      pl.tenant_id AS "tenantId",
      pl.patient_id AS "patientId",
      pl.admission_id AS "admissionId",
      pl.event_type AS "eventType",
      pl.message,
      pl.meta,
      pl.actor_user_id AS "actorUserId",
      pl.created_at AS "createdAt"
    FROM patient_log pl
    WHERE pl.tenant_id = $1 AND pl.id = $2
    `,
    [tenantId, id]
  );

  if (!rows[0]) throw new HttpError(404, 'Patient log entry not found');
  return rows[0];
}

module.exports = {
  listPatientLog,
  createPatientLog,
  getPatientLogEntry,
};
