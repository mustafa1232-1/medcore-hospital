// src/modules/patients/patient_join_code.routes.js
const express = require('express');

const { requireAuth } = require('../../middlewares/auth');
const { requireRole } = require('../../middlewares/roles');
const { HttpError } = require('../../utils/httpError');

const ctrl = require('./patient_join_code.controller');

const router = express.Router();

/**
 * ✅ Tenant guard:
 * - يضمن أن المستخدم (staff) لا يستطيع إصدار/إلغاء كود لمنشأة غير منشأته
 * - يعتمد على req.user.tenantId الموجود في JWT (staff)
 */
function requireSameTenantParam(paramName = 'tenantId') {
  return (req, _res, next) => {
    const tokenTenantId = req.user?.tenantId;
    const routeTenantId = String(req.params?.[paramName] || '');

    if (!tokenTenantId) return next(new HttpError(401, 'Unauthorized'));
    if (!routeTenantId) return next(new HttpError(400, `Missing ${paramName}`));

    if (String(tokenTenantId) !== routeTenantId) {
      return next(new HttpError(403, 'Forbidden: tenant mismatch'));
    }

    return next();
  };
}

// Staff issues join code for a specific patient in a facility
router.post(
  '/tenants/:tenantId/patients/:patientId/issue-join-code',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  requireSameTenantParam('tenantId'),
  ctrl.issue
);

// Staff revokes join code
router.post(
  '/tenants/:tenantId/patients/:patientId/revoke-join-code',
  requireAuth,
  requireRole('ADMIN', 'RECEPTION'),
  requireSameTenantParam('tenantId'),
  ctrl.revoke
);

module.exports = router;
