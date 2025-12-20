// src/modules/patients/patients.controller.js
const patientsService = require('./patients.service');

module.exports = {
  /**
   * GET /api/patients
   * Query:
   *  - q: search by name / phone
   */
  async listPatients(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const q = req.query.q || null;

      const rows = await patientsService.listPatients({ tenantId, q });
      return res.json({ items: rows });
    } catch (err) {
      return next(err);
    }
  },

  /**
   * POST /api/patients
   */
  async createPatient(req, res, next) {
    try {
      const tenantId = req.user.tenantId;

      const patient = await patientsService.createPatient(tenantId, req.body);
      return res.status(201).json(patient);
    } catch (err) {
      return next(err);
    }
  },

  /**
   * GET /api/patients/:id
   */
  async getPatientById(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = req.params.id;

      const patient = await patientsService.getPatientById(tenantId, patientId);
      return res.json(patient);
    } catch (err) {
      return next(err);
    }
  },

  /**
   * PATCH /api/patients/:id
   */
  async updatePatient(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = req.params.id;

      const patient = await patientsService.updatePatient(
        tenantId,
        patientId,
        req.body
      );

      return res.json(patient);
    } catch (err) {
      return next(err);
    }
  },
};
