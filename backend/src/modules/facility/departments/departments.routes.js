// src/modules/facility/departments/departments.routes.js
const express = require('express');
const { requireAuth } = require('../../../middlewares/auth');
const { requirePermission } = require('../../../utils/requirePermission');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./departments.controller');
const {
  createDepartmentSchema,
  updateDepartmentSchema,
  activateDepartmentSchema,

  // ✅ NEW
  transferStaffSchema,
  removeStaffSchema,
} = require('./departments.validators');

const router = express.Router();

// =========================
// Read
// =========================
router.get('/', requireAuth, requirePermission('facility.read'), ctrl.list);

// ✅ Department Overview (staff + rooms + beds + occupancy)
router.get(
  '/:id/overview',
  requireAuth,
  requirePermission('facility.read'),
  ctrl.overview
);

router.get('/:id', requireAuth, requirePermission('facility.read'), ctrl.getOne);

// =========================
// ✅ NEW: Staff management inside department
// - ADMIN: can transfer/remove anyone
// - DOCTOR: can transfer/remove NURSE only, cannot change self, cannot move doctors
// =========================
router.post(
  '/:id/staff/transfer',
  requireAuth,
  requirePermission('facility.write'),
  validateBody(transferStaffSchema),
  ctrl.transferStaff
);

router.post(
  '/:id/staff/remove',
  requireAuth,
  requirePermission('facility.write'),
  validateBody(removeStaffSchema),
  ctrl.removeStaff
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
