const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth'); // إذا عندك JWT للمريض مختلف، بدّله
const { requirePatientMembership } = require('../../middlewares/requirePatientMembership');

const ctrl = require('./patientMedications.controller');

// path: /api/patient/:tenantId/medications
router.get(
  '/:tenantId/medications',
  requireAuth,
  requirePatientMembership,
  ctrl.listMyMedications
);

module.exports = router;
