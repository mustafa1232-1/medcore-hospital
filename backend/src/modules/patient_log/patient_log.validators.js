const Joi = require('joi');

const createPatientLogSchema = Joi.object({
  admissionId: Joi.string().uuid().optional().allow(null, ''),
  eventType: Joi.string().trim().min(2).max(80).required(),
  message: Joi.string().allow('', null).max(500).optional().default(null),
  meta: Joi.object().optional().default({}),
});

module.exports = { createPatientLogSchema };
