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
// ✅ NEW: list assigned patients for the logged-in doctor
async function listAssignedPatients({ tenantId, doctorUserId, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!doctorUserId) throw new HttpError(400, 'Missing doctorUserId');

  const safeLimit = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  /**
   * Logic:
   * - A patient is considered "assigned" to a doctor if they have an ACTIVE/PENDING admission
   *   where assigned_doctor_user_id = current doctor.
   * - Return unique patients with latest admission timestamp ordering.
   */
  const sql = `
    WITH latest AS (
      SELECT
        a.patient_id,
        MAX(a.created_at) AS last_created_at
      FROM admissions a
      WHERE a.tenant_id = $1
        AND a.assigned_doctor_user_id = $2
        AND a.status IN ('ACTIVE','PENDING')
      GROUP BY a.patient_id
    )
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.is_active AS "isActive",
      l.last_created_at AS "lastAdmissionAt"
    FROM latest l
    JOIN patients p
      ON p.id = l.patient_id
     AND p.tenant_id = $1
    ORDER BY l.last_created_at DESC
    LIMIT $3 OFFSET $4
  `;

  const r = await pool.query(sql, [tenantId, doctorUserId, safeLimit, safeOffset]);

  // total (for pagination meta)
  const countQ = await pool.query(
    `
    SELECT COUNT(*)::int AS count
    FROM (
      SELECT 1
      FROM admissions a
      WHERE a.tenant_id = $1
        AND a.assigned_doctor_user_id = $2
        AND a.status IN ('ACTIVE','PENDING')
      GROUP BY a.patient_id
    ) t
    `,
    [tenantId, doctorUserId]
  );

  const total = countQ.rows[0]?.count || 0;

  return {
    items: r.rows,
    meta: { total, limit: safeLimit, offset: safeOffset },
  };
}

module.exports = {
  listPatients,
  createPatient,
  getPatientById,
  updatePatient,

  // NEW
  getPatientMedicalRecord,
  getPatientHealthAdvice,

  // ✅ NEW
  listAssignedPatients,
};