// src/modules/lookups/lookups.routes.js
const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { HttpError } = require('../../utils/httpError');

const pool = require('../../db/pool');

const router = express.Router();

function normalizeRole(x) {
  return String(x || '').toUpperCase().trim();
}

function roleNameOf(r) {
  if (!r) return '';
  if (typeof r === 'string') return r;
  if (typeof r === 'object' && r.name) return String(r.name);
  if (typeof r === 'object' && r.code) return String(r.code);
  return '';
}

function requireAnyRole(roles) {
  const needed = (Array.isArray(roles) ? roles : [roles])
    .map(normalizeRole)
    .filter(Boolean);

  return (req, _res, next) => {
    const raw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const have = raw.map(roleNameOf).map(normalizeRole).filter(Boolean);

    const ok = needed.some(r => have.includes(r));
    if (!ok) return next(new HttpError(403, 'Forbidden'));
    return next();
  };
}

// ✅ حسب طلبك: ADMIN يشوف كل شيء + DOCTOR يحتاجهم لإنشاء الأوامر
const LOOKUP_ROLES = ['ADMIN', 'DOCTOR'];

/**
 * GET /api/lookups/patients?q=&limit=
 * returns: { items: [{id, label, fullName, phone}] }
 */
router.get(
  '/patients',
  requireAuth,
  requireAnyRole(LOOKUP_ROLES),
  async (req, res, next) => {
    try {
      const tenantId = req.user?.tenantId;
      if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

      const q = String(req.query.q || '').trim();
      const limit = Math.min(parseInt(String(req.query.limit || '20'), 10) || 20, 50);

      // ✅ ملاحظة: نعتمد على جدول patients الموجود عندك من migration 004_patients_admissions.sql
      // إذا أسماء الأعمدة تختلف عندك، أخبرني وسأطابقها 1:1
      const sql = `
        SELECT
          p.id,
          COALESCE(p.full_name, p.name, '') AS "fullName",
          COALESCE(p.phone, '') AS "phone"
        FROM patients p
        WHERE p.tenant_id = $1
          AND (
            $2 = '' OR
            COALESCE(p.full_name, p.name, '') ILIKE '%' || $2 || '%' OR
            COALESCE(p.phone, '') ILIKE '%' || $2 || '%'
          )
        ORDER BY COALESCE(p.full_name, p.name, '') ASC
        LIMIT $3
      `;

      const r = await pool.query(sql, [tenantId, q, limit]);

      const items = r.rows.map(x => {
        const fullName = String(x.fullName || '').trim();
        const phone = String(x.phone || '').trim();
        const label = [fullName, phone ? `• ${phone}` : ''].join(' ').trim();

        return {
          id: x.id,
          label,
          fullName,
          phone,
        };
      });

      return res.json({ ok: true, items });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /api/lookups/staff?role=NURSE&q=&limit=
 * returns: { items: [{id, label, fullName, staffCode}] }
 */
router.get(
  '/staff',
  requireAuth,
  requireAnyRole(LOOKUP_ROLES),
  async (req, res, next) => {
    try {
      const tenantId = req.user?.tenantId;
      if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

      const role = normalizeRole(req.query.role);
      const q = String(req.query.q || '').trim();
      const limit = Math.min(parseInt(String(req.query.limit || '20'), 10) || 20, 50);

      if (!role) return next(new HttpError(400, 'Validation error', ['role is required']));

      // ✅ يفترض عندك users + user_roles + roles (من migrations السابقة)
      // فلترة الدور تتم عبر EXISTS (أفضل من JOIN لأن user ممكن عنده أكثر من role)
      const sql = `
        SELECT
          u.id,
          u.full_name AS "fullName",
          u.staff_code AS "staffCode",
          u.email,
          u.phone
        FROM users u
        WHERE u.tenant_id = $1
          AND u.is_active = TRUE
          AND (
            $2 = '' OR
            u.full_name ILIKE '%' || $2 || '%' OR
            COALESCE(u.email, '') ILIKE '%' || $2 || '%' OR
            COALESCE(u.phone, '') ILIKE '%' || $2 || '%'
          )
          AND EXISTS (
            SELECT 1
            FROM user_roles ur
            JOIN roles r ON r.id = ur.role_id
            WHERE ur.user_id = u.id
              AND UPPER(r.name) = $3
          )
        ORDER BY u.full_name ASC
        LIMIT $4
      `;

      const r = await pool.query(sql, [tenantId, q, role, limit]);

      const items = r.rows.map(x => {
        const fullName = String(x.fullName || '').trim();
        const staffCode = String(x.staffCode || '').trim();
        const label = [fullName, staffCode ? `• ${staffCode}` : ''].join(' ').trim();

        return {
          id: x.id,
          label,
          fullName,
          staffCode,
        };
      });

      return res.json({ ok: true, items });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
