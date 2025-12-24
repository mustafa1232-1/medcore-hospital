const pool = require('../../db/pool');

async function listMyMedications({ tenantId, patientId }) {
  const { rows } = await pool.query(
    `
    SELECT
      o.id,
      o.admission_id AS "admissionId",
      o.created_at AS "createdAt",
      o.payload
    FROM orders o
    WHERE o.tenant_id = $1
      AND o.patient_id = $2
      AND o.kind = 'MEDICATION'::order_kind
    ORDER BY o.created_at DESC
    LIMIT 200
    `,
    [tenantId, patientId]
  );

  // ✅ strip status completely
  return rows.map(r => {
    const p = r.payload || {};
    return {
      id: r.id,
      admissionId: r.admissionId,
      createdAt: r.createdAt,

      medicationName: p.medicationName || null,
      dose: p.dose || null,
      route: p.route || null,
      frequency: p.frequency || null,
      duration: p.duration || null,
      times: Array.isArray(p.times) ? p.times : [],
      instructions: p.instructions || null,

      requestedQty: p.requestedQty ?? null,
      // لا نرسل status ولا dispensedQty للمريض حسب طلبك
    };
  });
}

module.exports = { listMyMedications };
