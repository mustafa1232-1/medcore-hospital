const Joi = require('joi');

const createRoomSchema = Joi.object({
  departmentId: Joi.string().uuid().required(),
  code: Joi.string().trim().min(2).max(50).required(),
  name: Joi.string().trim().min(1).max(120).required(),
  floor: Joi.number().integer().min(-5).max(200).allow(null).default(null),
  isActive: Joi.boolean().default(true),
});

const updateRoomSchema = Joi.object({
  departmentId: Joi.string().uuid(),
  code: Joi.string().trim().min(2).max(50),
  name: Joi.string().trim().min(1).max(120),
  floor: Joi.number().integer().min(-5).max(200).allow(null),
  isActive: Joi.boolean(),
}).min(1);

module.exports = { createRoomSchema, updateRoomSchema };
