const express = require('express');
const { validateBody } = require('../../middlewares/validate');
const { requirePatientAuth } = require('../../middlewares/patientAuth');

const ctrl = require('./patientAuth.controller');
const { registerSchema, loginSchema } = require('./patientAuth.validators');

const router = express.Router();

router.post('/register', validateBody(registerSchema), ctrl.register);
router.post('/login', validateBody(loginSchema), ctrl.login);
router.get('/me', requirePatientAuth, ctrl.me);

module.exports = router;
