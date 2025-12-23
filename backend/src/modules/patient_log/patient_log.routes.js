const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requirePermission } = require('../../utils/requirePermission');
const { validateBody } = require('../../middlewares/validate');

const ctrl = require('./patient_log.controller');
const { createPatientLogSchema } = require('./patient_log.validators');

const router = express.Router();

// GET /api/patients/:patientId/log
router.get(
  '/patients/:patientId/log',
  requireAuth,
  requirePermission('patients.read'),
  ctrl.listByPatient
);

// POST /api/patients/:patientId/log  (اختياري - مخصص للطبيب/الإدارة)
router.post(
  '/patients/:patientId/log',
  requireAuth,
  requirePermission('patients.write'),
  validateBody(createPatientLogSchema),
  ctrl.create
);

// GET /api/patient-log/:id (تفاصيل سطر واحد)
router.get(
  '/patient-log/:id',
  requireAuth,
  requirePermission('patients.read'),
  ctrl.getOne
);

module.exports = router;
