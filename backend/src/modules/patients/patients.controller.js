// src/modules/patients/patients.controller.js
const patientsService = require('./patients.service');

module.exports = {
  async listPatients(req, res, next) {
    try {
      const tenantId = req.user.tenantId;

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

      const patient = await patientsService.updatePatient(tenantId, patientId, req.body);
      return res.json(patient);
    } catch (err) {
      return next(err);
    }
  },

  // ✅ NEW: assigned patients for doctor
  async listAssignedPatients(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const doctorUserId = req.user.userId;

      const result = await patientsService.listAssignedPatients({
        tenantId,
        doctorUserId,
        q: req.query.q,
        limit: req.query.limit,
        offset: req.query.offset,
      });

      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  // ✅ NEW
  async getPatientMedicalRecord(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = req.params.id;

      const limit = req.query.limit;
      const offset = req.query.offset;

      const data = await patientsService.getPatientMedicalRecord({
        tenantId,
        patientId,
        limit,
        offset,
      });

      return res.json({ data });
    } catch (err) {
      return next(err);
    }
  },

  // ✅ NEW
  async getPatientHealthAdvice(req, res, next) {
    try {
      const tenantId = req.user.tenantId;
      const patientId = req.params.id;

      const data = await patientsService.getPatientHealthAdvice({
        tenantId,
        patientId,
      });

      return res.json({ data });
    } catch (err) {
      return next(err);
    }
  },
};
