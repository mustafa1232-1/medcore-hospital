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
    where.push(`(LOWER(w.name) LIKE $${i} OR LOWER(COALESCE(w.code,'')) LIKE $${i})`);
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
      w.created_at AS "createdAt"
    FROM warehouses w
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
      w.created_at AS "createdAt"
    FROM warehouses w
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

  try {
    const { rows } = await pool.query(
      `
      INSERT INTO warehouses (tenant_id, name, code, is_active, created_at)
      VALUES ($1,$2,$3,$4, now())
      RETURNING
        id,
        name,
        code,
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      [tenantId, name, code, isActive]
    );
    return rows[0];
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

  if (set.length === 0) return getWarehouse({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `
      UPDATE warehouses
      SET ${set.join(', ')}
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        name,
        code,
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      values
    );
    return rows[0];
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
    RETURNING
      id,
      name,
      code,
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    [tenantId, id]
  );

  return rows[0];
}

module.exports = {
  listWarehouses,
  getWarehouse,
  createWarehouse,
  updateWarehouse,
  softDeleteWarehouse,
};
