// src/modules/patients/patients.routes.js
const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const patientsController = require('./patients.controller');
const {
  createPatientSchema,
  updatePatientSchema,
} = require('./patients.validators');

/**
 * Roles:
 * - RECEPTION: create + list + view
 * - DOCTOR: list + view
 * - ADMIN: full access
 */

// List patients (search by name / phone)
router.get(
  '/',
  requireAuth,
  requireRole('RECEPTION'),
  patientsController.listPatients
);

// Create patient (Reception/Admin)
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION'),
  validateBody(createPatientSchema),
  patientsController.createPatient
);

// Get single patient
router.get(
  '/:id',
  requireAuth,
  requireRole('RECEPTION'),
  patientsController.getPatientById
);

// Update patient basic info
router.patch(
  '/:id',
  requireAuth,
  requireRole('RECEPTION'),
  validateBody(updatePatientSchema),
  patientsController.updatePatient
);

module.exports = router;
