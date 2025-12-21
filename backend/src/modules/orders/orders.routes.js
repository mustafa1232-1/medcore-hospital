// src/modules/orders/orders.routes.js
const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');
const { requireActiveAdmissionBed } = require('../../middlewares/requireActiveAdmissionBed');

const ctrl = require('./orders.controller');
const {
  createMedicationOrderSchema,
  createLabOrderSchema,
  createProcedureOrderSchema,
  listOrdersQuerySchema,
  cancelOrderSchema,
} = require('./orders.validators');

const router = express.Router();

/**
 * ✅ Policy (حسب طلبك):
 * - ADMIN لا يملك صلاحيات الأوامر
 * - DOCTOR ينشئ + يقدر يشوف (dashboard/details) + يقدر يلغي (إن رغبت)
 * - NURSE/LAB/PHARMACY يشوفون (dashboard/details) فقط
 *
 * ملاحظة: لم نغيّر أي Controller أو Validator أو منطق requireActiveAdmissionBed
 */

// ✅ Helper محلي: يسمح لأي دور ضمن قائمة
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
    if (!ok) {
      const { HttpError } = require('../../utils/httpError');
      return next(new HttpError(403, 'Forbidden'));
    }
    return next();
  };
}

// ✅ الأدوار التي يسمح لها بالعرض (List/Details)
const ORDERS_VIEW_ROLES = ['DOCTOR', 'NURSE', 'LAB', 'PHARMACY'];

// List
router.get(
  '/',
  requireAuth,
  requireAnyRole(ORDERS_VIEW_ROLES),
  async (req, _res, next) => {
    // validate query manually using Joi (لأن validateBody خاص بالـ body)
    const { error, value } = listOrdersQuerySchema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const { HttpError } = require('../../utils/httpError');
      return next(
        new HttpError(
          400,
          'Validation error',
          error.details.map(d => d.message)
        )
      );
    }

    req.query = value;
    return next();
  },
  ctrl.list
);

router.get(
  '/:id',
  requireAuth,
  requireAnyRole(ORDERS_VIEW_ROLES),
  ctrl.getOne
);

// Create Medication
router.post(
  '/medication',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(createMedicationOrderSchema),
  requireActiveAdmissionBed('admissionId'),
  ctrl.createMedication
);

// Create Lab
router.post(
  '/lab',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(createLabOrderSchema),
  requireActiveAdmissionBed('admissionId'),
  ctrl.createLab
);

// Create Procedure
router.post(
  '/procedure',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(createProcedureOrderSchema),
  requireActiveAdmissionBed('admissionId'),
  ctrl.createProcedure
);

// Cancel
// ✅ حسب طلبك: لا ADMIN. خليها DOCTOR فقط.
// (إذا لاحقاً تريد السماح للمستلم NURSE/LAB/PHARMACY بإلغاء/رفض، نضيف endpoint منفصل أو نوسعها هنا.)
router.post(
  '/:id/cancel',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(cancelOrderSchema),
  ctrl.cancel
);

module.exports = router;
