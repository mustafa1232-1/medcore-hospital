const svc = require('./patient_profile_snapshots.service');

function tenantId(req) {
  return req.user.tenantId;
}

module.exports = {
  async list(req, res, next) {
    try {
      const patientId = String(req.params.id);
      const limit = req.query.limit;
      const offset = req.query.offset;

      const out = await svc.listPatientProfileSnapshots({
        tenantId: tenantId(req),
        patientId,
        limit,
        offset,
      });

      return res.json({ data: out.items, meta: out.meta });
    } catch (e) {
      return next(e);
    }
  },
};
