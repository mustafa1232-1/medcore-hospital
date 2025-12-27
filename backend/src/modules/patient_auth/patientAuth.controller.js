const svc = require('./patientAuth.service');

module.exports = {
  async register(req, res, next) {
    try {
      const out = await svc.patientRegister({
        fullName: req.body.fullName,
        email: req.body.email || null,
        phone: req.body.phone || null,
        password: req.body.password,
      });
      return res.status(201).json(out);
    } catch (e) {
      return next(e);
    }
  },

  async login(req, res, next) {
    try {
      const out = await svc.patientLogin({
        email: req.body.email || null,
        phone: req.body.phone || null,
        password: req.body.password,
      });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },

  async me(req, res, next) {
    try {
      const patientAccountId = req.patientUser?.sub;
      const out = await svc.patientMe({ patientAccountId });
      return res.json(out);
    } catch (e) {
      return next(e);
    }
  },
};
