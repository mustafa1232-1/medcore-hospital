// src/modules/tasks/tasks.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function listMyTasks({ tenantId, nurseUserId, query }) {
  const where = ['t.tenant_id = $1', '(t.assigned_to_user_id = $2 OR t.assigned_to_user_id IS NULL)'];
  const params = [tenantId, nurseUserId];
  let i = 3;

  if (query.status) {
    params.push(query.status);
    where.push(`t.status = $${i++}::task_status`);
  } else {
    // افتراضيًا: اعرض المهام الفعالة
    where.push(`t.status IN ('PENDING','STARTED')`);
  }

  const limit = query.limit ?? 30;
  const offset = query.offset ?? 0;

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM nursing_tasks t WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      t.id,
      t.admission_id AS "admissionId",
      t.patient_id AS "patientId",
      t.order_id AS "orderId",
      t.title,
      t.details,
      t.kind,
      t.status,
      t.assigned_to_user_id AS "assignedToUserId",
      t.started_at AS "startedAt",
      t.completed_at AS "completedAt",
      t.created_at AS "createdAt"
    FROM nursing_tasks t
    WHERE ${where.join(' AND ')}
    ORDER BY
      CASE WHEN t.status = 'PENDING' THEN 1 WHEN t.status = 'STARTED' THEN 2 ELSE 3 END,
      t.created_at ASC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getTaskOr404({ tenantId, taskId }) {
  const { rows } = await pool.query(
    `
    SELECT
      t.*,
      t.admission_id AS "admissionId",
      t.order_id AS "orderId",
      t.assigned_to_user_id AS "assignedToUserId"
    FROM nursing_tasks t
    WHERE t.tenant_id = $1 AND t.id = $2
    LIMIT 1
    `,
    [tenantId, taskId]
  );
  if (!rows[0]) throw new HttpError(404, 'Task not found');
  return rows[0];
}

async function startTask({ tenantId, taskId, nurseUserId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const tQ = await client.query(
      `SELECT id, status, assigned_to_user_id, order_id
       FROM nursing_tasks
       WHERE tenant_id = $1 AND id = $2
       FOR UPDATE`,
      [tenantId, taskId]
    );

    const t = tQ.rows[0];
    if (!t) throw new HttpError(404, 'Task not found');
    if (t.status !== 'PENDING') throw new HttpError(409, 'Task is not PENDING');

    if (t.assigned_to_user_id && t.assigned_to_user_id !== nurseUserId) {
      throw new HttpError(403, 'Forbidden');
    }

    const upd = await client.query(
      `
      UPDATE nursing_tasks
      SET status = 'STARTED'::task_status,
          assigned_to_user_id = COALESCE(assigned_to_user_id, $3),
          started_at = COALESCE(started_at, now()),
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING id, status, assigned_to_user_id AS "assignedToUserId", started_at AS "startedAt"
      `,
      [tenantId, taskId, nurseUserId]
    );

    if (t.order_id) {
      await client.query(
        `
        UPDATE orders
        SET status = CASE
          WHEN status = 'CREATED'::order_status THEN 'IN_PROGRESS'::order_status
          ELSE status
        END,
        updated_at = now()
        WHERE tenant_id = $1 AND id = $2
        `,
        [tenantId, t.order_id]
      );
    }

    await client.query('COMMIT');
    return upd.rows[0];
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function completeTask({ tenantId, taskId, nurseUserId, note }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const tQ = await client.query(
      `SELECT id, status, assigned_to_user_id, order_id
       FROM nursing_tasks
       WHERE tenant_id = $1 AND id = $2
       FOR UPDATE`,
      [tenantId, taskId]
    );

    const t = tQ.rows[0];
    if (!t) throw new HttpError(404, 'Task not found');

    if (!['PENDING', 'STARTED'].includes(t.status)) {
      throw new HttpError(409, 'Task is not completable');
    }

    if (t.assigned_to_user_id && t.assigned_to_user_id !== nurseUserId) {
      throw new HttpError(403, 'Forbidden');
    }

    const upd = await client.query(
      `
      UPDATE nursing_tasks
      SET status = 'COMPLETED'::task_status,
          assigned_to_user_id = COALESCE(assigned_to_user_id, $3),
          started_at = COALESCE(started_at, now()),
          completed_at = now(),
          details = CASE
            WHEN $4 IS NULL OR $4 = '' THEN details
            ELSE COALESCE(details,'') || E'\n' || 'NOTE: ' || $4
          END,
          updated_at = now()
      WHERE tenant_id = $1 AND id = $2
      RETURNING id, status, assigned_to_user_id AS "assignedToUserId", completed_at AS "completedAt"
      `,
      [tenantId, taskId, nurseUserId, note || null]
    );

    if (t.order_id) {
      const remaining = await client.query(
        `
        SELECT 1
        FROM nursing_tasks
        WHERE tenant_id = $1 AND order_id = $2
          AND status IN ('PENDING','STARTED')
        LIMIT 1
        `,
        [tenantId, t.order_id]
      );

      if (!remaining.rows[0]) {
        await client.query(
          `
          UPDATE orders
          SET status = 'COMPLETED'::order_status,
              updated_at = now()
          WHERE tenant_id = $1 AND id = $2
            AND status <> 'CANCELLED'::order_status
          `,
          [tenantId, t.order_id]
        );
      }
    }

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
  listMyTasks,
  startTask,
  completeTask,
  getTaskOr404,
};
