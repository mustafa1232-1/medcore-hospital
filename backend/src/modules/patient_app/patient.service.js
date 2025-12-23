const pool = require('../../db/pool');

async function listMyMedications({ tenantId, tenantPatientId, limit = 50, offset = 0 }) {
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
      AND o.status <> 'CANCELLED'::order_status
    ORDER BY o.created_at DESC
    LIMIT $3 OFFSET $4
    `,
    [tenantId, tenantPatientId, limit, offset]
  );

  // ✅ لا نرجع status إطلاقاً
  const items = rows.map(r => {
    const p = r.payload || {};
    return {
      orderId: r.id,
      admissionId: r.admissionId,
      createdAt: r.createdAt,

      medicationName: p.medicationName ?? null,
      dose: p.dose ?? null,
      route: p.route ?? null,
      frequency: p.frequency ?? null,
      duration: p.duration ?? null,

      // إضافاتك (اختيارية)
      dosageText: p.dosageText ?? null,
      frequencyText: p.frequencyText ?? null,
      durationText: p.durationText ?? null,
      withFood: p.withFood ?? null,
      patientInstructionsAr: p.patientInstructionsAr ?? null,
      patientInstructionsEn: p.patientInstructionsEn ?? null,
      warningsText: p.warningsText ?? null,
    };
  });

  return { items, meta: { limit, offset, total: items.length } };
}

module.exports = { listMyMedications };
