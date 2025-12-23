// src/modules/orders/orders.validators.js
const Joi = require('joi');

const createMedicationOrderSchema = Joi.object({
  admissionId: Joi.string().uuid().required(),

  /**
   * ✅ Backward compatible:
   * - القديم: medicationName + dose + route + frequency...
   * - الجديد: drugId + requestedQty + (تعليمات المريض... )
   */
  drugId: Joi.string().uuid().allow(null, '').default(null),

  // ✅ requestedQty: خليها integer positive (أوضح للمخزون)
  requestedQty: Joi.number().integer().positive().allow(null).default(null),

  // ✅ القديم: required حتى لا نكسر القديم
  medicationName: Joi.string().trim().min(2).max(200).required(),
  dose: Joi.string().trim().min(1).max(80).required(),
  route: Joi.string().trim().min(1).max(80).required(),
  frequency: Joi.string().trim().min(1).max(80).required(),
  duration: Joi.string().trim().min(1).max(80).allow(null, '').default(null),
  startNow: Joi.boolean().default(true),

  // ✅ معلومات المريض الإضافية (matching drug_catalog fields)
  patientInstructionsAr: Joi.string().allow('', null).max(2000).default(null),
  patientInstructionsEn: Joi.string().allow('', null).max(2000).default(null),
  dosageText: Joi.string().allow('', null).max(200).default(null),
  frequencyText: Joi.string().allow('', null).max(200).default(null),
  durationText: Joi.string().allow('', null).max(200).default(null),
  withFood: Joi.boolean().allow(null).default(null),
  warningsText: Joi.string().allow('', null).max(2000).default(null),

  notes: Joi.string().allow('', null).max(2000).default(null),
});

const createLabOrderSchema = Joi.object({
  admissionId: Joi.string().uuid().required(),
  testName: Joi.string().trim().min(2).max(200).required(),
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
  status: Joi.string()
    .valid('CREATED', 'IN_PROGRESS', 'PARTIALLY_COMPLETED', 'COMPLETED', 'OUT_OF_STOCK', 'CANCELLED')
    .optional(),
  limit: Joi.number().integer().min(1).max(100).default(20),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const cancelOrderSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

/** =========================
 * ✅ Pharmacy actions schemas
 * ========================= */
const pharmacyPrepareSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const pharmacyPartialSchema = Joi.object({
  preparedQty: Joi.number().integer().positive().required(),
  notes: Joi.string().allow('', null).max(2000).default(null),
});

// ✅ في routes عندك اسمها out-of-stock وتستخدم notes
const pharmacyOutOfStockSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

module.exports = {
  createMedicationOrderSchema,
  createLabOrderSchema,
  createProcedureOrderSchema,
  listOrdersQuerySchema,
  cancelOrderSchema,
  pharmacyPrepareSchema,
  pharmacyPartialSchema,
  pharmacyOutOfStockSchema,
};
