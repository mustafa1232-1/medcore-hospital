// src/modules/auth/auth.routes.js
const express = require('express');
const router = express.Router();

const authController = require('./auth.controller');
const { validateBody } = require('../../middlewares/validate');
const { requireAuth } = require('../../middlewares/auth'); // NEW

const {
  registerTenantSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  changePasswordSchema, // NEW
} = require('./auth.validators');

router.post('/register-tenant', validateBody(registerTenantSchema), authController.registerTenant);
router.post('/login', validateBody(loginSchema), authController.login);
router.post('/refresh', validateBody(refreshSchema), authController.refresh);
router.post('/logout', validateBody(logoutSchema), authController.logout);

// NEW: change password (logged-in)
router.post('/change-password', requireAuth, validateBody(changePasswordSchema), authController.changePassword);

module.exports = router;
