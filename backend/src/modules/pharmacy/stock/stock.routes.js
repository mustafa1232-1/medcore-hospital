// src/modules/pharmacy/stock/stock.routes.js
const express = require('express');

const { requireAuth } = require('../../../middlewares/auth');
const { requireRole } = require('../../../middlewares/roles');
const { HttpError } = require('../../../utils/httpError');

const ctrl = require('./stock.controller');
const { balanceQuerySchema, ledgerQuerySchema } = require('./stock.validators');

const router = express.Router();

/**
 * Policy:
 * - PHARMACY + ADMIN can view stock
 * - (Optional) DOCTOR can view only DISPENSE ledger for a patient later (we can add later)
 */
router.get(
  '/balance',
  requireAuth,
  requireRole('PHARMACY', 'ADMIN'),
  (req, _res, next) => {
    const { error, value } = balanceQuerySchema.validate(req.query, {
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
  ctrl.balance
);

router.get(
  '/ledger',
  requireAuth,
  requireRole('PHARMACY', 'ADMIN'),
  (req, _res, next) => {
    const { error, value } = ledgerQuerySchema.validate(req.query, {
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
  ctrl.ledger
);

module.exports = router;
