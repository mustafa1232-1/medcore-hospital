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

// ✅ Patients lookup
// GET /api/lookups/patients?q=&limit=
router.get('/patients', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

    const q = str(req.query.q);
    const limit = Math.min(toInt(req.query.limit, 20), 50);

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
 * ✅ Staff lookup (NOW supports departmentId + allows RECEPTION)
 * GET /api/lookups/staff?role=DOCTOR&departmentId=<uuid>&q=&limit=
 */
router.get('/staff', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

    const role = normalizeRole(req.query.role);
    if (!role) return next(new HttpError(400, 'role is required'));

    const departmentId = str(req.query.departmentId) || null; // ✅ NEW
    const q = str(req.query.q);
    const limit = Math.min(toInt(req.query.limit, 20), 50);

    // ✅ السماح: ADMIN / DOCTOR / RECEPTION
    // الاستقبال يحتاج يشوف أطباء الأقسام حتى يعيّن طبيب للمريض
    const rolesRaw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const roles = rolesRaw
      .map(r => (typeof r === 'string' ? r : r?.name))
      .filter(Boolean)
      .map(x => String(x).toUpperCase().trim());

    const canLookupStaff =
      roles.includes('ADMIN') || roles.includes('DOCTOR') || roles.includes('RECEPTION');

    if (!canLookupStaff) return next(new HttpError(403, 'Forbidden'));

    const params = [tenantId, role];
    let idx = params.length; // last used index

    let where = `
      u.tenant_id = $1
      AND u.is_active = true
      AND EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = u.id
          AND UPPER(r.name) = $2
          AND r.tenant_id = u.tenant_id
      )
    `;

    // ✅ filter by department
    if (departmentId) {
      params.push(departmentId);
      idx = params.length;
      where += ` AND u.department_id = $${idx}`;
    }

    // ✅ search filter
    if (q) {
      params.push(`%${q}%`);
      idx = params.length;
      const p = `$${idx}`;
      where += `
        AND (
          u.full_name ILIKE ${p}
          OR COALESCE(u.staff_code,'') ILIKE ${p}
          OR COALESCE(u.email,'') ILIKE ${p}
          OR COALESCE(u.phone,'') ILIKE ${p}
        )
      `;
    }

    params.push(limit);
    const limitP = `$${params.length}`;

    const sql = `
      SELECT
        u.id,
        u.full_name AS "fullName",
        u.staff_code AS "staffCode",
        u.email,
        u.phone,
        u.department_id AS "departmentId"
      FROM users u
      WHERE ${where}
      ORDER BY u.full_name ASC
      LIMIT ${limitP}
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
      departmentId: x.departmentId,
    }));

    return res.json({ ok: true, items });
  } catch (err) {
    next(err);
  }
});

/**
 * ✅ Departments lookup
 * GET /api/lookups/departments?q=&limit=
 * - For dropdowns (doctor/nurse department selection)
 */
router.get('/departments', requireAuth, async (req, res, next) => {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

    const q = str(req.query.q);
    const limit = Math.min(toInt(req.query.limit, 100), 200);

    const params = [tenantId];
    let where = `WHERE tenant_id = $1 AND is_active = true`;

    if (q) {
      params.push(`%${q}%`);
      const p = `$${params.length}`;
      where += ` AND (name ILIKE ${p} OR code ILIKE ${p})`;
    }

    params.push(limit);

    const { rows } = await pool.query(
      `
      SELECT id, code, name
      FROM departments
      ${where}
      ORDER BY name ASC
      LIMIT $${params.length}
      `,
      params
    );

    const items = rows.map(d => ({
      id: d.id,
      code: d.code,
      name: d.name,
      label: d.name,
    }));

    return res.json({ ok: true, items });
  } catch (e) {
    return next(e);
  }
});

const systemDepartmentsRoutes = require('./lookups.system.routes');
router.use(systemDepartmentsRoutes);

module.exports = router;
