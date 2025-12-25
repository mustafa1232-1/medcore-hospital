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

// ✅ Join code + external history (cross-facility)
const patientLinkController = require('./patient_link.controller');

/**
 * Roles:
 * - RECEPTION: create + update + list + view + medical record
 * - DOCTOR: list + view + medical record + advice + assigned
 * - ADMIN: full access
 */

// ✅ Doctor: Assigned patients
// IMPORTANT: must be BEFORE "/:id" routes to avoid treating "assigned" as :id
router.get(
  '/assigned',
  requireAuth,
  requireRole('DOCTOR', 'ADMIN'),
  patientsController.listAssignedPatients
);

// List patients
router.get(
  '/',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.listPatients
);

// Create patient (Reception/Admin فقط)
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(createPatientSchema),
  patientsController.createPatient
);

// ✅ Medical record (must be before "/:id")
router.get(
  '/:id/medical-record',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientMedicalRecord
);

// ✅ Health advice (must be before "/:id")
router.get(
  '/:id/health-advice',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientHealthAdvice
);

// Generate join code for a patient (Reception/Admin only)
router.post(
  '/:id/join-code',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  patientLinkController.issueJoinCode
);

// View external history across facilities (Reception/Admin/Doctor)
router.get(
  '/:id/external-history',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientLinkController.externalHistory
);

// Get single patient
router.get(
  '/:id',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientById
);

// Update patient basic info (Reception/Admin فقط)
router.patch(
  '/:id',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(updatePatientSchema),
  patientsController.updatePatient
);

module.exports = router;
