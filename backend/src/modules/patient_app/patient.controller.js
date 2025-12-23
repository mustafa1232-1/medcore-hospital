const svc = require('./patient.service');

module.exports = {
  async listMyMedications(req, res, next) {
    try {
      const { tenantId, tenantPatientId } = req.patient;

      const limit = Number(req.query.limit || 50);
      const offset = Number(req.query.offset || 0);

      const data = await svc.listMyMedications({
        tenantId,
        tenantPatientId,
        limit,
        offset,
      });

      return res.json(data);
    } catch (e) {
      return next(e);
    }
  },
};
