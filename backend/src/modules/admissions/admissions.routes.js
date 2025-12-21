const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { validateBody } = require('../../middlewares/validate');

const ctrl = require('./admissions.controller');
const {
  createAdmissionSchema,
  updateAdmissionSchema,
  assignBedSchema,
  closeAdmissionSchema,
} = require('./admissions.validators');

const router = express.Router();

// LIST: خليه للأدمن فقط كبداية (آمن مع requireRole الحالي)
router.get('/', requireAuth, requireRole('ADMIN'), ctrl.list);

// CREATE: Reception ينشئ Admission PENDING
router.post(
  '/',
  requireAuth,
  requireRole('RECEPTION'),
  validateBody(createAdmissionSchema),
  ctrl.create
);

// VIEW: Admin (يمكن نوسعها لاحقًا لو عدلنا requireRole إلى requireAnyRole)
router.get('/:id', requireAuth, requireRole('ADMIN'), ctrl.getOne);

// UPDATE: Admin/Doctor لاحقًا. الآن Admin فقط (آمن)
router.patch(
  '/:id',
  requireAuth,
  requireRole('ADMIN'),
  validateBody(updateAdmissionSchema),
  ctrl.update
);

// Assign bed: Admin (أو Doctor لاحقًا)
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
