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

// ✅ NEW: Patient Medical Record (History + Logs + Files + Admissions + Bed timeline)
router.get(
  '/:id/medical-record',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientMedicalRecord
);

// ✅ NEW: Health advice by current department (based on active admission bed)
router.get(
  '/:id/health-advice',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientHealthAdvice
);

/**
 * ✅ NEW: Patient linking (QR/Join Code) + cross-facility history
 *
 * - join-code: Reception/Admin يولدون كود انضمام للمريض داخل نفس الـ tenant
 * - external-history: Reception/Admin/Doctor يشوفون المنشآت الأخرى المرتبطة بحساب المريض (إن كان مرتبط)
 */

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

module.exports = router;
