const svc = require('./patient_join.service');

module.exports = {
  async join(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const { tenantId, patientId, joinCode } = req.body || {};

      const out = await svc.joinFacility({
        patientAccountId,
        tenantId: String(tenantId || ''),
        patientId: String(patientId || ''),
        joinCode: String(joinCode || ''),
      });

      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async leave(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const tenantId = String(req.params.tenantId);

      const out = await svc.leaveFacility({ patientAccountId, tenantId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
