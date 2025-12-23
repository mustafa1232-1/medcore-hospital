const Joi = require('joi');

const StockMoveType = [
  'RECEIPT',
  'DISPENSE',
  'TRANSFER_OUT',
  'TRANSFER_IN',
  'ADJUSTMENT_IN',
  'ADJUSTMENT_OUT',
  'WASTE',
  'RETURN',
];

const RequestStatus = ['DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'];

const createRequestSchema = Joi.object({
  kind: Joi.string().valid(...StockMoveType).required(),

  fromWarehouseId: Joi.string().uuid().allow(null),
  toWarehouseId: Joi.string().uuid().allow(null),

  // dispense refs
  patientId: Joi.string().uuid().allow(null),
  admissionId: Joi.string().uuid().allow(null),
  orderId: Joi.string().uuid().allow(null),

  notes: Joi.string().allow('', null).max(2000).default(null),
});

const addLineSchema = Joi.object({
  drugId: Joi.string().uuid().required(),
  qty: Joi.number().positive().max(1000000).required(),

  lotNumber: Joi.string().trim().max(80).allow(null, '').default(null),
  expiryDate: Joi.date().iso().allow(null).default(null),
  unitCost: Joi.number().precision(4).min(0).max(100000000).allow(null).default(null),

  notes: Joi.string().allow('', null).max(1000).default(null),
});

const updateLineSchema = Joi.object({
  qty: Joi.number().positive().max(1000000),
  lotNumber: Joi.string().trim().max(80).allow(null, ''),
  expiryDate: Joi.date().iso().allow(null),
  unitCost: Joi.number().precision(4).min(0).max(100000000).allow(null),
  notes: Joi.string().allow('', null).max(1000),
}).min(1);

const listRequestsQuerySchema = Joi.object({
  status: Joi.string().valid(...RequestStatus).optional(),
  kind: Joi.string().valid(...StockMoveType).optional(),
  fromWarehouseId: Joi.string().uuid().optional(),
  toWarehouseId: Joi.string().uuid().optional(),
  patientId: Joi.string().uuid().optional(),
  admissionId: Joi.string().uuid().optional(),
  orderId: Joi.string().uuid().optional(),
  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const submitSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const approveSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const rejectSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

module.exports = {
  StockMoveType,
  createRequestSchema,
  addLineSchema,
  updateLineSchema,
  listRequestsQuerySchema,
  submitSchema,
  approveSchema,
  rejectSchema,
};
