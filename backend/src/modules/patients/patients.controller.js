// src/modules/patients/patients.controller.js
const patientsService = require('./patients.service');

function getTenantId(req) {
  return req.user.tenantId;
}

function getUserId(req) {
  // ✅ standard in your backend (like admissions.controller.js)
  return req.user.sub || req.user.userId || req.user.id;
}

module.exports = {
  async listPatients(req, res, next) {
    try {
      const tenantId = getTenantId(req);

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
      const tenantId = getTenantId(req);

      const patient = await patientsService.createPatient(tenantId, req.body);
      return res.status(201).json(patient);
    } catch (err) {
      return next(err);
    }
  },

  async getPatientById(req, res, next) {
    try {
      const tenantId = getTenantId(req);
      const patientId = req.params.id;

      const patient = await patientsService.getPatientById(tenantId, patientId);
      return res.json(patient);
    } catch (err) {
      return next(err);
    }
  },

  async updatePatient(req, res, next) {
    try {
      const tenantId = getTenantId(req);
      const patientId = req.params.id;

      const patient = await patientsService.updatePatient(tenantId, patientId, req.body);
      return res.json(patient);
    } catch (err) {
      return next(err);
    }
  },

  // ✅ Assigned patients for doctor/admin
  async listAssignedPatients(req, res, next) {
    try {
      const tenantId = getTenantId(req);
      const doctorUserId = getUserId(req);

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

  async getPatientMedicalRecord(req, res, next) {
    try {
      const tenantId = getTenantId(req);
      const patientId = req.params.id;

      const data = await patientsService.getPatientMedicalRecord({
        tenantId,
        patientId,
        limit: req.query.limit,
        offset: req.query.offset,
      });

      return res.json({ data });
    } catch (err) {
      return next(err);
    }
  },

  async getPatientHealthAdvice(req, res, next) {
    try {
      const tenantId = getTenantId(req);
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
