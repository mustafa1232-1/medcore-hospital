const express = require('express');
const { requirePatientAuth } = require('../../../middlewares/patientAuth');

const ctrl = require('./patient_memberships.controller');

const router = express.Router();

// Patient reads their memberships (after approval)
router.get('/memberships', requirePatientAuth, ctrl.listMyMemberships);

// Patient reads their join requests (pending/approved/rejected)
router.get('/join-requests', requirePatientAuth, ctrl.listMyJoinRequests);

module.exports = router;
