// src/modules/pharmacy/stock/stock.service.js
const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

async function getBalance({ tenantId, query }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const warehouseId = query.warehouseId;
  const drugId = query.drugId || null;

  const limit = clampInt(query.limit, { min: 1, max: 200, fallback: 50 });
  const offset = clampInt(query.offset, { min: 0, max: 1000000, fallback: 0 });

  // verify warehouse
  const w = await pool.query(
    `SELECT id FROM warehouses WHERE tenant_id = $1 AND id = $2 AND is_active = true LIMIT 1`,
    [tenantId, warehouseId]
  );
  if (!w.rows[0]) throw new HttpError(400, 'Invalid warehouseId');

  const where = ['sm.tenant_id = $1', 'sm.warehouse_id = $2', `sm.status = 'APPROVED'::request_status`];
  const params = [tenantId, warehouseId];
  let i = 3;

  if (drugId) {
    params.push(drugId);
    where.push(`sm.drug_id = $${i++}`);
  }

  // balance per drug
  // IMPORTANT: stock_moves.qty is positive, direction is +1/-1
  const countQ = await pool.query(
    `
    SELECT COUNT(*)::int AS count
    FROM (
      SELECT sm.drug_id
      FROM stock_moves sm
      WHERE ${where.join(' AND ')}
      GROUP BY sm.drug_id
    ) x
    `,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      sm.drug_id AS "drugId",
      dc.generic_name AS "genericName",
      dc.brand_name AS "brandName",
      dc.strength,
      dc.form,
      dc.route,
      SUM(sm.qty * sm.direction)::numeric AS balance
    FROM stock_moves sm
    JOIN drug_catalog dc ON dc.id = sm.drug_id
    WHERE ${where.join(' AND ')}
    GROUP BY sm.drug_id, dc.generic_name, dc.brand_name, dc.strength, dc.form, dc.route
    ORDER BY dc.generic_name ASC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getLedger({ tenantId, query }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const where = ['sm.tenant_id = $1', `sm.status = 'APPROVED'::request_status`];
  const params = [tenantId];
  let i = 2;

  if (query.drugId) { params.push(query.drugId); where.push(`sm.drug_id = $${i++}`); }
  if (query.warehouseId) { params.push(query.warehouseId); where.push(`sm.warehouse_id = $${i++}`); }
  if (query.patientId) { params.push(query.patientId); where.push(`sm.patient_id = $${i++}`); }
  if (query.admissionId) { params.push(query.admissionId); where.push(`sm.admission_id = $${i++}`); }
  if (query.orderId) { params.push(query.orderId); where.push(`sm.order_id = $${i++}`); }
  if (query.kind) { params.push(query.kind); where.push(`sm.move_type = $${i++}::stock_move_type`); }

  if (query.from) { params.push(query.from); where.push(`sm.created_at >= $${i++}::timestamptz`); }
  if (query.to) { params.push(query.to); where.push(`sm.created_at <= $${i++}::timestamptz`); }

  const limit = clampInt(query.limit, { min: 1, max: 200, fallback: 50 });
  const offset = clampInt(query.offset, { min: 0, max: 1000000, fallback: 0 });

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM stock_moves sm WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      sm.id,
      sm.move_type AS "moveType",
      sm.warehouse_id AS "warehouseId",
      w.name AS "warehouseName",

      sm.drug_id AS "drugId",
      dc.generic_name AS "genericName",
      dc.brand_name AS "brandName",
      dc.strength,
      dc.form,
      dc.route,

      sm.lot_id AS "lotId",
      sl.lot_number AS "lotNumber",
      sl.expiry_date AS "expiryDate",
      sl.unit_cost AS "unitCost",

      sm.qty,
      sm.direction,

      sm.patient_id AS "patientId",
      p.full_name AS "patientName",

      sm.admission_id AS "admissionId",
      sm.order_id AS "orderId",

      sm.department_id AS "departmentId",
      d.code AS "departmentCode",

      sm.room_id AS "roomId",
      r.code AS "roomCode",

      sm.bed_id AS "bedId",
      b.code AS "bedCode",

      sm.created_by_user_id AS "createdByUserId",
      u1.full_name AS "createdByName",

      sm.approved_by_user_id AS "approvedByUserId",
      u2.full_name AS "approvedByName",

      sm.approved_at AS "approvedAt",
      sm.notes,
      sm.created_at AS "createdAt"
    FROM stock_moves sm
    JOIN warehouses w ON w.id = sm.warehouse_id
    JOIN drug_catalog dc ON dc.id = sm.drug_id
    LEFT JOIN stock_lots sl ON sl.id = sm.lot_id
    LEFT JOIN patients p ON p.id = sm.patient_id
    LEFT JOIN departments d ON d.id = sm.department_id
    LEFT JOIN rooms r ON r.id = sm.room_id
    LEFT JOIN beds b ON b.id = sm.bed_id
    LEFT JOIN users u1 ON u1.id = sm.created_by_user_id
    LEFT JOIN users u2 ON u2.id = sm.approved_by_user_id
    WHERE ${where.join(' AND ')}
    ORDER BY sm.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

module.exports = { getBalance, getLedger };
