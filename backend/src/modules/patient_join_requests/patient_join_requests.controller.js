const svc = require('./patient_join_requests.service');

module.exports = {
  async submitByCode(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const code = String(req.body?.code || '').trim();

      const out = await svc.submitByCode({ patientAccountId, code });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async listMine(req, res, next) {
    try {
      const tenantId = String(req.tenantId || req.user?.tenantId || '');
      const limit = Math.min(50, Math.max(1, Number(req.query?.limit) || 20));
      const offset = Math.max(0, Number(req.query?.offset) || 0);

      const out = await svc.listMine({ tenantId, limit, offset });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async approve(req, res, next) {
    try {
      const tenantId = String(req.tenantId || req.user?.tenantId || '');
      const id = String(req.params?.id || '');
      const staffUserId = req.user?.sub || null;

      const out = await svc.decide({ tenantId, id, action: 'APPROVED', staffUserId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async reject(req, res, next) {
    try {
      const tenantId = String(req.tenantId || req.user?.tenantId || '');
      const id = String(req.params?.id || '');
      const staffUserId = req.user?.sub || null;

      const out = await svc.decide({ tenantId, id, action: 'REJECTED', staffUserId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
