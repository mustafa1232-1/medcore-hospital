const Joi = require('joi');

const createDepartmentSchema = Joi.object({
  // ✅ أصبح اختياري: إذا لم يُرسل سنولده في service
  code: Joi.string().trim().min(2).max(50).optional().allow(null, ''),
  name: Joi.string().trim().min(2).max(120).required(),
  isActive: Joi.boolean().default(true),
});

const updateDepartmentSchema = Joi.object({
  code: Joi.string().trim().min(2).max(50),
  name: Joi.string().trim().min(2).max(120),
  isActive: Joi.boolean(),
}).min(1);

module.exports = { createDepartmentSchema, updateDepartmentSchema };
