// src/modules/users/users.routes.js
const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const usersController = require('./users.controller');
const { createUserSchema, setActiveSchema } = require('./users.validators');

// NEW
const { adminResetPasswordSchema } = require('./users.password.validators');

// ADMIN only
router.get('/', requireAuth, requireRole('ADMIN'), usersController.listUsers);
router.post('/', requireAuth, requireRole('ADMIN'), validateBody(createUserSchema), usersController.createUser);
router.patch('/:id/active', requireAuth, requireRole('ADMIN'), validateBody(setActiveSchema), usersController.setActive);

// NEW: reset password for a staff member
router.post(
  '/:id/reset-password',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(adminResetPasswordSchema),
  usersController.resetPassword
);

module.exports = router;
