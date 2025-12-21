// src/routes/lookups.routes.js
const express = require('express');
const pool = require('../db/pool');

const { requireAuth } = require('../middlewares/auth');
const { HttpError } = require('../utils/httpError');

const router = express.Router();

function str(v) {
  return String(v ?? '').trim();
}

function toInt(v, def = 20) {
  const n = Number.parseInt(String(v ?? ''), 10);
  if (Number.isFinite(n) && n > 0) return n;
  return def;
}

function normalizeRole(v) {
  return String(v ?? '').toUpperCase().trim();
}

// ✅ Patients lookup (FIXED for your schema)
// GET /api/lookups/patients?q=&limit=
router.get('/patients', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

    const q = str(req.query.q);
    const limit = Math.min(toInt(req.query.limit, 20), 50);

    // params:
    // $1 tenantId
    // $2 limit
    // $3 pattern (optional)
    const params = [tenantId, limit];

    let where = `p.tenant_id = $1`;
    if (q) {
      params.push(`%${q}%`);
      where += ` AND (
        p.full_name ILIKE $3
        OR COALESCE(p.phone,'') ILIKE $3
      )`;
    }

    const sql = `
      SELECT
        p.id,
        p.full_name AS "fullName",
        p.phone
      FROM patients p
      WHERE ${where}
      ORDER BY p.full_name ASC
      LIMIT $2
    `;

    const r = await pool.query(sql, params);

    const items = r.rows.map(x => ({
      id: x.id,
      label: x.phone ? `${x.fullName} — ${x.phone}` : `${x.fullName}`,
      sub: x.phone || '',
      fullName: x.fullName,
      phone: x.phone,
    }));

    return res.json({ ok: true, items });
  } catch (err) {
    next(err);
  }
});


/**
 * ✅ Staff lookup
 * GET /api/lookups/staff?role=NURSE&q=&limit=
 * - الهدف: Doctor/Admin يختارون موظف بالاسم حسب role
 */
router.get('/staff', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

    const role = normalizeRole(req.query.role);
    if (!role) return next(new HttpError(400, 'role is required'));

    const q = str(req.query.q);
    const limit = Math.min(toInt(req.query.limit, 20), 50);

    // ✅ السماح: DOCTOR و ADMIN فقط (حسب طلبك)
    const rolesRaw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const roles = rolesRaw
      .map(r => (typeof r === 'string' ? r : r?.name))
      .filter(Boolean)
      .map(x => String(x).toUpperCase().trim());

    const canLookupStaff = roles.includes('DOCTOR') || roles.includes('ADMIN');
    if (!canLookupStaff) return next(new HttpError(403, 'Forbidden'));

    // نفترض وجود:
    // users (id, tenant_id, full_name, staff_code, email, phone, is_active)
    // user_roles (user_id, role_id)
    // roles (id, name)
    //
    // إذا اسم جدول user_roles عندك مختلف، فقط غيّره هنا.
    const params = [tenantId, role, limit];
    let qFilter = '';
    if (q) {
      params.push(`%${q}%`);
      qFilter = `
        AND (
          u.full_name ILIKE $4
          OR COALESCE(u.staff_code,'') ILIKE $4
          OR COALESCE(u.email,'') ILIKE $4
          OR COALESCE(u.phone,'') ILIKE $4
        )
      `;
    }

    const sql = `
      SELECT
        u.id,
        u.full_name AS "fullName",
        u.staff_code AS "staffCode",
        u.email,
        u.phone
      FROM users u
      WHERE
        u.tenant_id = $1
        AND u.is_active = true
        AND EXISTS (
          SELECT 1
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = u.id
            AND UPPER(r.name) = $2
        )
        ${qFilter}
      ORDER BY u.full_name ASC
      LIMIT $3
    `;

    const r = await pool.query(sql, params);

    const items = r.rows.map(x => ({
      id: x.id,
      label: x.staffCode ? `${x.fullName} — ${x.staffCode}` : `${x.fullName}`,
      sub: x.phone || x.email || '',
      fullName: x.fullName,
      staffCode: x.staffCode,
      email: x.email,
      phone: x.phone,
    }));

    return res.json({ ok: true, items });
  } catch (err) {
    next(err);
  }
});
// ✅ Departments lookup
router.get('/departments', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    const q = String(req.query.q || '').trim();

    const params = [tenantId];
    let where = `WHERE tenant_id = $1 AND is_active = true`;

    if (q) {
      params.push(`%${q}%`);
      const p = `$${params.length}`;
      where += ` AND (name ILIKE ${p} OR code ILIKE ${p})`;
    }

    const { rows } = await pool.query(
      `
      SELECT id, code, name
      FROM departments
      ${where}
      ORDER BY name ASC
      LIMIT 100
      `,
      params
    );

    return res.json({ ok: true, items: rows });
  } catch (e) {
    return next(e);
  }
});

module.exports = router;
