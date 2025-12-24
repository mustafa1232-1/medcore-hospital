const express = require('express');
const { requirePatientAuth } = require('../../middlewares/patientAuth');
const { requirePatientMembership } = require('../../middlewares/requirePatientMembership');

const ctrl = require('./patient.controller');

const router = express.Router();

router.get(
  '/tenants/:tenantId/medications',
  requirePatientAuth,
  requirePatientMembership,
  ctrl.listMyMedications
);

module.exports = router;
