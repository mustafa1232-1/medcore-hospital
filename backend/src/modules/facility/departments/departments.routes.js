const express = require('express');
const { requireAuth } = require('../../../middlewares/auth');
const { requirePermission } = require('../../../utils/requirePermission');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./departments.controller');
const {
  createDepartmentSchema,
  updateDepartmentSchema,
  activateDepartmentSchema,
} = require('./departments.validators');

const router = express.Router();

// =========================
// Read
// =========================
router.get(
  '/',
  requireAuth,
  requirePermission('facility.read'),
  ctrl.list
);

router.get(
  '/:id',
  requireAuth,
  requirePermission('facility.read'),
  ctrl.getOne
);

// =========================
// Create (manual – legacy / optional)
// =========================
router.post(
  '/',
  requireAuth,
  requirePermission('facility.write'),
  validateBody(createDepartmentSchema),
  ctrl.create
);

// =========================
// Activate from system catalog (PRIMARY)
// default:
// - roomsCount = 1
// - bedsPerRoom = 1
// user can change both freely
// =========================
router.post(
  '/activate',
  requireAuth,
  requirePermission('facility.write'),
  validateBody(activateDepartmentSchema),
  ctrl.activate
);

// =========================
// Update
// =========================
router.patch(
  '/:id',
  requireAuth,
  requirePermission('facility.write'),
  validateBody(updateDepartmentSchema),
  ctrl.update
);

// =========================
// Soft delete
// =========================
router.delete(
  '/:id',
  requireAuth,
  requirePermission('facility.write'),
  ctrl.remove
);

module.exports = router;
