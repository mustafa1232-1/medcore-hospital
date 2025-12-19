const express = require('express');
const router = express.Router();

const controller = require('./auth.controller');

// عندك register-tenant موجود
router.post('/register-tenant', controller.registerTenant);

// login/refresh/logout
router.post('/login', controller.login);
router.post('/refresh', controller.refresh);
router.post('/logout', controller.logout);

module.exports = router;
