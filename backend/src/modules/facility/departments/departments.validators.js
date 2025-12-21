const Joi = require('joi');

const createDepartmentSchema = Joi.object({
  code: Joi.string().trim().min(2).max(50).optional().allow(null, ''),
  name: Joi.string().trim().min(2).max(120).required(),
  isActive: Joi.boolean().default(true),
});

const updateDepartmentSchema = Joi.object({
  code: Joi.string().trim().min(2).max(50),
  name: Joi.string().trim().min(2).max(120),
  isActive: Joi.boolean(),
}).min(1);

// ✅ NEW: activate department from system catalog
const activateDepartmentSchema = Joi.object({
  systemDepartmentId: Joi.string().uuid().required(),
  roomsCount: Joi.number().integer().min(1).required(),
  bedsPerRoom: Joi.number().integer().min(1).required(),
});

module.exports = {
  createDepartmentSchema,
  updateDepartmentSchema,
  activateDepartmentSchema,
};
