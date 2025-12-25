const express = require('express');
const { requirePatientAuth } = require('../../middlewares/patientAuth');

const ctrl = require('./patient_join.controller');

const router = express.Router();

// Patient joins a facility using QR payload (AUTO APPROVE)
router.post('/join', requirePatientAuth, ctrl.join);

// Patient leaves a facility (no data deletion)
router.post('/tenants/:tenantId/leave', requirePatientAuth, ctrl.leave);

module.exports = router;
