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
 * - DOCTOR: list + view + medical record + advice + assigned patients
 * - ADMIN: full access
 */

// ✅ UUID guard to prevent "/assigned" or any other string from hitting "/:id"
const UUID_REGEX =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

router.param('id', (req, res, next, value) => {
  // Only validate if route actually has :id
  if (!UUID_REGEX.test(String(value || ''))) {
    return next(new (require('../../utils/httpError').HttpError)(400, 'Invalid patient id'));
  }
  return next();
});

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

// ✅ Patient Medical Record
router.get(
  '/:id/medical-record',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientMedicalRecord
);

// ✅ Health advice
router.get(
  '/:id/health-advice',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientHealthAdvice
);

// ✅ Patient linking (join code)
router.post(
  '/:id/join-code',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  patientLinkController.issueJoinCode
);

// ✅ External history
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

// Update patient (Reception/Admin فقط)
router.patch(
  '/:id',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(updatePatientSchema),
  patientsController.updatePatient
);

module.exports = router;
