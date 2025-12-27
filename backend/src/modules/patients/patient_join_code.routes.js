// src/modules/patients/patient_join_code.routes.js
const express = require('express');

// TODO: ضع هنا ميدلوير الستاف عندك
// const { requireAuth } = require('../../middlewares/auth');
const jwt = require('jsonwebtoken');

const ctrl = require('./patient_join_code.controller');

const router = express.Router();

// Staff issues join code for a specific patient in a facility
router.post(
  '/tenants/:tenantId/patients/:patientId/issue-join-code',
  // requireAuth,
  // requireTenantAccess,
  ctrl.issue
);

// Staff revokes join code
router.post(
  '/tenants/:tenantId/patients/:patientId/revoke-join-code',
  // requireAuth,
  // requireTenantAccess,
  ctrl.revoke
);

module.exports = router;
