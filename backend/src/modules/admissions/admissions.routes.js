const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const ctrl = require('./admissions.controller');
const {
  createAdmissionSchema,
  createOutpatientSchema, // ✅ new
  updateAdmissionSchema,
  assignBedSchema,
  closeAdmissionSchema,
} = require('./admissions.validators');

const router = express.Router();

// LIST: Admin only
router.get('/', requireAuth, requireRole('ADMIN'), ctrl.list);

// CREATE: Reception creates PENDING
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION'),
  validateBody(createAdmissionSchema),
  ctrl.create
);

// ✅ NEW: DOCTOR creates outpatient visit (ACTIVE, no bed)
router.post(
  '/outpatient',
  requireAuth,
  requireRole('DOCTOR'),
  validateBody(createOutpatientSchema),
  ctrl.createOutpatient
);

// ✅ NEW: DOCTOR gets active admission for patient
router.get(
  '/active',
  requireAuth,
  requireRole('DOCTOR'),
  ctrl.getActiveForPatient
);

// VIEW: Admin
router.get('/:id', requireAuth, requireRole('ADMIN'), ctrl.getOne);

// UPDATE: Admin
router.patch(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(updateAdmissionSchema),
  ctrl.update
);

// Assign bed: Admin
router.post(
  '/:id/assign-bed',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(assignBedSchema),
  ctrl.assignBed
);

router.post(
  '/:id/release-bed',
  requireAuth,
  requireRole('ADMIN'),
  ctrl.releaseBed
);

router.post(
  '/:id/discharge',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(closeAdmissionSchema),
  ctrl.discharge
);

router.post(
  '/:id/cancel',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(closeAdmissionSchema),
  ctrl.cancel
);

module.exports = router;
