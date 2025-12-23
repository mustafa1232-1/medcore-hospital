const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function writePatientLogTx({ client, tenantId, patientId, admissionId, actorUserId, eventType, message, meta }) {
  await client.query(
    `
    INSERT INTO patient_log (
      tenant_id, patient_id, admission_id,
      actor_user_id, event_type, message, meta, created_at
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb, now())
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
}

async function lockOrderForMedication({ client, tenantId, orderId }) {
  const q = await client.query(
    `
    SELECT
      o.id,
      o.admission_id AS "admissionId",
      o.patient_id AS "patientId",
      o.kind,
      o.status,
      o.payload
    FROM orders o
    WHERE o.tenant_id = $1 AND o.id = $2
    FOR UPDATE
    `,
    [tenantId, orderId]
  );

  const order = q.rows[0];
  if (!order) throw new HttpError(404, 'Order not found');
  if (order.kind !== 'MEDICATION') throw new HttpError(409, 'Order is not MEDICATION');
  if (order.status === 'CANCELLED') throw new HttpError(409, 'Cannot administer a CANCELLED order');

  return order;
}

function normalizeAdminStatus({ giveNow, status }) {
  if (status) return String(status).toUpperCase().trim();
  return giveNow ? 'GIVEN' : 'SCHEDULED';
}

async function createMedicationAdminTx({
  tenantId,
  orderId,
  scheduledAt,
  giveNow = true,
  status,
  notes,
  administeredByUserId,
  markOrderCompleted = false,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const order = await lockOrderForMedication({ client, tenantId, orderId });

    const finalStatus = normalizeAdminStatus({ giveNow, status });

    const givenAt = finalStatus === 'GIVEN' ? new Date().toISOString() : null;

    const ins = await client.query(
      `
      INSERT INTO medication_administrations (
        tenant_id,
        order_id,
        admission_id,
        patient_id,
        scheduled_at,
        given_at,
        status,
        administered_by_user_id,
        notes,
        created_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7::medication_admin_status,$8,$9, now())
      RETURNING
        id,
        order_id AS "orderId",
        admission_id AS "admissionId",
        patient_id AS "patientId",
        scheduled_at AS "scheduledAt",
        given_at AS "givenAt",
        status,
        administered_by_user_id AS "administeredByUserId",
        notes,
        created_at AS "createdAt"
      `,
      [
        tenantId,
        order.id,
        order.admissionId,
        order.patientId,
        scheduledAt || null,
        givenAt,
        finalStatus,
        administeredByUserId || null,
        notes || null,
      ]
    );

    // If given, mark related task STARTED/COMPLETED logically
    if (finalStatus === 'GIVEN') {
      // complete related tasks if open
      await client.query(
        `
        UPDATE nursing_tasks
        SET status = 'COMPLETED'::task_status,
            completed_at = now(),
            updated_at = now()
        WHERE tenant_id = $1 AND order_id = $2
          AND status IN ('PENDING','STARTED')
        `,
        [tenantId, order.id]
      );

      // optionally complete order
      if (markOrderCompleted && order.status !== 'COMPLETED') {
        await client.query(
          `
          UPDATE orders
          SET status = 'COMPLETED'::order_status,
              updated_at = now()
          WHERE tenant_id = $1 AND id = $2
          `,
          [tenantId, order.id]
        );
      } else {
        // If not completing, at least move order to IN_PROGRESS (if still CREATED)
        if (order.status === 'CREATED') {
          await client.query(
            `
            UPDATE orders
            SET status = 'IN_PROGRESS'::order_status,
                updated_at = now()
            WHERE tenant_id = $1 AND id = $2
            `,
            [tenantId, order.id]
          );
        }
      }
    }

    // log
    await writePatientLogTx({
      client,
      tenantId,
      patientId: order.patientId,
      admissionId: order.admissionId,
      actorUserId: administeredByUserId,
      eventType: 'MED_ADMIN_RECORDED',
      message: `تم تسجيل إعطاء دواء: ${order.payload?.medicationName || ''}`.trim(),
      meta: {
        orderId: order.id,
        adminId: ins.rows[0].id,
        status: finalStatus,
        medicationName: order.payload?.medicationName,
        dose: order.payload?.dose,
        route: order.payload?.route,
        frequency: order.payload?.frequency,
        markOrderCompleted: !!markOrderCompleted,
      },
    });

    await client.query('COMMIT');
    return { orderId: order.id, admin: ins.rows[0] };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function listMedicationAdmins({ tenantId, query }) {
  const where = ['ma.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (query.patientId) { params.push(query.patientId); where.push(`ma.patient_id = $${i++}`); }
  if (query.admissionId) { params.push(query.admissionId); where.push(`ma.admission_id = $${i++}`); }
  if (query.orderId) { params.push(query.orderId); where.push(`ma.order_id = $${i++}`); }

  const limit = query.limit ?? 50;
  const offset = query.offset ?? 0;

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM medication_administrations ma WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      ma.id,
      ma.order_id AS "orderId",
      ma.admission_id AS "admissionId",
      ma.patient_id AS "patientId",
      ma.scheduled_at AS "scheduledAt",
      ma.given_at AS "givenAt",
      ma.status,
      ma.administered_by_user_id AS "administeredByUserId",
      ma.notes,
      ma.created_at AS "createdAt"
    FROM medication_administrations ma
    WHERE ${where.join(' AND ')}
    ORDER BY ma.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getMedicationAdmin({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      ma.id,
      ma.order_id AS "orderId",
      ma.admission_id AS "admissionId",
      ma.patient_id AS "patientId",
      ma.scheduled_at AS "scheduledAt",
      ma.given_at AS "givenAt",
      ma.status,
      ma.administered_by_user_id AS "administeredByUserId",
      ma.notes,
      ma.created_at AS "createdAt"
    FROM medication_administrations ma
    WHERE ma.tenant_id = $1 AND ma.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Medication administration not found');
  return rows[0];
}

module.exports = {
  createMedicationAdminTx,
  listMedicationAdmins,
  getMedicationAdmin,
};
