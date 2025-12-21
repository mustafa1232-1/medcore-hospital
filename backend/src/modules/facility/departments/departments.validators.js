// src/modules/facility/departments/departments.validators.js
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

// ✅ Activate department from system catalog
// ✅ defaults: roomsCount=1, bedsPerRoom=1 (user can change)
const activateDepartmentSchema = Joi.object({
  systemDepartmentId: Joi.string().uuid().required(),
  roomsCount: Joi.number().integer().min(1).default(1),
  bedsPerRoom: Joi.number().integer().min(1).default(1),
});

// ✅ NEW: transfer staff between departments
const transferStaffSchema = Joi.object({
  staffUserId: Joi.string().uuid().required(),
  toDepartmentId: Joi.string().uuid().required(),
});

// ✅ NEW: remove staff from department (set department_id = NULL)
const removeStaffSchema = Joi.object({
  staffUserId: Joi.string().uuid().required(),
});

module.exports = {
  createDepartmentSchema,
  updateDepartmentSchema,
  activateDepartmentSchema,

  // ✅ new
  transferStaffSchema,
  removeStaffSchema,
};
