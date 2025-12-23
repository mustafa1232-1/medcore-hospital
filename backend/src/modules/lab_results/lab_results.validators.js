const Joi = require('joi');

const createLabResultSchema = Joi.object({
  orderId: Joi.string().uuid().required(),

  // result JSON payload
  result: Joi.object().required(),

  // optional note
  notes: Joi.string().allow('', null).max(2000).default(null),

  // optional: mark order completed when result added
  markOrderCompleted: Joi.boolean().default(true),
});

const listLabResultsQuerySchema = Joi.object({
  patientId: Joi.string().uuid().optional(),
  admissionId: Joi.string().uuid().optional(),
  orderId: Joi.string().uuid().optional(),

  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

module.exports = {
  createLabResultSchema,
  listLabResultsQuerySchema,
};
