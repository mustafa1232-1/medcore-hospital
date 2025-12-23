const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

function normalizeStr(x) {
  if (x === undefined || x === null) return null;
  const s = String(x).trim();
  return s.length ? s : null;
}

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

async function ensureUserIsPharmacy({ tenantId, userId }) {
  // ✅ verify that the assigned user belongs to same tenant and has PHARMACY role
  const { rows } = await pool.query(
    `
    SELECT
      u.id,
      u.tenant_id AS "tenantId",
      u.is_active AS "isActive",
      COALESCE(ur.role, '') AS "role"
    FROM users u
    LEFT JOIN user_roles ur ON ur.user_id = u.id
    WHERE u.tenant_id = $1 AND u.id = $2
    `,
    [tenantId, userId]
  );

  if (!rows.length) throw new HttpError(404, 'Pharmacist user not found');

  const roles = rows.map((r) => String(r.role || '').toUpperCase()).filter(Boolean);
  const isActive = !!rows[0].isActive;

  if (!isActive) throw new HttpError(400, 'Assigned pharmacist is not active');
  if (!roles.includes('PHARMACY')) {
    throw new HttpError(400, 'Assigned user must have PHARMACY role');
  }
}

async function listWarehouses({ tenantId, query }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const q = normalizeStr(query?.q);
  const active = query?.active;

  const limit = clampInt(query?.limit, { min: 1, max: 200, fallback: 50 });
  const offset = clampInt(query?.offset, { min: 0, max: 1000000, fallback: 0 });

  const where = ['w.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (q) {
    params.push(`%${q.toLowerCase()}%`);
    where.push(
      `(LOWER(w.name) LIKE $${i} OR LOWER(COALESCE(w.code,'')) LIKE $${i})`
    );
    i++;
  }

  if (active !== undefined) {
    params.push(!!active);
    where.push(`w.is_active = $${i++}`);
  }

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM warehouses w WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      w.id,
      w.name,
      w.code,
      w.is_active AS "isActive",
      w.created_at AS "createdAt",

      w.pharmacist_user_id AS "pharmacistUserId",
      pu.full_name AS "pharmacistName",
      pu.staff_code AS "pharmacistStaffCode"
    FROM warehouses w
    LEFT JOIN users pu ON pu.id = w.pharmacist_user_id
    WHERE ${where.join(' AND ')}
    ORDER BY w.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getWarehouse({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      w.id,
      w.name,
      w.code,
      w.is_active AS "isActive",
      w.created_at AS "createdAt",

      w.pharmacist_user_id AS "pharmacistUserId",
      pu.full_name AS "pharmacistName",
      pu.staff_code AS "pharmacistStaffCode"
    FROM warehouses w
    LEFT JOIN users pu ON pu.id = w.pharmacist_user_id
    WHERE w.tenant_id = $1 AND w.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );

  if (!rows[0]) throw new HttpError(404, 'Warehouse not found');
  return rows[0];
}

async function createWarehouse({ tenantId, data }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const name = normalizeStr(data.name);
  if (!name) throw new HttpError(400, 'name is required');

  const code = normalizeStr(data.code);
  const isActive = data.isActive === undefined ? true : !!data.isActive;

  const pharmacistUserId = normalizeStr(data.pharmacistUserId);
  if (!pharmacistUserId) throw new HttpError(400, 'pharmacistUserId is required');

  // ✅ enforce: warehouse واحد لكل Tenant حالياً
  const existing = await pool.query(
    `
    SELECT id
    FROM warehouses
    WHERE tenant_id = $1
    LIMIT 1
    `,
    [tenantId]
  );
  if (existing.rows[0]) {
    throw new HttpError(409, 'Warehouse already exists for this facility');
  }

  // ✅ ensure assigned user is PHARMACY in same tenant
  await ensureUserIsPharmacy({ tenantId, userId: pharmacistUserId });

  try {
    const { rows } = await pool.query(
      `
      INSERT INTO warehouses (tenant_id, name, code, is_active, pharmacist_user_id, created_at)
      VALUES ($1,$2,$3,$4,$5, now())
      RETURNING
        id,
        name,
        code,
        is_active AS "isActive",
        pharmacist_user_id AS "pharmacistUserId",
        created_at AS "createdAt"
      `,
      [tenantId, name, code, isActive, pharmacistUserId]
    );

    // enrich pharmacist info
    return getWarehouse({ tenantId, id: rows[0].id });
  } catch (e) {
    if (e && e.code === '23505') {
      throw new HttpError(409, 'Warehouse name already exists');
    }
    throw e;
  }
}

async function updateWarehouse({ tenantId, id, patch }) {
  await getWarehouse({ tenantId, id });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  function push(col, v) {
    values.push(v);
    set.push(`${col} = $${++i}`);
  }

  if (patch.name !== undefined) push('name', normalizeStr(patch.name));
  if (patch.code !== undefined) push('code', normalizeStr(patch.code));
  if (patch.isActive !== undefined) push('is_active', !!patch.isActive);

  if (patch.pharmacistUserId !== undefined) {
    const pharmacistUserId = normalizeStr(patch.pharmacistUserId);
    if (!pharmacistUserId) throw new HttpError(400, 'pharmacistUserId is invalid');
    await ensureUserIsPharmacy({ tenantId, userId: pharmacistUserId });
    push('pharmacist_user_id', pharmacistUserId);
  }

  if (set.length === 0) return getWarehouse({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `
      UPDATE warehouses
      SET ${set.join(', ')}
      WHERE tenant_id = $1 AND id = $2
      RETURNING id
      `,
      values
    );

    return getWarehouse({ tenantId, id: rows[0].id });
  } catch (e) {
    if (e && e.code === '23505') {
      throw new HttpError(409, 'Warehouse name already exists');
    }
    throw e;
  }
}

async function softDeleteWarehouse({ tenantId, id }) {
  await getWarehouse({ tenantId, id });

  const { rows } = await pool.query(
    `
    UPDATE warehouses
    SET is_active = false
    WHERE tenant_id = $1 AND id = $2
    RETURNING id
    `,
    [tenantId, id]
  );

  return getWarehouse({ tenantId, id: rows[0].id });
}

module.exports = {
  listWarehouses,
  getWarehouse,
  createWarehouse,
  updateWarehouse,
  softDeleteWarehouse,
};
