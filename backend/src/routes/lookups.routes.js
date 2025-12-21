// src/routes/lookups.routes.js
const express = require('express');
const pool = require('../db/pool');

const { requireAuth } = require('../middlewares/auth');
const { HttpError } = require('../utils/httpError');

const router = express.Router();

// ✅ نفس requireAnyRole التي استخدمناها سابقاً (بدون لمس roles middleware)
function requireAnyRole(roles) {
  const needed = (Array.isArray(roles) ? roles : [roles])
    .map(r => String(r || '').toUpperCase().trim())
    .filter(Boolean);

  return (req, _res, next) => {
    const rolesRaw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const normalized = rolesRaw
      .map(r => (typeof r === 'string' ? r : r?.name))
      .filter(Boolean)
      .map(x => String(x).toUpperCase().trim());

    const ok = needed.some(r => normalized.includes(r));
    if (!ok) return next(new HttpError(403, 'Forbidden'));
    return next();
  };
}

/**
 * ✅ Patients lookup
 * GET /api/lookups/patients?q=...
 * Roles: DOCTOR, NURSE, LAB, PHARMACY
 */
router.get(
  '/patients',
  requireAuth,
  requireAnyRole(['DOCTOR', 'NURSE', 'LAB', 'PHARMACY']),
  async (req, res, next) => {
    try {
      const tenantId = req.user?.tenantId;
      if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

      const q = String(req.query.q || '').trim();
      const limit = Math.min(parseInt(req.query.limit || '20', 10) || 20, 50);

      // ✅ يرجّع قائمة مختصرة + محاولة جلب آخر admission (اختياري حسب جداولك)
      // ملاحظة: إذا ما عندك admissions/rooms/beds بهذا الشكل، عدّل الجزء الخاص بها فقط.
      const sql = `
        SELECT
          p.id,
          p.full_name AS "fullName",
          p.phone,
          COALESCE(a.code, '') AS "admissionCode",
          COALESCE(r.code, '') AS "roomCode",
          COALESCE(b.code, '') AS "bedCode"
        FROM patients p
        LEFT JOIN admissions a
          ON a.patient_id = p.id
         AND a.tenant_id = p.tenant_id
         AND a.status = 'ACTIVE'
        LEFT JOIN rooms r ON r.id = a.room_id
        LEFT JOIN beds  b ON b.id = a.bed_id
        WHERE p.tenant_id = $1
          AND (
            $2 = '' OR
            p.full_name ILIKE '%' || $2 || '%' OR
            COALESCE(p.phone, '') ILIKE '%' || $2 || '%'
          )
        ORDER BY p.full_name ASC
        LIMIT $3
      `;

      const result = await pool.query(sql, [tenantId, q, limit]);

      return res.json({
        ok: true,
        items: result.rows.map(x => ({
          id: x.id,
          fullName: x.fullName,
          phone: x.phone,
          admissionCode: x.admissionCode,
          roomCode: x.roomCode,
          bedCode: x.bedCode,
          label: [
            x.fullName,
            x.phone ? `(${x.phone})` : null,
            (x.roomCode || x.bedCode) ? `${x.roomCode} / ${x.bedCode}` : null,
          ].filter(Boolean).join(' '),
        })),
      });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * ✅ Staff lookup
 * GET /api/lookups/staff?role=NURSE&q=...
 * Roles: DOCTOR (اختيار المستلم)
 */
router.get(
  '/staff',
  requireAuth,
  requireAnyRole(['DOCTOR']),
  async (req, res, next) => {
    try {
      const tenantId = req.user?.tenantId;
      if (!tenantId) return next(new HttpError(401, 'Unauthorized: invalid payload'));

      const role = String(req.query.role || '').toUpperCase().trim(); // NURSE/LAB/PHARMACY
      const q = String(req.query.q || '').trim();
      const limit = Math.min(parseInt(req.query.limit || '20', 10) || 20, 50);

      if (!['NURSE', 'LAB', 'PHARMACY'].includes(role)) {
        return next(new HttpError(400, 'Validation error', ['role must be NURSE, LAB, or PHARMACY']));
      }

      // ✅ يعتمد على أن users.roles مخزنة كمصفوفة (أو JSON) — إذا عندك جدول user_roles عدّله
      // هنا نفترض roles مخزنة كـ jsonb array من strings أو objects {name}
      const sql = `
        SELECT
          u.id,
          u.full_name AS "fullName",
          u.staff_code AS "staffCode",
          u.email,
          u.phone
        FROM users u
        WHERE u.tenant_id = $1
          AND u.is_active = true
          AND (
            -- roles ممكن تكون ['NURSE'] أو [{name:'NURSE'}]
            EXISTS (
              SELECT 1
              FROM jsonb_array_elements(COALESCE(u.roles, '[]'::jsonb)) el
              WHERE
                (jsonb_typeof(el) = 'string' AND UPPER(el::text) = '"' || $2 || '"')
                OR (jsonb_typeof(el) = 'object' AND UPPER(COALESCE(el->>'name','')) = $2)
            )
          )
          AND (
            $3 = '' OR
            u.full_name ILIKE '%' || $3 || '%' OR
            COALESCE(u.staff_code,'') ILIKE '%' || $3 || '%' OR
            COALESCE(u.phone,'') ILIKE '%' || $3 || '%'
          )
        ORDER BY u.full_name ASC
        LIMIT $4
      `;

      const result = await pool.query(sql, [tenantId, role, q, limit]);

      return res.json({
        ok: true,
        items: result.rows.map(x => ({
          id: x.id,
          fullName: x.fullName,
          staffCode: x.staffCode,
          phone: x.phone,
          label: [
            x.fullName,
            x.staffCode ? `(${x.staffCode})` : null,
            x.phone ? `- ${x.phone}` : null,
          ].filter(Boolean).join(' '),
        })),
      });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
