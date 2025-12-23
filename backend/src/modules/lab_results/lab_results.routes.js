const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');
const { HttpError } = require('../../utils/httpError');

const ctrl = require('./lab_results.controller');
const { createLabResultSchema, listLabResultsQuerySchema } = require('./lab_results.validators');

const router = express.Router();

/**
 * Policy:
 * - LAB/ADMIN: create result
 * - DOCTOR/NURSE/LAB/ADMIN: view
 */

const VIEW_ROLES = ['DOCTOR', 'NURSE', 'LAB', 'ADMIN'];

router.get(
  '/',
  requireAuth,
  requireRole(...VIEW_ROLES),
  async (req, _res, next) => {
    const { error, value } = listLabResultsQuerySchema.validate(req.query, {
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
  requireRole('LAB', 'ADMIN'),
  validateBody(createLabResultSchema),
  ctrl.create
);

module.exports = router;
