const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');
const { HttpError } = require('../../utils/httpError');

const ctrl = require('./med_admin.controller');
const { createMedAdminSchema, listMedAdminsQuerySchema } = require('./med_admin.validators');

const router = express.Router();

/**
 * Policy:
 * - NURSE/PHARMACY/ADMIN: create medication administration
 * - DOCTOR/NURSE/PHARMACY/ADMIN: view
 */

const VIEW_ROLES = ['DOCTOR', 'NURSE', 'PHARMACY', 'ADMIN'];

router.get(
  '/',
  requireAuth,
  requireRole(...VIEW_ROLES),
  async (req, _res, next) => {
    const { error, value } = listMedAdminsQuerySchema.validate(req.query, {
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
  requireRole('NURSE', 'PHARMACY', 'ADMIN'),
  validateBody(createMedAdminSchema),
  ctrl.create
);

module.exports = router;
