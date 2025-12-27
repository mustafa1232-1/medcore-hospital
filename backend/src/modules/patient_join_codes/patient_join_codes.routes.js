// src/modules/patient_join_codes/patient_join_codes.routes.js
const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');

const ctrl = require('./patient_join_codes.controller');

const router = express.Router();

// Reception/Admin creates a facility join code (no params, tenant from JWT)
router.post(
  '/',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  ctrl.create
);

module.exports = router;
