// src/modules/patients/patients.controller.js
const patientsService = require('./patients.service');

module.exports = {
  async listPatients(req, res, next) {
    try {
      const tenantId = req.user.tenantId;

      const result = await patientsService.listPatients({
        tenantId,
        q: req.query.q,
        phone: req.query.phone,
        gender: req.query.gender,
        isActive: req.query.isActive,
        dobFrom: req.query.dobFrom,
        dobTo: req.query.dobTo,
        createdFrom: req.query.createdFrom,
        createdTo: req.query.createdTo,
        limit: req.query.limit,
        offset: req.query.offset,
      });

      // ✅ لا نكسر الشكل القديم: items موجود دائماً
      return res.json({
        items: result.items,
        meta: result.meta,
      });
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
