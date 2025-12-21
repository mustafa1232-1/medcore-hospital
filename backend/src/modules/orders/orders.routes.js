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
 * Create orders: DOCTOR (أو ADMIN لاحقًا)
 * List/get/cancel: ADMIN (أو توسعة لاحقًا)
 */

// List
router.get(
  '/',
  requireAuth,
  requireRole('ADMIN'),
  async (req, _res, next) => {
    // validate query manually using Joi (لأن validateBody خاص بالـ body)
    const { error, value } = listOrdersQuerySchema.validate(req.query, { abortEarly: false, stripUnknown: true });
    if (error) return next(new (require('../../utils/httpError').HttpError)(400, 'Validation error', error.details.map(d => d.message)));
    req.query = value;
    return next();
  },
  ctrl.list
);

router.get(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
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
router.post(
  '/:id/cancel',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(cancelOrderSchema),
  ctrl.cancel
);

module.exports = router;
