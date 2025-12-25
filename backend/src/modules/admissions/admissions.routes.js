// src/modules/admissions/admissions.routes.js
const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const ctrl = require('./admissions.controller');
const {
  createAdmissionSchema,
  createOutpatientSchema,
  updateAdmissionSchema,
  assignBedSchema,
  closeAdmissionSchema,
} = require('./admissions.validators');

const router = express.Router();

// LIST: Admin only
router.get('/', requireAuth, requireRole('ADMIN'), ctrl.list);

// ✅ CREATE (Inpatient/Pending):
// was RECEPTION only; now allow DOCTOR too (as you requested)
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION', 'DOCTOR', 'ADMIN'),
  validateBody(createAdmissionSchema),
  ctrl.create
);

// ✅ DOCTOR creates outpatient visit (ACTIVE, no bed)
router.post(
  '/outpatient',
  requireAuth,
  requireRole('DOCTOR', 'ADMIN'),
  validateBody(createOutpatientSchema),
  ctrl.createOutpatient
);

// ✅ DOCTOR gets active admission for patient
router.get(
  '/active',
  requireAuth,
  requireRole('DOCTOR', 'ADMIN'),
  ctrl.getActiveForPatient
);

// VIEW: Admin only (keep)
router.get('/:id', requireAuth, requireRole('ADMIN'), ctrl.getOne);

// UPDATE: Admin only (keep)
router.patch(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(updateAdmissionSchema),
  ctrl.update
);

// ✅ Assign bed: allow DOCTOR too (your request)
router.post(
  '/:id/assign-bed',
  requireAuth,
  requireRole('ADMIN', 'DOCTOR'),
  validateBody(assignBedSchema),
  ctrl.assignBed
);

// release bed: keep admin (you can add DOCTOR if you want)
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
