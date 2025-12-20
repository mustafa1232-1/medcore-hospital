// src/modules/patients/patients.controller.js
const patientsService = require('./patients.service');

module.exports = {
  async listPatients(req, res, next) {
    try {
      const tenantId = req.user.tenantId;

      // ✅ نمرر Query كما هو للسيرفس (بدون تغيير أي routes)
      const result = await patientsService.listPatients({
        tenantId,
        query: req.query,
      });

      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  async createPatient(req, res, next) {
    try {
      const tenantId = req.user.tenantId;

      const patient = await patientsService.createPatient(tenantId, req.body);
      return res.status(201).json(patient);
    } catch (err) {
      return next(err);
    }
  },

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
