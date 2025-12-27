const express = require('express');
const { requirePatientAuth } = require('../../../middlewares/patientAuth');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./patient_profile.controller');
const { patchProfileSchema } = require('./patient_profile.validators');

const router = express.Router();

// Patient self profile
router.get('/profile', requirePatientAuth, ctrl.getMyProfile);
router.patch('/profile', requirePatientAuth, validateBody(patchProfileSchema), ctrl.patchMyProfile);

module.exports = router;
