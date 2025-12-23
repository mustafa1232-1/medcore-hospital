const express = require('express');

const { requireAuth } = require('../../../middlewares/auth');
const { requireRole } = require('../../../middlewares/roles');
const { validateBody } = require('../../../middlewares/validate');
const { HttpError } = require('../../../utils/httpError');

const ctrl = require('./stockRequests.controller');
const {
  createRequestSchema,
  addLineSchema,
  updateLineSchema,
  listRequestsQuerySchema,
  submitSchema,
  approveSchema,
  rejectSchema,
  // cancelSchema, // (اختياري إذا فعلنا cancel)
} = require('./stockRequests.validators');

const router = express.Router();

/**
 * Policy (strict):
 * - PHARMACY: create + edit draft + submit + view
 * - ADMIN: view + approve/reject
 */

// List
router.get(
  '/',
  requireAuth,
  requireRole('PHARMACY', 'ADMIN'),
  async (req, _res, next) => {
    const { error, value } = listRequestsQuerySchema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });
    if (error) {
      return next(
        new HttpError(
          400,
          'Validation error',
          error.details.map((d) => d.message)
        )
      );
    }
    req.query = value;
    return next();
  },
  ctrl.list
);

// Details
router.get('/:id', requireAuth, requireRole('PHARMACY', 'ADMIN'), ctrl.getOne);

// Create request (PHARMACY فقط)
router.post(
  '/',
  requireAuth,
  requireRole('PHARMACY'),
  validateBody(createRequestSchema),
  ctrl.create
);

// Lines (draft only) - PHARMACY فقط
router.post(
  '/:id/lines',
  requireAuth,
  requireRole('PHARMACY'),
  validateBody(addLineSchema),
  ctrl.addLine
);

router.patch(
  '/:id/lines/:lineId',
  requireAuth,
  requireRole('PHARMACY'),
  validateBody(updateLineSchema),
  ctrl.updateLine
);

router.delete(
  '/:id/lines/:lineId',
  requireAuth,
  requireRole('PHARMACY'),
  ctrl.removeLine
);

// Submit (PHARMACY فقط)
router.post(
  '/:id/submit',
  requireAuth,
  requireRole('PHARMACY'),
  validateBody(submitSchema),
  ctrl.submit
);

// Approve/Reject (ADMIN فقط)
router.post(
  '/:id/approve',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(approveSchema),
  ctrl.approve
);

router.post(
  '/:id/reject',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(rejectSchema),
  ctrl.reject
);

module.exports = router;
