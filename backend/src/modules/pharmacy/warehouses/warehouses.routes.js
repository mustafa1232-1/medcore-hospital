const express = require('express');

const { requireAuth } = require('../../../middlewares/auth');
const { requireRole } = require('../../../middlewares/roles');
const { validateBody } = require('../../../middlewares/validate');
const { HttpError } = require('../../../utils/httpError');

const ctrl = require('./warehouses.controller');
const {
  listWarehousesQuerySchema,
  createWarehouseSchema,
  updateWarehouseSchema,
} = require('./warehouses.validators');

const router = express.Router();

/**
 * Policy:
 * - VIEW: PHARMACY + ADMIN
 * - WRITE: ADMIN only
 */

function validateQuery(schema) {
  return (req, _res, next) => {
    const { error, value } = schema.validate(req.query, {
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
  };
}

router.get(
  '/',
  requireAuth,
  requireRole('PHARMACY', 'ADMIN'),
  validateQuery(listWarehousesQuerySchema),
  ctrl.list
);

router.get(
  '/:id',
  requireAuth,
  requireRole('PHARMACY', 'ADMIN'),
  ctrl.getOne
);

router.post(
  '/',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(createWarehouseSchema),
  ctrl.create
);

router.patch(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(updateWarehouseSchema),
  ctrl.update
);

// Soft delete (disable)
router.delete(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
  ctrl.remove
);

module.exports = router;
