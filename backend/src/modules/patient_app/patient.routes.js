const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requirePatientMembership } = require('../../middlewares/requirePatientMembership');

const ctrl = require('./patient.controller');

const router = express.Router();

// ✅ المريض يشوف أدوية منشأة معينة
router.get(
  '/tenants/:tenantId/medications',
  requireAuth,                 // JWT للمريض
  requirePatientMembership,    // يطلع tenantPatientId
  ctrl.listMyMedications
);

module.exports = router;
