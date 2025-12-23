const Joi = require('joi');

const listWarehousesQuerySchema = Joi.object({
  active: Joi.boolean().optional(),
  q: Joi.string().allow('', null).max(200).default(''),
  limit: Joi.number().integer().min(1).max(200).default(50),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const createWarehouseSchema = Joi.object({
  name: Joi.string().trim().min(2).max(200).required(),
  code: Joi.string().trim().max(50).allow(null, '').default(null),
  isActive: Joi.boolean().default(true),
});

const updateWarehouseSchema = Joi.object({
  name: Joi.string().trim().min(2).max(200),
  code: Joi.string().trim().max(50).allow(null, ''),
  isActive: Joi.boolean(),
}).min(1);

module.exports = {
  listWarehousesQuerySchema,
  createWarehouseSchema,
  updateWarehouseSchema,
};
