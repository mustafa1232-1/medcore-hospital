// src/modules/patients/patient_join_code.controller.js
const svc = require('./patient_join_code.service');

module.exports = {
  async issue(req, res, next) {
    try {
      const tenantId = String(req.params.tenantId || '');
      const patientId = String(req.params.patientId || '');

      const len = req.body?.len;
      const ttlMinutes = req.body?.ttlMinutes;

      const out = await svc.issueJoinCode({
        tenantId,
        patientId,
        len,
        ttlMinutes,
      });

      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async revoke(req, res, next) {
    try {
      const tenantId = String(req.params.tenantId || '');
      const patientId = String(req.params.patientId || '');

      const out = await svc.revokeJoinCode({ tenantId, patientId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
