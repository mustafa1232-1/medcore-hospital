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
 *  NEW: Patient Log writer (داخل TX)
 *  =========================== */
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
  // إذا جدول patient_log غير موجود بعد عندك، ستظهر مشكلة.
  // لكن بما أننا أنشأناه سابقًا في module patient_log، فهذا طبيعي.
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
  if (kind === 'MEDICATION') {
    return `تم إنشاء طلب دواء: ${payload?.medicationName || ''}`.trim();
  }
  if (kind === 'LAB') {
    return `تم إنشاء طلب تحليل: ${payload?.testName || ''}`.trim();
  }
  if (kind === 'PROCEDURE') {
    return `تم إنشاء طلب إجراء: ${payload?.procedureName || ''}`.trim();
  }
  return 'تم إنشاء طلب';
}

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

    // Admission lock
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

    // Active bed assignment required
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
    if (!activeBed) {
      throw new HttpError(403, 'يجب تعيين غرفة وسرير للمريض قبل تنفيذ أي إجراء');
    }

    // Create Order
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

    // Tasks
    const tasks = await createTasksForOrderTx({
      client,
      tenantId,
      order,
      activeBed,
      createdByUserId,
    });

    // ✅ NEW: log
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
        taskIds: tasks.map(t => t.id),
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
 *  UPDATED: Cancel داخل TX + Log + Cancel tasks atomically
 *  =========================== */
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
      // لا نكسر: رجّع نفس الطلب
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

    // ✅ منع إلغاء مكتمل (منطقي)
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

    // Cancel related tasks (PENDING/STARTED فقط)
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

    // ✅ NEW: Log
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
        cancelledTasks: tUpd.rows.map(r => r.id),
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

module.exports = {
  createOrderTx,
  listOrders,
  getOrder,
  cancelOrderTx,
  ensureAdmissionInTenant,
};
