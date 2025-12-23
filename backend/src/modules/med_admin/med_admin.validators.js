const Joi = require('joi');

const MedicationAdminStatus = ['SCHEDULED', 'GIVEN', 'MISSED', 'CANCELLED'];

const createMedAdminSchema = Joi.object({
  orderId: Joi.string().uuid().required(),

  // For SCHEDULED you may provide scheduledAt
  scheduledAt: Joi.date().iso().optional().allow(null),

  // If given now
  giveNow: Joi.boolean().default(true),

  // status override (default depends on giveNow)
  status: Joi.string().valid(...MedicationAdminStatus).optional(),

  notes: Joi.string().allow('', null).max(2000).default(null),

  // Optional: when GIVEN, mark tasks/order completed
  markOrderCompleted: Joi.boolean().default(false),
});

const listMedAdminsQuerySchema = Joi.object({
  patientId: Joi.string().uuid().optional(),
  admissionId: Joi.string().uuid().optional(),
  orderId: Joi.string().uuid().optional(),

  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

module.exports = {
  createMedAdminSchema,
  listMedAdminsQuerySchema,
};
