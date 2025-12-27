const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { requirePatientAuth } = require('../../middlewares/patientAuth');
const { HttpError } = require('../../utils/httpError');

const ctrl = require('./patient_join_requests.controller');

const router = express.Router();

function requireSameTenantFromToken() {
  return (req, _res, next) => {
    const tokenTenantId = req.user?.tenantId;
    if (!tokenTenantId) return next(new HttpError(401, 'Unauthorized'));
    req.tenantId = String(tokenTenantId);
    return next();
  };
}

// ==========================
// Patient submits join request by facility code
// ==========================
router.post('/submit', requirePatientAuth, ctrl.submitByCode);

// ==========================
// Staff (Reception/Admin) list requests for own tenant
// ==========================
router.get(
  '/',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  requireSameTenantFromToken(),
  ctrl.listMine
);

// Approve / Reject
router.post(
  '/:id/approve',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  requireSameTenantFromToken(),
  ctrl.approve
);

router.post(
  '/:id/reject',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  requireSameTenantFromToken(),
  ctrl.reject
);

module.exports = router;
