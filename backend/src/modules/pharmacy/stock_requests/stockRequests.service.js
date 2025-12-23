const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function norm(x) {
  if (x === undefined || x === null) return null;
  const s = String(x).trim();
  return s.length ? s : null;
}

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

function directionForKind(kind) {
  // IN types
  if (['RECEIPT', 'TRANSFER_IN', 'ADJUSTMENT_IN', 'RETURN'].includes(kind)) return +1;
  // OUT types
  if (['DISPENSE', 'TRANSFER_OUT', 'ADJUSTMENT_OUT', 'WASTE'].includes(kind)) return -1;
  throw new HttpError(400, `Unsupported kind: ${kind}`);
}

async function ensureWarehouse({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, is_active FROM warehouses WHERE tenant_id = $1 AND id = $2 LIMIT 1`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(400, 'Invalid warehouseId');
  if (!rows[0].is_active) throw new HttpError(409, 'Warehouse is inactive');
  return rows[0];
}

async function ensureDrug({ tenantId, id }) {
  const { rows } = await pool.query(
    `SELECT id, is_active FROM drug_catalog WHERE tenant_id = $1 AND id = $2 LIMIT 1`,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(400, 'Invalid drugId');
  if (!rows[0].is_active) throw new HttpError(409, 'Drug is inactive');
  return rows[0];
}

async function getRequestOr404({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      sr.id,
      sr.tenant_id AS "tenantId",
      sr.kind,
      sr.status,
      sr.from_warehouse_id AS "fromWarehouseId",
      sr.to_warehouse_id AS "toWarehouseId",
      sr.patient_id AS "patientId",
      sr.admission_id AS "admissionId",
      sr.order_id AS "orderId",
      sr.submitted_by_user_id AS "submittedByUserId",
      sr.submitted_at AS "submittedAt",
      sr.approved_by_user_id AS "approvedByUserId",
      sr.approved_at AS "approvedAt",
      sr.notes,
      sr.created_at AS "createdAt"
    FROM stock_requests sr
    WHERE sr.tenant_id = $1 AND sr.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Stock request not found');
  return rows[0];
}

async function listLines({ tenantId, requestId }) {
  const { rows } = await pool.query(
    `
    SELECT
      srl.id,
      srl.request_id AS "requestId",
      srl.drug_id AS "drugId",
      srl.lot_number AS "lotNumber",
      srl.expiry_date AS "expiryDate",
      srl.unit_cost AS "unitCost",
      srl.qty,
      srl.notes
    FROM stock_request_lines srl
    WHERE srl.tenant_id = $1 AND srl.request_id = $2
    ORDER BY srl.id ASC
    `,
    [tenantId, requestId]
  );
  return rows;
}

async function getRequestDetails({ tenantId, id }) {
  const req = await getRequestOr404({ tenantId, id });
  const lines = await listLines({ tenantId, requestId: id });
  return { ...req, lines };
}

async function listRequests({ tenantId, query }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const where = ['sr.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (query.status) { params.push(query.status); where.push(`sr.status = $${i++}::request_status`); }
  if (query.kind) { params.push(query.kind); where.push(`sr.kind = $${i++}::stock_move_type`); }
  if (query.fromWarehouseId) { params.push(query.fromWarehouseId); where.push(`sr.from_warehouse_id = $${i++}`); }
  if (query.toWarehouseId) { params.push(query.toWarehouseId); where.push(`sr.to_warehouse_id = $${i++}`); }
  if (query.patientId) { params.push(query.patientId); where.push(`sr.patient_id = $${i++}`); }
  if (query.admissionId) { params.push(query.admissionId); where.push(`sr.admission_id = $${i++}`); }
  if (query.orderId) { params.push(query.orderId); where.push(`sr.order_id = $${i++}`); }

  const limit = clampInt(query.limit, { min: 1, max: 200, fallback: 50 });
  const offset = clampInt(query.offset, { min: 0, max: 1000000, fallback: 0 });

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM stock_requests sr WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      sr.id,
      sr.kind,
      sr.status,
      sr.from_warehouse_id AS "fromWarehouseId",
      sr.to_warehouse_id AS "toWarehouseId",
      sr.patient_id AS "patientId",
      sr.admission_id AS "admissionId",
      sr.order_id AS "orderId",
      sr.submitted_at AS "submittedAt",
      sr.approved_at AS "approvedAt",
      sr.created_at AS "createdAt"
    FROM stock_requests sr
    WHERE ${where.join(' AND ')}
    ORDER BY sr.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function createRequest({ tenantId, data }) {
  const kind = String(data.kind).trim();
  const fromWarehouseId = data.fromWarehouseId || null;
  const toWarehouseId = data.toWarehouseId || null;

  // Validate warehouses requirements by kind
  if (kind === 'RECEIPT' || kind === 'ADJUSTMENT_IN' || kind === 'RETURN') {
    if (!toWarehouseId) throw new HttpError(400, 'toWarehouseId is required for this kind');
    await ensureWarehouse({ tenantId, id: toWarehouseId });
  }

  if (kind === 'DISPENSE' || kind === 'WASTE' || kind === 'ADJUSTMENT_OUT') {
    if (!fromWarehouseId) throw new HttpError(400, 'fromWarehouseId is required for this kind');
    await ensureWarehouse({ tenantId, id: fromWarehouseId });
  }

  if (kind === 'TRANSFER_OUT' || kind === 'TRANSFER_IN') {
    if (!fromWarehouseId || !toWarehouseId) {
      throw new HttpError(400, 'fromWarehouseId and toWarehouseId are required for transfer');
    }
    if (fromWarehouseId === toWarehouseId) throw new HttpError(400, 'fromWarehouseId cannot equal toWarehouseId');
    await ensureWarehouse({ tenantId, id: fromWarehouseId });
    await ensureWarehouse({ tenantId, id: toWarehouseId });
  }

  // DISPENSE must be linked to order/admission/patient
  const patientId = data.patientId || null;
  const admissionId = data.admissionId || null;
  const orderId = data.orderId || null;

  if (kind === 'DISPENSE') {
    if (!orderId) throw new HttpError(400, 'orderId is required for DISPENSE');
    if (!admissionId) throw new HttpError(400, 'admissionId is required for DISPENSE');
    if (!patientId) throw new HttpError(400, 'patientId is required for DISPENSE');
  }

  const notes = data.notes || null;

  const { rows } = await pool.query(
    `
    INSERT INTO stock_requests (
      tenant_id, kind, status,
      from_warehouse_id, to_warehouse_id,
      patient_id, admission_id, order_id,
      notes, created_at
    )
    VALUES ($1,$2::stock_move_type,'DRAFT'::request_status,$3,$4,$5,$6,$7,$8,now())
    RETURNING
      id,
      kind,
      status,
      from_warehouse_id AS "fromWarehouseId",
      to_warehouse_id AS "toWarehouseId",
      patient_id AS "patientId",
      admission_id AS "admissionId",
      order_id AS "orderId",
      notes,
      created_at AS "createdAt"
    `,
    [tenantId, kind, fromWarehouseId, toWarehouseId, patientId, admissionId, orderId, notes]
  );

  return rows[0];
}

async function ensureDraftEditable({ tenantId, requestId }) {
  const req = await getRequestOr404({ tenantId, id: requestId });
  if (req.status !== 'DRAFT') throw new HttpError(409, 'Request is not editable unless status is DRAFT');
  return req;
}

async function addLine({ tenantId, requestId, data }) {
  await ensureDraftEditable({ tenantId, requestId });
  await ensureDrug({ tenantId, id: data.drugId });

  const { rows } = await pool.query(
    `
    INSERT INTO stock_request_lines (
      tenant_id, request_id, drug_id,
      lot_number, expiry_date, unit_cost,
      qty, notes
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
    RETURNING
      id,
      request_id AS "requestId",
      drug_id AS "drugId",
      lot_number AS "lotNumber",
      expiry_date AS "expiryDate",
      unit_cost AS "unitCost",
      qty,
      notes
    `,
    [
      tenantId,
      requestId,
      data.drugId,
      norm(data.lotNumber),
      data.expiryDate || null,
      data.unitCost === undefined ? null : data.unitCost,
      data.qty,
      data.notes || null,
    ]
  );

  return rows[0];
}

async function updateLine({ tenantId, requestId, lineId, patch }) {
  await ensureDraftEditable({ tenantId, requestId });

  const set = [];
  const values = [tenantId, requestId, lineId];
  let i = 3;

  function push(col, v) {
    values.push(v);
    set.push(`${col} = $${++i}`);
  }

  if (patch.qty !== undefined) push('qty', patch.qty);
  if (patch.lotNumber !== undefined) push('lot_number', norm(patch.lotNumber));
  if (patch.expiryDate !== undefined) push('expiry_date', patch.expiryDate || null);
  if (patch.unitCost !== undefined) push('unit_cost', patch.unitCost === null ? null : patch.unitCost);
  if (patch.notes !== undefined) push('notes', patch.notes || null);

  if (set.length === 0) return null;

  const { rows } = await pool.query(
    `
    UPDATE stock_request_lines
    SET ${set.join(', ')}
    WHERE tenant_id = $1 AND request_id = $2 AND id = $3
    RETURNING
      id,
      request_id AS "requestId",
      drug_id AS "drugId",
      lot_number AS "lotNumber",
      expiry_date AS "expiryDate",
      unit_cost AS "unitCost",
      qty,
      notes
    `,
    values
  );
  if (!rows[0]) throw new HttpError(404, 'Line not found');
  return rows[0];
}

async function removeLine({ tenantId, requestId, lineId }) {
  await ensureDraftEditable({ tenantId, requestId });

  const q = await pool.query(
    `DELETE FROM stock_request_lines WHERE tenant_id = $1 AND request_id = $2 AND id = $3`,
    [tenantId, requestId, lineId]
  );
  if (q.rowCount === 0) throw new HttpError(404, 'Line not found');
  return { ok: true };
}

async function submitRequest({ tenantId, id, submittedByUserId, notes }) {
  const req = await getRequestOr404({ tenantId, id });
  if (req.status !== 'DRAFT') throw new HttpError(409, 'Only DRAFT can be submitted');

  const lines = await listLines({ tenantId, requestId: id });
  if (lines.length === 0) throw new HttpError(409, 'Cannot submit empty request');

  const { rows } = await pool.query(
    `
    UPDATE stock_requests
    SET status = 'SUBMITTED'::request_status,
        submitted_by_user_id = $3,
        submitted_at = now(),
        notes = COALESCE($4, notes)
    WHERE tenant_id = $1 AND id = $2
    RETURNING
      id,
      kind,
      status,
      submitted_at AS "submittedAt"
    `,
    [tenantId, id, submittedByUserId, notes || null]
  );

  return rows[0];
}

// =========================
// Ledger helpers (critical)
// =========================
async function getDrugBalanceTx({ client, tenantId, warehouseId, drugId }) {
  const { rows } = await client.query(
    `
    SELECT COALESCE(SUM(sm.qty * sm.direction), 0)::numeric AS balance
    FROM stock_moves sm
    WHERE sm.tenant_id = $1
      AND sm.warehouse_id = $2
      AND sm.drug_id = $3
      AND sm.status = 'APPROVED'::request_status
    `,
    [tenantId, warehouseId, drugId]
  );
  return Number(rows[0]?.balance || 0);
}

async function ensureDispenseOrderTx({ client, tenantId, orderId, admissionId, patientId }) {
  const { rows } = await client.query(
    `
    SELECT
      o.id,
      o.kind,
      o.status,
      o.admission_id AS "admissionId",
      o.patient_id AS "patientId",
      o.doctor_user_id AS "doctorUserId"
    FROM orders o
    WHERE o.tenant_id = $1 AND o.id = $2
    LIMIT 1
    `,
    [tenantId, orderId]
  );
  const o = rows[0];
  if (!o) throw new HttpError(400, 'Invalid orderId');
  if (o.kind !== 'MEDICATION') throw new HttpError(409, 'DISPENSE must be linked to MEDICATION order');
  if (String(o.admissionId) !== String(admissionId)) throw new HttpError(409, 'order.admissionId mismatch');
  if (String(o.patientId) !== String(patientId)) throw new HttpError(409, 'order.patientId mismatch');
  return o;
}

async function getAdmissionBedSnapshotTx({ client, tenantId, admissionId }) {
  // Snapshot القسم/الغرفة/السرير وقت التنفيذ (لللوغ)
  const { rows } = await client.query(
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
  return rows[0] || null;
}

async function ensureLotTx({ client, tenantId, warehouseId, drugId, lotNumber, expiryDate, unitCost }) {
  const { rows } = await client.query(
    `
    SELECT id
    FROM stock_lots
    WHERE tenant_id = $1
      AND warehouse_id = $2
      AND drug_id = $3
      AND COALESCE(lot_number,'') = COALESCE($4,'')
      AND COALESCE(expiry_date::text,'') = COALESCE($5::date::text,'')
    LIMIT 1
    `,
    [tenantId, warehouseId, drugId, lotNumber || null, expiryDate || null]
  );
  if (rows[0]) return rows[0].id;

  const ins = await client.query(
    `
    INSERT INTO stock_lots (tenant_id, warehouse_id, drug_id, lot_number, expiry_date, unit_cost, created_at)
    VALUES ($1,$2,$3,$4,$5,$6,now())
    RETURNING id
    `,
    [tenantId, warehouseId, drugId, lotNumber || null, expiryDate || null, unitCost ?? null]
  );
  return ins.rows[0].id;
}

// =========================
// APPROVE (Transaction)
// =========================
async function approveRequestTx({ tenantId, id, approvedByUserId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const rQ = await client.query(
      `
      SELECT
        sr.id,
        sr.kind,
        sr.status,
        sr.from_warehouse_id AS "fromWarehouseId",
        sr.to_warehouse_id AS "toWarehouseId",
        sr.patient_id AS "patientId",
        sr.admission_id AS "admissionId",
        sr.order_id AS "orderId",
        sr.submitted_by_user_id AS "submittedByUserId"
      FROM stock_requests sr
      WHERE sr.tenant_id = $1 AND sr.id = $2
      FOR UPDATE
      `,
      [tenantId, id]
    );

    const req = rQ.rows[0];
    if (!req) throw new HttpError(404, 'Stock request not found');
    if (req.status !== 'SUBMITTED') throw new HttpError(409, 'Only SUBMITTED can be approved');

    const linesQ = await client.query(
      `
      SELECT
        id,
        drug_id AS "drugId",
        lot_number AS "lotNumber",
        expiry_date AS "expiryDate",
        unit_cost AS "unitCost",
        qty
      FROM stock_request_lines
      WHERE tenant_id = $1 AND request_id = $2
      ORDER BY id ASC
      `,
      [tenantId, id]
    );

    const lines = linesQ.rows;
    if (lines.length === 0) throw new HttpError(409, 'Cannot approve empty request');

    const kind = req.kind;
    const dir = directionForKind(kind);

    // Warehouses validation in tx
    if (dir === +1) {
      if (!req.toWarehouseId) throw new HttpError(400, 'toWarehouseId is required');
    } else {
      if (!req.fromWarehouseId) throw new HttpError(400, 'fromWarehouseId is required');
    }

    // Strong DISPENSE enforcement + snapshot
    let order = null;
    let snap = null;

    if (kind === 'DISPENSE') {
      if (!req.orderId || !req.admissionId || !req.patientId) {
        throw new HttpError(400, 'DISPENSE requires orderId + admissionId + patientId');
      }

      order = await ensureDispenseOrderTx({
        client,
        tenantId,
        orderId: req.orderId,
        admissionId: req.admissionId,
        patientId: req.patientId,
      });

      snap = await getAdmissionBedSnapshotTx({ client, tenantId, admissionId: req.admissionId });
      if (!snap) {
        throw new HttpError(409, 'لا يمكن صرف الدواء بدون تعيين سرير فعّال للتنويم');
      }
    }

    // For OUT types: enforce balance >= qty per drug (warehouse-level)
    const warehouseId = dir === +1 ? req.toWarehouseId : req.fromWarehouseId;

    // lock warehouse row (optional)
    await client.query(
      `SELECT id FROM warehouses WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, warehouseId]
    );

    // Pre-check balances (aggregate per drug)
    if (dir === -1) {
      const needByDrug = new Map();
      for (const ln of lines) {
        const k = String(ln.drugId);
        needByDrug.set(k, (needByDrug.get(k) || 0) + Number(ln.qty));
      }

      for (const [drugId, need] of needByDrug.entries()) {
        const bal = await getDrugBalanceTx({ client, tenantId, warehouseId, drugId });
        if (bal < need) {
          throw new HttpError(409, `Insufficient stock for drugId=${drugId}. balance=${bal}, need=${need}`);
        }
      }
    }

    // Create moves (one per line)
    const moves = [];
    for (const ln of lines) {
      // ensure drug exists (tx-safe)
      const dQ = await client.query(
        `SELECT id FROM drug_catalog WHERE tenant_id = $1 AND id = $2 AND is_active = true LIMIT 1`,
        [tenantId, ln.drugId]
      );
      if (!dQ.rows[0]) throw new HttpError(409, 'Drug is invalid or inactive');

      // lot row
      const lotId = await ensureLotTx({
        client,
        tenantId,
        warehouseId,
        drugId: ln.drugId,
        lotNumber: ln.lotNumber,
        expiryDate: ln.expiryDate,
        unitCost: ln.unitCost,
      });

      const refType = 'STOCK_REQUEST';
      const refId = req.id;

      // ✅ snapshot columns only for DISPENSE (audit trail)
      const departmentId = kind === 'DISPENSE' ? (snap?.departmentId || null) : null;
      const roomId = kind === 'DISPENSE' ? (snap?.roomId || null) : null;
      const bedId = kind === 'DISPENSE' ? (snap?.bedId || null) : null;

      const ins = await client.query(
        `
        INSERT INTO stock_moves (
          tenant_id,
          move_type,
          status,
          warehouse_id,
          lot_id,
          drug_id,
          qty,
          direction,
          reference_type,
          reference_id,
          patient_id,
          admission_id,
          order_id,
          department_id,
          room_id,
          bed_id,
          created_by_user_id,
          approved_by_user_id,
          approved_at,
          notes,
          created_at
        )
        VALUES (
          $1,
          $2::stock_move_type,
          'APPROVED'::request_status,
          $3,
          $4,
          $5,
          $6,
          $7,
          $8,
          $9,
          $10,
          $11,
          $12,
          $13,
          $14,
          $15,
          $16,
          $17,
          now(),
          $18,
          now()
        )
        RETURNING
          id,
          move_type AS "moveType",
          warehouse_id AS "warehouseId",
          lot_id AS "lotId",
          drug_id AS "drugId",
          qty,
          direction,
          patient_id AS "patientId",
          admission_id AS "admissionId",
          order_id AS "orderId",
          department_id AS "departmentId",
          room_id AS "roomId",
          bed_id AS "bedId",
          created_at AS "createdAt"
        `,
        [
          tenantId,
          kind,
          warehouseId,
          lotId,
          ln.drugId,
          ln.qty,
          dir,
          refType,
          refId,
          kind === 'DISPENSE' ? req.patientId : null,
          kind === 'DISPENSE' ? req.admissionId : null,
          kind === 'DISPENSE' ? req.orderId : null,
          departmentId,
          roomId,
          bedId,
          req.submittedByUserId || null, // who submitted/created the request
          approvedByUserId,
          notes || null,
        ]
      );

      moves.push(ins.rows[0]);
    }

    // Mark request APPROVED
    await client.query(
      `
      UPDATE stock_requests
      SET status = 'APPROVED'::request_status,
          approved_by_user_id = $3,
          approved_at = now(),
          notes = COALESCE($4, notes)
      WHERE tenant_id = $1 AND id = $2
      `,
      [tenantId, id, approvedByUserId, notes || null]
    );

    await client.query('COMMIT');

    const details = await getRequestDetails({ tenantId, id });
    return { request: details, moves, snapshot: snap, order };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function rejectRequest({ tenantId, id, approvedByUserId, notes }) {
  const req = await getRequestOr404({ tenantId, id });
  if (req.status !== 'SUBMITTED') throw new HttpError(409, 'Only SUBMITTED can be rejected');

  const { rows } = await pool.query(
    `
    UPDATE stock_requests
    SET status = 'REJECTED'::request_status,
        approved_by_user_id = $3,
        approved_at = now(),
        notes = COALESCE($4, notes)
    WHERE tenant_id = $1 AND id = $2
    RETURNING
      id,
      kind,
      status,
      approved_at AS "approvedAt"
    `,
    [tenantId, id, approvedByUserId, notes || null]
  );

  return rows[0];
}

module.exports = {
  listRequests,
  getRequestDetails,
  createRequest,
  addLine,
  updateLine,
  removeLine,
  submitRequest,
  approveRequestTx,
  rejectRequest,
};
