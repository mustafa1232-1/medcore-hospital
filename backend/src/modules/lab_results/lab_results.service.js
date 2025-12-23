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

async function lockOrderForLab({ client, tenantId, orderId }) {
  const q = await client.query(
    `
    SELECT
      o.id,
      o.tenant_id AS "tenantId",
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
  if (order.kind !== 'LAB') throw new HttpError(409, 'Order is not LAB');
  if (order.status === 'CANCELLED') throw new HttpError(409, 'Cannot add result to a CANCELLED order');

  return order;
}

async function createLabResultTx({ tenantId, orderId, result, notes, createdByUserId, markOrderCompleted = true }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const order = await lockOrderForLab({ client, tenantId, orderId });

    // insert result
    const ins = await client.query(
      `
      INSERT INTO lab_results (
        tenant_id,
        order_id,
        admission_id,
        patient_id,
        result,
        created_by_user_id,
        created_at
      )
      VALUES ($1,$2,$3,$4,$5::jsonb,$6, now())
      RETURNING
        id,
        order_id AS "orderId",
        admission_id AS "admissionId",
        patient_id AS "patientId",
        result,
        created_by_user_id AS "createdByUserId",
        created_at AS "createdAt"
      `,
      [
        tenantId,
        order.id,
        order.admissionId,
        order.patientId,
        JSON.stringify({ ...(result || {}), notes: notes || undefined }),
        createdByUserId || null,
      ]
    );

    // Optionally complete order + tasks
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

      // complete related tasks if still open
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
    }

    // log
    await writePatientLogTx({
      client,
      tenantId,
      patientId: order.patientId,
      admissionId: order.admissionId,
      actorUserId: createdByUserId,
      eventType: 'LAB_RESULT_ADDED',
      message: `تمت إضافة نتيجة تحليل: ${order.payload?.testName || ''}`.trim(),
      meta: {
        orderId: order.id,
        labResultId: ins.rows[0].id,
        testName: order.payload?.testName,
        markOrderCompleted: !!markOrderCompleted,
      },
    });

    await client.query('COMMIT');
    return { orderId: order.id, labResult: ins.rows[0] };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function listLabResults({ tenantId, query }) {
  const where = ['lr.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (query.patientId) { params.push(query.patientId); where.push(`lr.patient_id = $${i++}`); }
  if (query.admissionId) { params.push(query.admissionId); where.push(`lr.admission_id = $${i++}`); }
  if (query.orderId) { params.push(query.orderId); where.push(`lr.order_id = $${i++}`); }

  const limit = query.limit ?? 50;
  const offset = query.offset ?? 0;

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM lab_results lr WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      lr.id,
      lr.order_id AS "orderId",
      lr.admission_id AS "admissionId",
      lr.patient_id AS "patientId",
      lr.result,
      lr.created_by_user_id AS "createdByUserId",
      lr.created_at AS "createdAt"
    FROM lab_results lr
    WHERE ${where.join(' AND ')}
    ORDER BY lr.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getLabResult({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      lr.id,
      lr.order_id AS "orderId",
      lr.admission_id AS "admissionId",
      lr.patient_id AS "patientId",
      lr.result,
      lr.created_by_user_id AS "createdByUserId",
      lr.created_at AS "createdAt"
    FROM lab_results lr
    WHERE lr.tenant_id = $1 AND lr.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Lab result not found');
  return rows[0];
}

module.exports = {
  createLabResultTx,
  listLabResults,
  getLabResult,
};
