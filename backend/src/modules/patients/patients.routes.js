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
async function listAssignedPatients({ tenantId, doctorUserId, q, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!doctorUserId) throw new HttpError(400, 'Missing doctorUserId');

  const safeLimit = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  const params = [tenantId, doctorUserId];
  let i = 3;

  // ✅ نعرض مرضى الطبيب بناءً على admissions الحالية (PENDING/ACTIVE)
  // ✅ DISTINCT لتجنب تكرار المريض لو عنده أكثر من admission
  let where = `
    a.tenant_id = $1
    AND a.assigned_doctor_user_id = $2
    AND a.status IN ('PENDING','ACTIVE')
  `;

  if (q) {
    params.push(`%${String(q).toLowerCase()}%`);
    where += `
      AND (
        LOWER(p.full_name) LIKE $${i}
        OR COALESCE(p.phone,'') LIKE $${i}
      )
    `;
    i++;
  }

  const countQ = await pool.query(
    `
    SELECT COUNT(DISTINCT p.id)::int AS count
    FROM admissions a
    JOIN patients p
      ON p.tenant_id = a.tenant_id
     AND p.id = a.patient_id
    WHERE ${where}
    `,
    params
  );

  const total = countQ.rows[0]?.count || 0;

  params.push(safeLimit, safeOffset);

  const listSql = `
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.national_id AS "nationalId",
      p.address,
      p.notes,
      p.is_active AS "isActive",
      p.created_at AS "createdAt",

      a.id AS "admissionId",
      a.status AS "admissionStatus",
      a.reason AS "admissionReason",
      a.started_at AS "admissionStartedAt",
      a.created_at AS "admissionCreatedAt"
    FROM admissions a
    JOIN patients p
      ON p.tenant_id = a.tenant_id
     AND p.id = a.patient_id
    WHERE ${where}
    ORDER BY p.id, a.created_at DESC
    LIMIT $${i} OFFSET $${i + 1}
  `;

  const { rows } = await pool.query(listSql, params);

  return {
    items: rows,
    meta: { total, limit: safeLimit, offset: safeOffset },
  };
}

module.exports = {
  listPatients,
  createPatient,
  getPatientById,
  updatePatient,

  // ✅ ADD THIS
  listAssignedPatients,

  getPatientMedicalRecord,
  getPatientHealthAdvice,
};