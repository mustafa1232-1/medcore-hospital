const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

async function ensurePatientInTenant({ tenantId, patientId }) {
  const q = await pool.query(
    `SELECT id FROM patients WHERE tenant_id = $1 AND id = $2 LIMIT 1`,
    [tenantId, patientId]
  );
  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found');
}

async function listPatientProfileSnapshots({ tenantId, patientId, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!patientId) throw new HttpError(400, 'Missing patientId');

  await ensurePatientInTenant({ tenantId, patientId });

  const lim = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const off = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  const countQ = await pool.query(
    `
    SELECT COUNT(*)::int AS count
    FROM tenant_patient_profile_snapshots s
    WHERE s.tenant_id = $1 AND s.tenant_patient_id = $2
    `,
    [tenantId, patientId]
  );
  const total = countQ.rows[0]?.count || 0;

  const { rows } = await pool.query(
    `
    SELECT
      s.id,
      s.tenant_id AS "tenantId",
      s.tenant_patient_id AS "tenantPatientId",
      s.patient_account_id AS "patientAccountId",
      s.snapshot,
      s.created_at AS "createdAt"
    FROM tenant_patient_profile_snapshots s
    WHERE s.tenant_id = $1 AND s.tenant_patient_id = $2
    ORDER BY s.created_at DESC
    LIMIT $3 OFFSET $4
    `,
    [tenantId, patientId, lim, off]
  );

  return { items: rows, meta: { total, limit: lim, offset: off } };
}

module.exports = { listPatientProfileSnapshots };
