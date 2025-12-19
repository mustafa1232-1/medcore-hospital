const express = require('express');
const router = express.Router();

const controller = require('./auth.controller');

router.post('/register-tenant', controller.registerTenant);
router.post('/login', controller.login);
router.post('/refresh', controller.refresh);
router.post('/logout', controller.logout);

module.exports = router;
console.log('auth controller keys:', Object.keys(controller));