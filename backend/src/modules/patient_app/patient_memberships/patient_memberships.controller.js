const svc = require('./patient_memberships.service');

module.exports = {
  async listMyMemberships(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const out = await svc.listMyMemberships({ patientAccountId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async listMyJoinRequests(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const limit = Math.min(50, Math.max(1, Number(req.query?.limit) || 20));
      const offset = Math.max(0, Number(req.query?.offset) || 0);

      const out = await svc.listMyJoinRequests({ patientAccountId, limit, offset });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
