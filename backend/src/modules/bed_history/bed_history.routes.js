const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const { requirePermission } = require('../../utils/requirePermission');

const ctrl = require('./bed_history.controller');

const router = express.Router();

// GET /api/facility/beds/:bedId/history
router.get(
  '/facility/beds/:bedId/history',
  requireAuth,
  requirePermission('facility.read'),
  ctrl.listByBed
);

// GET /api/bed-history/:id (اختياري للتفاصيل)
router.get(
  '/bed-history/:id',
  requireAuth,
  requirePermission('facility.read'),
  ctrl.getOne
);

module.exports = router;
