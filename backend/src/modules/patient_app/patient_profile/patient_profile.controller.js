const svc = require('./patient_profile.service');

module.exports = {
  async getMyProfile(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const out = await svc.getOrCreateProfile({ patientAccountId });
      return res.json({ ok: true, data: out });
    } catch (e) {
      return next(e);
    }
  },

  async patchMyProfile(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const out = await svc.patchProfile({
        patientAccountId,
        patch: req.body || {},
      });
      return res.json({ ok: true, data: out });
    } catch (e) {
      return next(e);
    }
  },
};
