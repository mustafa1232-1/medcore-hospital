const Joi = require('joi');

const DrugForm = [
  'TABLET',
  'CAPSULE',
  'SYRUP',
  'INJECTION',
  'DROPS',
  'CREAM',
  'OINTMENT',
  'SUPPOSITORY',
  'IV_BAG',
  'INHALER',
  'OTHER',
];

const listDrugQuerySchema = Joi.object({
  q: Joi.string().allow('', null).max(200).default(''),
  active: Joi.boolean().optional(),
  form: Joi.string().valid(...DrugForm).optional(),
  route: Joi.string().allow('', null).max(50).optional(),
  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const createDrugSchema = Joi.object({
  genericName: Joi.string().trim().min(2).max(200).required(),
  brandName: Joi.string().trim().max(200).allow(null, '').default(null),
  strength: Joi.string().trim().max(80).allow(null, '').default(null),
  form: Joi.string().valid(...DrugForm).default('OTHER'),
  route: Joi.string().trim().max(50).allow(null, '').default(null),
  unit: Joi.string().trim().max(50).allow(null, '').default(null),
  packSize: Joi.number().integer().min(1).max(100000).allow(null).default(null),
  barcode: Joi.string().trim().max(100).allow(null, '').default(null),
  atcCode: Joi.string().trim().max(30).allow(null, '').default(null),
  isActive: Joi.boolean().default(true),
});

const updateDrugSchema = Joi.object({
  genericName: Joi.string().trim().min(2).max(200),
  brandName: Joi.string().trim().max(200).allow(null, ''),
  strength: Joi.string().trim().max(80).allow(null, ''),
  form: Joi.string().valid(...DrugForm),
  route: Joi.string().trim().max(50).allow(null, ''),
  unit: Joi.string().trim().max(50).allow(null, ''),
  packSize: Joi.number().integer().min(1).max(100000).allow(null),
  barcode: Joi.string().trim().max(100).allow(null, ''),
  atcCode: Joi.string().trim().max(30).allow(null, ''),
  isActive: Joi.boolean(),
}).min(1);

module.exports = {
  DrugForm,
  listDrugQuerySchema,
  createDrugSchema,
  updateDrugSchema,
};
