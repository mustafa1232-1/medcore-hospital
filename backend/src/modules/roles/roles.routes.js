// src/modules/roles/roles.routes.js
const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth');
const rolesController = require('./roles.controller');

// GET /api/roles
router.get('/', requireAuth, rolesController.listRoles);

module.exports = router;
