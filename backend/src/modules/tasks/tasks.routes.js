const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const ctrl = require('./tasks.controller');
const { completeTaskSchema } = require('./tasks.validators');

const router = express.Router();

// Nurse sees their tasks (assigned to them or unassigned)
router.get(
  '/my',
  requireAuth,
  requireRole('NURSE'),
  ctrl.listMy
);

router.post(
  '/:id/start',
  requireAuth,
  requireRole('NURSE'),
  ctrl.start
);

router.post(
  '/:id/complete',
  requireAuth,
  requireRole('NURSE'),
  validateBody(completeTaskSchema),
  ctrl.complete
);

module.exports = router;
