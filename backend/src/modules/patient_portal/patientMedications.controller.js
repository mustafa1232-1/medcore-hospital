const svc = require('./patientMedications.service');

module.exports = {
  async listMyMedications(req, res, next) {
    try {
      const { tenantId, tenantPatientId } = req.patient;

      const data = await svc.listMyMedications({
        tenantId,
        patientId: tenantPatientId,
      });

      // ✅ patient يرى الدواء فقط (بدون status)
      return res.json({ data });
    } catch (e) {
      return next(e);
    }
  },
};
