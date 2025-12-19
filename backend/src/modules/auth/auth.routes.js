// src/modules/auth/auth.routes.js
const express = require('express');
const router = express.Router();

const authController = require('./auth.controller');
const { validateBody } = require('../../middlewares/validate');
const {
  registerTenantSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
} = require('./auth.validators');

// مهم: كل وسيط هنا لازم يكون function
router.post('/register-tenant', validateBody(registerTenantSchema), authController.registerTenant);
router.post('/login', validateBody(loginSchema), authController.login);
router.post('/refresh', validateBody(refreshSchema), authController.refresh);
router.post('/logout', validateBody(logoutSchema), authController.logout);

module.exports = router;
