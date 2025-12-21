// src/modules/orders/orders.routes.js
const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');
const { requireActiveAdmissionBed } = require('../../middlewares/requireActiveAdmissionBed');
const { HttpError } = require('../../utils/httpError');

const ctrl = require('./orders.controller');
const {
  createMedicationOrderSchema,
  createLabOrderSchema,
  createProcedureOrderSchema,
  listOrdersQuerySchema,
  cancelOrderSchema,
} = require('./orders.validators');

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

/**
 * ✅ Policy:
 * - CREATE/CANCEL: DOCTOR فقط
 * - VIEW (List/Details): DOCTOR + NURSE + LAB + PHARMACY + ADMIN
 */

const ORDERS_VIEW_ROLES = ['DOCTOR', 'NURSE', 'LAB', 'PHARMACY', 'ADMIN'];

// List
router.get(
  '/',
  requireAuth,
  requireAnyRole(ORDERS_VIEW_ROLES),
  async (req, _res, next) => {
    const { error, value } = listOrdersQuerySchema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
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

// Details
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

// Cancel (DOCTOR فقط)
router.post(
  '/:id/cancel',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(cancelOrderSchema),
  ctrl.cancel
);

module.exports = router;
