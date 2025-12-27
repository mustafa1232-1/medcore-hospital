// src/modules/patient_join_codes/patient_join_codes.controller.js
const svc = require('./patient_join_codes.service');

module.exports = {
  async create(req, res, next) {
    try {
      const tenantId = req.user?.tenantId;
      const createdByUserId = req.user?.sub || null;

      const expiresInMinutes = Number(req.body?.expiresInMinutes ?? 10);
      const maxUses = Number(req.body?.maxUses ?? 1);

      const out = await svc.createJoinCode({
        tenantId,
        createdByUserId,
        expiresInMinutes,
        maxUses,
      });

      return res.json({ ok: true, data: out });
    } catch (e) {
      return next(e);
    }
  },
};
