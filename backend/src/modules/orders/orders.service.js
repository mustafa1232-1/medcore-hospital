// src/modules/orders/orders.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function ensureAdmissionInTenant({ tenantId, admissionId }) {
  const { rows } = await pool.query(
    `
    SELECT
      a.id,
      a.status,
      a.patient_id AS "patientId",
      ab.bed_id AS "bedId",
      b.room_id AS "roomId",
      r.department_id AS "departmentId"
    FROM admissions a
    LEFT JOIN admission_beds ab
      ON ab.admission_id = a.id AND ab.is_active = true
    LEFT JOIN beds b ON b.id = ab.bed_id
    LEFT JOIN rooms r ON r.id = b.room_id
    WHERE a.tenant_id = $1 AND a.id = $2
    LIMIT 1
    `,
    [tenantId, admissionId]
  );

  const a = rows[0];
  if (!a) throw new HttpError(404, 'Admission not found');
  return a;
}

function tasksFromPayload({ kind, payload }) {
  if (kind === 'MEDICATION') {
    const title = `إعطاء دواء: ${payload.medicationName}`;
    const details =
      `الجرعة: ${payload.dose} | الطريق: ${payload.route} | التكرار: ${payload.frequency}` +
      (payload.duration ? ` | المدة: ${payload.duration}` : '');
    return [{ title, details }];
  }

  if (kind === 'LAB') {
    const title = `سحب عينة للتحليل: ${payload.testName}`;
    const details = `الأولوية: ${payload.priority} | العينة: ${payload.specimen}`;
    return [{ title, details }];
  }

  if (kind === 'PROCEDURE') {
    const title = `إجراء/تحضير: ${payload.procedureName}`;
    const details = `الاستعجال: ${payload.urgency}`;
    return [{ title, details }];
  }

  return [];
}

async function createTasksForOrderTx({ client, tenantId, order, activeBed, createdByUserId }) {
  const list = tasksFromPayload({ kind: order.kind, payload: order.payload || {} });

  const out = [];
  for (const t of list) {
    const ins = await client.query(
      `
      INSERT INTO nursing_tasks (
        tenant_id,
        admission_id,
        patient_id,
        order_id,
        department_id,
        room_id,
        bed_id,
        title,
        details,
        kind,
        status,
        assigned_to_user_id,
        created_by_user_id,
        created_at,
        updated_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'PENDING',NULL,$11,now(),now())
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        order_id AS "orderId",
        title,
        details,
        kind,
        status,
        assigned_to_user_id AS "assignedToUserId",
        created_at AS "createdAt"
      `,
      [
        tenantId,
        order.admissionId,
        order.patientId,
        order.id,
        activeBed.departmentId || null,
        activeBed.roomId || null,
        activeBed.bedId || null,
        t.title,
        t.details || null,
        order.kind,
        createdByUserId,
      ]
    );
    out.push(ins.rows[0]);
  }

  return out;
}

/** ===========================
 *  Patient Log writer (داخل TX)
 * =========================== */
async function writePatientLogTx({
  client,
  tenantId,
  patientId,
  admissionId,
  actorUserId,
  eventType,
  message,
  meta,
}) {
  await client.query(
    `
    INSERT INTO patient_log (
      tenant_id,
      patient_id,
      admission_id,
      actor_user_id,
      event_type,
      message,
      meta,
      created_at
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

function orderSummaryMessage({ kind, payload }) {
  if (kind === 'MEDICATION') return `تم إنشاء طلب دواء: ${payload?.medicationName || ''}`.trim();
  if (kind === 'LAB') return `تم إنشاء طلب تحليل: ${payload?.testName || ''}`.trim();
  if (kind === 'PROCEDURE') return `تم إنشاء طلب إجراء: ${payload?.procedureName || ''}`.trim();
  return 'تم إنشاء طلب';
}

/** ===========================
 *  Create order TX
 * =========================== */
async function createOrderTx({
  tenantId,
  admissionId,
  kind,
  payload,
  notes,
  createdByUserId,
  doctorUserId,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const aQ = await client.query(
      `
      SELECT a.id, a.status, a.patient_id AS "patientId"
      FROM admissions a
      WHERE a.tenant_id = $1 AND a.id = $2
      FOR UPDATE
      `,
      [tenantId, admissionId]
    );

    const a = aQ.rows[0];
    if (!a) throw new HttpError(404, 'Admission not found');
    if (a.status !== 'ACTIVE') {
      throw new HttpError(403, 'يجب تعيين غرفة وسرير وتفعيل الدخول قبل تنفيذ أي إجراء');
    }

    const bedQ = await client.query(
      `
      SELECT
        ab.bed_id AS "bedId",
        b.room_id AS "roomId",
        r.department_id AS "departmentId"
      FROM admission_beds ab
      JOIN beds b ON b.id = ab.bed_id
      JOIN rooms r ON r.id = b.room_id
      WHERE ab.tenant_id = $1 AND ab.admission_id = $2 AND ab.is_active = true
      LIMIT 1
      `,
      [tenantId, admissionId]
    );

    const activeBed = bedQ.rows[0];
    if (!activeBed) throw new HttpError(403, 'يجب تعيين غرفة وسرير للمريض قبل تنفيذ أي إجراء');

    const oIns = await client.query(
      `
      INSERT INTO orders (
        tenant_id,
        admission_id,
        patient_id,
        created_by_user_id,
        doctor_user_id,
        kind,
        status,
        payload,
        notes,
        created_at,
        updated_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,'CREATED',$7::jsonb,$8,now(),now())
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        kind,
        status,
        payload,
        notes,
        created_at AS "createdAt",
        updated_at AS "updatedAt"
      `,
      [
        tenantId,
        admissionId,
        a.patientId,
        createdByUserId,
        doctorUserId || null,
        kind,
        JSON.stringify(payload || {}),
        notes || null,
      ]
    );

    const order = oIns.rows[0];

    const tasks = await createTasksForOrderTx({
      client,
      tenantId,
      order,
      activeBed,
      createdByUserId,
    });

    await writePatientLogTx({
      client,
      tenantId,
      patientId: order.patientId,
      admissionId: order.admissionId,
      actorUserId: createdByUserId,
      eventType: 'ORDER_CREATED',
      message: orderSummaryMessage({ kind: order.kind, payload: order.payload }),
      meta: {
        orderId: order.id,
        kind: order.kind,
        payload: order.payload,
        taskIds: tasks.map((t) => t.id),
      },
    });

    await client.query('COMMIT');
    return { order, tasks };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function listOrders({ tenantId, query }) {
  const where = ['o.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (query.admissionId) { params.push(query.admissionId); where.push(`o.admission_id = $${i++}`); }
  if (query.patientId) { params.push(query.patientId); where.push(`o.patient_id = $${i++}`); }
  if (query.kind) { params.push(query.kind); where.push(`o.kind = $${i++}::order_kind`); }
  if (query.status) { params.push(query.status); where.push(`o.status = $${i++}::order_status`); }

  const limit = query.limit ?? 20;
  const offset = query.offset ?? 0;

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM orders o WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      o.id,
      o.admission_id AS "admissionId",
      o.patient_id AS "patientId",
      o.kind,
      o.status,
      o.payload,
      o.notes,
      o.created_at AS "createdAt",
      o.updated_at AS "updatedAt",
      o.cancelled_at AS "cancelledAt"
    FROM orders o
    WHERE ${where.join(' AND ')}
    ORDER BY o.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getOrder({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      o.id,
      o.admission_id AS "admissionId",
      o.patient_id AS "patientId",
      o.kind,
      o.status,
      o.payload,
      o.notes,
      o.created_at AS "createdAt",
      o.updated_at AS "updatedAt",
      o.cancelled_at AS "cancelledAt"
    FROM orders o
    WHERE o.tenant_id = $1 AND o.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );

  if (!rows[0]) throw new HttpError(404, 'Order not found');
  return rows[0];
}

/** ===========================
 *  Cancel TX + log + cancel tasks
 * =========================== */
async function cancelOrderTx({ tenantId, id, notes, cancelledByUserId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const oQ = await client.query(
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
      [tenantId, id]
    );

    const order = oQ.rows[0];
    if (!order) throw new HttpError(404, 'Order not found');

    if (order.status === 'CANCELLED') {
      const full = await client.query(
        `
        SELECT
          o.id,
          o.admission_id AS "admissionId",
          o.patient_id AS "patientId",
          o.kind,
          o.status,
          o.payload,
          o.notes,
          o.created_at AS "createdAt",
          o.updated_at AS "updatedAt",
          o.cancelled_at AS "cancelledAt"
        FROM orders o
        WHERE o.tenant_id = $1 AND o.id = $2
        LIMIT 1
        `,
        [tenantId, id]
      );
      await client.query('COMMIT');
      return full.rows[0];
    }

    if (order.status === 'COMPLETED') {
      throw new HttpError(409, 'لا يمكن إلغاء طلب مكتمل');
    }

    const upd = await client.query(
      `
      UPDATE orders
      SET status = 'CANCELLED'::order_status,
          cancelled_at = now(),
          notes = COALESCE($3, notes),
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        kind,
        status,
        payload,
        notes,
        created_at AS "createdAt",
        updated_at AS "updatedAt",
        cancelled_at AS "cancelledAt"
      `,
      [tenantId, id, notes || null]
    );

    const tUpd = await client.query(
      `
      UPDATE nursing_tasks
      SET status = 'CANCELLED'::task_status,
          cancelled_at = now(),
          updated_at = now()
      WHERE tenant_id = $1 AND order_id = $2 AND status IN ('PENDING','STARTED')
      RETURNING id
      `,
      [tenantId, id]
    );

    await writePatientLogTx({
      client,
      tenantId,
      patientId: upd.rows[0].patientId,
      admissionId: upd.rows[0].admissionId,
      actorUserId: cancelledByUserId || null,
      eventType: 'ORDER_CANCELLED',
      message: 'تم إلغاء الطلب',
      meta: {
        orderId: id,
        kind: upd.rows[0].kind,
        payload: upd.rows[0].payload,
        cancelledTasks: tUpd.rows.map((r) => r.id),
        notes: notes || null,
      },
    });

    await client.query('COMMIT');
    return upd.rows[0];
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

/** ===========================
 *  Pharmacy actions (اللوجك الجديد payload.pharmacy)
 * =========================== */
async function _lockOrderTx(client, { tenantId, orderId }) {
  const q = await client.query(
    `
    SELECT
      o.id,
      o.tenant_id AS "tenantId",
      o.admission_id AS "admissionId",
      o.patient_id AS "patientId",
      o.kind,
      o.status,
      o.payload,
      o.notes
    FROM orders o
    WHERE o.tenant_id = $1 AND o.id = $2
    FOR UPDATE
    `,
    [tenantId, orderId]
  );

  const order = q.rows[0];
  if (!order) throw new HttpError(404, 'Order not found');
  return order;
}

function _num(x) {
  const n = Number(x);
  return Number.isFinite(n) ? n : null;
}

async function pharmacyPrepareTx({ tenantId, orderId, actorUserId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const order = await _lockOrderTx(client, { tenantId, orderId });

    if (order.kind !== 'MEDICATION') throw new HttpError(409, 'هذا الإجراء متاح فقط لطلبات الدواء');
    if (order.status === 'CANCELLED') throw new HttpError(409, 'الطلب ملغي');

    // إذا مكتمل بالفعل: نرجع order الحالي بدون تغيير
    if (order.status === 'COMPLETED') {
      await client.query('COMMIT');
      return { order };
    }

    const payload = order.payload || {};
    const requestedQty = _num(payload.requestedQty) ?? null;
    const preparedQty = requestedQty; // FULL = requestedQty

    payload.pharmacy = {
      ...(payload.pharmacy || {}),
      preparedQty,
      preparedAt: new Date().toISOString(),
      mode: 'FULL',
      notes: notes || null,
    };

    const upd = await client.query(
      `
      UPDATE orders
      SET status = 'COMPLETED'::order_status,
          payload = $3::jsonb,
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        kind,
        status,
        payload,
        notes,
        created_at AS "createdAt",
        updated_at AS "updatedAt"
      `,
      [tenantId, orderId, JSON.stringify(payload)]
    );

    await writePatientLogTx({
      client,
      tenantId,
      patientId: upd.rows[0].patientId,
      admissionId: upd.rows[0].admissionId,
      actorUserId,
      eventType: 'MED_ORDER_PREPARED',
      message: 'تم تجهيز طلب الدواء بالكامل',
      meta: { orderId, requestedQty, preparedQty, notes: notes || null },
    });

    await client.query('COMMIT');
    return { order: upd.rows[0] };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function pharmacyPartialTx({ tenantId, orderId, preparedQty, actorUserId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const order = await _lockOrderTx(client, { tenantId, orderId });

    if (order.kind !== 'MEDICATION') throw new HttpError(409, 'هذا الإجراء متاح فقط لطلبات الدواء');
    if (order.status === 'CANCELLED') throw new HttpError(409, 'الطلب ملغي');
    if (order.status === 'COMPLETED') throw new HttpError(409, 'الطلب مكتمل بالفعل');

    const payload = order.payload || {};
    const requestedQty = _num(payload.requestedQty);

    const pQty = _num(preparedQty);
    if (!pQty || pQty <= 0) throw new HttpError(400, 'preparedQty غير صالح');

    if (requestedQty != null && pQty > requestedQty) {
      throw new HttpError(400, 'preparedQty لا يمكن أن يكون أكبر من requestedQty');
    }

    payload.pharmacy = {
      ...(payload.pharmacy || {}),
      preparedQty: pQty,
      preparedAt: new Date().toISOString(),
      mode: 'PARTIAL',
      notes: notes || null,
    };

    const upd = await client.query(
      `
      UPDATE orders
      SET status = 'PARTIALLY_COMPLETED'::order_status,
          payload = $3::jsonb,
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        kind,
        status,
        payload,
        notes,
        created_at AS "createdAt",
        updated_at AS "updatedAt"
      `,
      [tenantId, orderId, JSON.stringify(payload)]
    );

    await writePatientLogTx({
      client,
      tenantId,
      patientId: upd.rows[0].patientId,
      admissionId: upd.rows[0].admissionId,
      actorUserId,
      eventType: 'MED_ORDER_PARTIAL',
      message: 'تم تجهيز طلب الدواء بشكل جزئي',
      meta: { orderId, requestedQty: requestedQty ?? null, preparedQty: pQty, notes: notes || null },
    });

    await client.query('COMMIT');
    return { order: upd.rows[0] };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function pharmacyOutOfStockTx({ tenantId, orderId, actorUserId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const order = await _lockOrderTx(client, { tenantId, orderId });

    if (order.kind !== 'MEDICATION') throw new HttpError(409, 'هذا الإجراء متاح فقط لطلبات الدواء');
    if (order.status === 'CANCELLED') throw new HttpError(409, 'الطلب ملغي');
    if (order.status === 'COMPLETED') throw new HttpError(409, 'الطلب مكتمل بالفعل');

    const payload = order.payload || {};
    const requestedQty = _num(payload.requestedQty) ?? null;

    payload.pharmacy = {
      ...(payload.pharmacy || {}),
      outOfStockAt: new Date().toISOString(),
      mode: 'OUT_OF_STOCK',
      notes: notes || null,
    };

    const upd = await client.query(
      `
      UPDATE orders
      SET status = 'OUT_OF_STOCK'::order_status,
          payload = $3::jsonb,
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        admission_id AS "admissionId",
        patient_id AS "patientId",
        kind,
        status,
        payload,
        notes,
        created_at AS "createdAt",
        updated_at AS "updatedAt"
      `,
      [tenantId, orderId, JSON.stringify(payload)]
    );

    await writePatientLogTx({
      client,
      tenantId,
      patientId: upd.rows[0].patientId,
      admissionId: upd.rows[0].admissionId,
      actorUserId,
      eventType: 'MED_ORDER_OUT_OF_STOCK',
      message: 'تم إبلاغ الطبيب بنفاد الكمية',
      meta: { orderId, requestedQty, notes: notes || null },
    });

    await client.query('COMMIT');
    return { order: upd.rows[0] };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

/** ===========================
 *  Patient medication view (بدون status)
 * =========================== */
async function listPatientMedicationView({ tenantId, patientId, limit = 50, offset = 0 }) {
  if (!patientId) throw new HttpError(400, 'patientId missing in token');

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
    [tenantId, patientId, limit, offset]
  );

  const items = rows.map((r) => {
    const p = r.payload || {};
    return {
      orderId: r.id,
      admissionId: r.admissionId,
      createdAt: r.createdAt,

      medicationName: p.medicationName || null,
      dose: p.dose || null,
      route: p.route || null,
      frequency: p.frequency || null,
      duration: p.duration || null,

      dosageText: p.dosageText ?? null,
      frequencyText: p.frequencyText ?? null,
      durationText: p.durationText ?? null,
      withFood: p.withFood ?? null,
      patientInstructionsAr: p.patientInstructionsAr ?? null,
      patientInstructionsEn: p.patientInstructionsEn ?? null,
      warningsText: p.warningsText ?? null,
    };
  });

  // ✅ meta.total الصحيح = عدد النتائج الكلي (إذا تريد) يحتاج COUNT. حالياً مثل كودك: items.length
  return { items, meta: { limit, offset, total: items.length } };
}

module.exports = {
  ensureAdmissionInTenant,

  createOrderTx,
  listOrders,
  getOrder,
  cancelOrderTx,

  pharmacyPrepareTx,
  pharmacyPartialTx,
  pharmacyOutOfStockTx,

  listPatientMedicationView,
};
