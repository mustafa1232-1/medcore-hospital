// src/modules/patients/patients.routes.js
const express = require('express');
const router = express.Router();

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');
const patientProfileSnapshotsController = require('./patient_profile_snapshots.controller');
const patientsController = require('./patients.controller');
const { createPatientSchema, updatePatientSchema } = require('./patients.validators');

// Join code + external history (cross-facility)
const patientLinkController = require('./patient_link.controller');

/**
 * Roles:
 * - RECEPTION: create + update + list + view + medical record
 * - DOCTOR: list + view + medical record + advice + assigned
 * - ADMIN: full access
 */

// ✅ Doctor/Admin: Assigned patients
// IMPORTANT: must be BEFORE "/:id" routes
router.get(
  '/assigned',
  requireAuth,
  requireRole('DOCTOR', 'ADMIN'),
  patientsController.listAssignedPatients
);

// ✅ Compatibility guard: prevent "/lookup" being treated as ":id"
router.get(
  '/lookup',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  async (req, res) => {
    return res
      .status(410)
      .json({ message: 'Deprecated. Use GET /api/lookups/patients' });
  }
);

// List patients
router.get(
  '/',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.listPatients
);

// Create patient (Reception/Admin only)
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(createPatientSchema),
  patientsController.createPatient
);

// Medical record (keep before "/:id")
router.get(
  '/:id/medical-record',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientMedicalRecord
);

// Health advice (keep before "/:id")
router.get(
  '/:id/health-advice',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientHealthAdvice
);

// Generate join code (Reception/Admin only)
router.post(
  '/:id/join-code',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  patientLinkController.issueJoinCode
);

// External history across facilities
router.get(
  '/:id/external-history',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientLinkController.externalHistory
);
router.get(
  '/:id/profile-snapshots',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientProfileSnapshotsController.list
);
// Get single patient
router.get(
  '/:id',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN', 'DOCTOR'),
  patientsController.getPatientById
);

// Update patient (Reception/Admin only)
router.patch(
  '/:id',
  requireAuth,
  requireRole('RECEPTION', 'ADMIN'),
  validateBody(updatePatientSchema),
  patientsController.updatePatient
);

module.exports = router;
