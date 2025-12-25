const svc = require('./patient_link.service');

module.exports = {
  async issueJoinCode(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = String(req.params.id);

      const ttlMinutes = req.body?.ttlMinutes ? Number(req.body.ttlMinutes) : 30;

      const out = await svc.issueJoinCode({
        tenantId,
        patientId,
        ttlMinutes,
      });

      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async externalHistory(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = String(req.params.id);

      const out = await svc.getExternalHistory({ tenantId, patientId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
