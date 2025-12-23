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

  // ✅ REQUIRED: must assign a pharmacist
  pharmacistUserId: Joi.string().guid({ version: ['uuidv4', 'uuidv5'] }).required(),
});

const updateWarehouseSchema = Joi.object({
  name: Joi.string().trim().min(2).max(200),
  code: Joi.string().trim().max(50).allow(null, ''),
  isActive: Joi.boolean(),

  // (Optional) allow re-assign pharmacist later by admin if you want
  pharmacistUserId: Joi.string().guid({ version: ['uuidv4', 'uuidv5'] }),
}).min(1);

module.exports = {
  listWarehousesQuerySchema,
  createWarehouseSchema,
  updateWarehouseSchema,
};
