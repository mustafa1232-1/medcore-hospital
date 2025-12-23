const express = require('express');

const { requireAuth } = require('../../../middlewares/auth');
const { requireRole } = require('../../../middlewares/roles');
const { validateBody } = require('../../../middlewares/validate');
const { HttpError } = require('../../../utils/httpError');

const ctrl = require('./drugs.controller');
const { listDrugQuerySchema, createDrugSchema, updateDrugSchema } = require('./drugs.validators');

const router = express.Router();

/**
 * Policy:
 * - VIEW: DOCTOR + NURSE + PHARMACY + ADMIN
 * - WRITE: PHARMACY + ADMIN
 */

const VIEW_ROLES = ['DOCTOR', 'NURSE', 'PHARMACY', 'ADMIN'];
const WRITE_ROLES = ['PHARMACY', 'ADMIN'];

router.get(
  '/',
  requireAuth,
  requireRole(...VIEW_ROLES),
  async (req, _res, next) => {
    const { error, value } = listDrugQuerySchema.validate(req.query, {
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

router.get(
  '/:id',
  requireAuth,
  requireRole(...VIEW_ROLES),
  ctrl.getOne
);

router.post(
  '/',
  requireAuth,
  requireRole(...WRITE_ROLES),
  validateBody(createDrugSchema),
  ctrl.create
);

router.patch(
  '/:id',
  requireAuth,
  requireRole(...WRITE_ROLES),
  validateBody(updateDrugSchema),
  ctrl.update
);

router.delete(
  '/:id',
  requireAuth,
  requireRole(...WRITE_ROLES),
  ctrl.remove
);

module.exports = router;
