const Joi = require('joi');

const createMedicationOrderSchema = Joi.object({
  admissionId: Joi.string().uuid().required(),

  // payload (بحد أدنى)
  medicationName: Joi.string().trim().min(2).max(200).required(),
  dose: Joi.string().trim().min(1).max(80).required(),        // "500mg"
  route: Joi.string().trim().min(1).max(80).required(),       // "IV / PO"
  frequency: Joi.string().trim().min(1).max(80).required(),   // "BID / TID / q8h"
  duration: Joi.string().trim().min(1).max(80).allow(null, '').default(null),
  startNow: Joi.boolean().default(true),

  notes: Joi.string().allow('', null).max(2000).default(null),
});

const createLabOrderSchema = Joi.object({
  admissionId: Joi.string().uuid().required(),

  testName: Joi.string().trim().min(2).max(200).required(),   // "CBC"
  priority: Joi.string().valid('ROUTINE', 'STAT').default('ROUTINE'),
  specimen: Joi.string().trim().min(1).max(120).default('BLOOD'),
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const createProcedureOrderSchema = Joi.object({
  admissionId: Joi.string().uuid().required(),

  procedureName: Joi.string().trim().min(2).max(250).required(),
  urgency: Joi.string().valid('NORMAL', 'URGENT').default('NORMAL'),
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const listOrdersQuerySchema = Joi.object({
  admissionId: Joi.string().uuid().optional(),
  patientId: Joi.string().uuid().optional(),
  kind: Joi.string().valid('MEDICATION', 'LAB', 'PROCEDURE').optional(),
  status: Joi.string().valid('CREATED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED').optional(),
  limit: Joi.number().integer().min(1).max(100).default(20),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const cancelOrderSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

module.exports = {
  createMedicationOrderSchema,
  createLabOrderSchema,
  createProcedureOrderSchema,
  listOrdersQuerySchema,
  cancelOrderSchema,
};
