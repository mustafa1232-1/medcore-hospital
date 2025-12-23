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

async function listDrugs({ tenantId, query }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const q = normalizeStr(query?.q);
  const active = query?.active;
  const form = normalizeStr(query?.form);
  const route = normalizeStr(query?.route);

  const limit = clampInt(query?.limit, { min: 1, max: 200, fallback: 50 });
  const offset = clampInt(query?.offset, { min: 0, max: 1000000, fallback: 0 });

  const where = ['dc.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (q) {
    params.push(`%${q.toLowerCase()}%`);
    where.push(
      `(LOWER(dc.generic_name) LIKE $${i} OR LOWER(COALESCE(dc.brand_name,'')) LIKE $${i} OR LOWER(COALESCE(dc.strength,'')) LIKE $${i})`
    );
    i++;
  }

  if (active !== undefined) {
    params.push(!!active);
    where.push(`dc.is_active = $${i++}`);
  }

  if (form) {
    params.push(form);
    where.push(`dc.form = $${i++}::drug_form`);
  }

  if (route) {
    params.push(route.toLowerCase());
    where.push(`LOWER(COALESCE(dc.route,'')) = $${i++}`);
  }

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM drug_catalog dc WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      dc.id,
      dc.generic_name AS "genericName",
      dc.brand_name AS "brandName",
      dc.strength,
      dc.form,
      dc.route,
      dc.unit,
      dc.pack_size AS "packSize",
      dc.barcode,
      dc.atc_code AS "atcCode",
      dc.is_active AS "isActive",
      dc.created_at AS "createdAt"
    FROM drug_catalog dc
    WHERE ${where.join(' AND ')}
    ORDER BY dc.generic_name ASC, dc.strength ASC NULLS LAST
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function getDrug({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      dc.id,
      dc.generic_name AS "genericName",
      dc.brand_name AS "brandName",
      dc.strength,
      dc.form,
      dc.route,
      dc.unit,
      dc.pack_size AS "packSize",
      dc.barcode,
      dc.atc_code AS "atcCode",
      dc.is_active AS "isActive",
      dc.created_at AS "createdAt"
    FROM drug_catalog dc
    WHERE dc.tenant_id = $1 AND dc.id = $2
    LIMIT 1
    `,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Drug not found');
  return rows[0];
}

async function createDrug({ tenantId, data }) {
  const genericName = normalizeStr(data.genericName);
  if (!genericName) throw new HttpError(400, 'genericName is required');

  const brandName = normalizeStr(data.brandName);
  const strength = normalizeStr(data.strength);
  const form = (data.form || 'OTHER').toUpperCase().trim();
  const route = normalizeStr(data.route);
  const unit = normalizeStr(data.unit);
  const packSize = data.packSize === null || data.packSize === undefined ? null : Number(data.packSize);
  const barcode = normalizeStr(data.barcode);
  const atcCode = normalizeStr(data.atcCode);
  const isActive = data.isActive === undefined ? true : !!data.isActive;

  try {
    const { rows } = await pool.query(
      `
      INSERT INTO drug_catalog (
        tenant_id,
        generic_name,
        brand_name,
        strength,
        form,
        route,
        unit,
        pack_size,
        barcode,
        atc_code,
        is_active,
        created_at
      )
      VALUES ($1,$2,$3,$4,$5::drug_form,$6,$7,$8,$9,$10,$11, now())
      RETURNING
        id,
        generic_name AS "genericName",
        brand_name AS "brandName",
        strength,
        form,
        route,
        unit,
        pack_size AS "packSize",
        barcode,
        atc_code AS "atcCode",
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      [
        tenantId,
        genericName,
        brandName,
        strength,
        form,
        route,
        unit,
        packSize,
        barcode,
        atcCode,
        isActive,
      ]
    );
    return rows[0];
  } catch (e) {
    if (e && e.code === '23505') {
      throw new HttpError(409, 'Duplicate drug (same generic/strength/form/route/unit)');
    }
    throw e;
  }
}

async function updateDrug({ tenantId, id, patch }) {
  await getDrug({ tenantId, id });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  function push(col, v) {
    values.push(v);
    set.push(`${col} = $${++i}`);
  }

  if (patch.genericName !== undefined) push('generic_name', normalizeStr(patch.genericName));
  if (patch.brandName !== undefined) push('brand_name', normalizeStr(patch.brandName));
  if (patch.strength !== undefined) push('strength', normalizeStr(patch.strength));
  if (patch.form !== undefined) push('form', String(patch.form).toUpperCase().trim());
  if (patch.route !== undefined) push('route', normalizeStr(patch.route));
  if (patch.unit !== undefined) push('unit', normalizeStr(patch.unit));
  if (patch.packSize !== undefined) push('pack_size', patch.packSize === null ? null : Number(patch.packSize));
  if (patch.barcode !== undefined) push('barcode', normalizeStr(patch.barcode));
  if (patch.atcCode !== undefined) push('atc_code', normalizeStr(patch.atcCode));
  if (patch.isActive !== undefined) push('is_active', !!patch.isActive);

  if (set.length === 0) return getDrug({ tenantId, id });

  try {
    const { rows } = await pool.query(
      `
      UPDATE drug_catalog
      SET ${set.join(', ')}
      WHERE tenant_id = $1 AND id = $2
      RETURNING
        id,
        generic_name AS "genericName",
        brand_name AS "brandName",
        strength,
        form,
        route,
        unit,
        pack_size AS "packSize",
        barcode,
        atc_code AS "atcCode",
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      values
    );
    return rows[0];
  } catch (e) {
    if (e && e.code === '23505') {
      throw new HttpError(409, 'Duplicate drug (same generic/strength/form/route/unit)');
    }
    throw e;
  }
}

async function softDeleteDrug({ tenantId, id }) {
  await getDrug({ tenantId, id });

  const { rows } = await pool.query(
    `
    UPDATE drug_catalog
    SET is_active = false
    WHERE tenant_id = $1 AND id = $2
    RETURNING
      id,
      generic_name AS "genericName",
      brand_name AS "brandName",
      strength,
      form,
      route,
      unit,
      pack_size AS "packSize",
      barcode,
      atc_code AS "atcCode",
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    [tenantId, id]
  );

  return rows[0];
}

module.exports = {
  listDrugs,
  getDrug,
  createDrug,
  updateDrug,
  softDeleteDrug,
};
