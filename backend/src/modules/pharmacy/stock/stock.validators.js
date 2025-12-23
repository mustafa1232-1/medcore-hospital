// src/modules/pharmacy/stock/stock.validators.js
const Joi = require('joi');

const balanceQuerySchema = Joi.object({
  warehouseId: Joi.string().uuid().required(),
  drugId: Joi.string().uuid().optional(),
  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const ledgerQuerySchema = Joi.object({
  drugId: Joi.string().uuid().optional(),
  warehouseId: Joi.string().uuid().optional(),
  patientId: Joi.string().uuid().optional(),
  admissionId: Joi.string().uuid().optional(),
  orderId: Joi.string().uuid().optional(),
  kind: Joi.string()
    .valid('RECEIPT','DISPENSE','TRANSFER_OUT','TRANSFER_IN','ADJUSTMENT_IN','ADJUSTMENT_OUT','WASTE','RETURN')
    .optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

module.exports = { balanceQuerySchema, ledgerQuerySchema };
