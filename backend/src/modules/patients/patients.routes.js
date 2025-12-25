// src/modules/patients/patients.routes.js
const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const patientsController = require('./patients.controller');
const { createPatientSchema, updatePatientSchema } = require('./patients.validators');

// ✅ NEW: Join code + external history (cross-facility)
const patientLinkController = require('./patient_link.controller');

/**
 * Roles:
 * - RECEPTION: create + update + list + view + medical record
 * - DOCTOR: list + view + medical record + advice
 * - ADMIN: full access
 */

// ✅ UUID regex to prevent route shadowing (e.g. /assigned becomes NOT a patientId)
const UUID_RE = '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})';

/**
 * ✅ IMPORTANT:
 * Put fixed/static routes BEFORE "/:id"
 */

// ✅ Doctor: list assigned patients
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

// ✅ NEW: Patient Medical Record (History + Logs + Files + Admissions + Bed timeline)
router.get(
  `/:id${UUID_RE}/medical-record`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientMedicalRecord
);

// ✅ NEW: Health advice by current department (based on active admission bed)
router.get(
  `/:id${UUID_RE}/health-advice`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientHealthAdvice
);

/**
 * ✅ NEW: Patient linking (QR/Join Code) + cross-facility history
 */

// Generate join code for a patient (Reception/Admin only)
router.post(
  `/:id${UUID_RE}/join-code`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  patientLinkController.issueJoinCode
);

// View external history across facilities (Reception/Admin/Doctor)
router.get(
  `/:id${UUID_RE}/external-history`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientLinkController.externalHistory
);

// Get single patient
router.get(
  `/:id${UUID_RE}`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientById
);

// Update patient basic info (Reception/Admin فقط)
router.patch(
  `/:id${UUID_RE}`,
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(updatePatientSchema),
  patientsController.updatePatient
);

module.exports = router;
