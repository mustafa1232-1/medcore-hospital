const Joi = require('joi');

const createDepartmentSchema = Joi.object({
  // ✅ Fixed catalog activation (no free-text names)
  // One of these must be sent:
  // - systemDepartmentId
  // - systemDepartmentCode (e.g., ER, ICU)
  systemDepartmentId: Joi.string().guid({ version: 'uuidv4' }).optional(),
  systemDepartmentCode: Joi.string().trim().min(2).max(30).optional(),

  // layout settings (required by business, enforced here)
  roomsCount: Joi.number().integer().min(1).max(500).required(),
  bedsPerRoom: Joi.number().integer().min(1).max(50).required(),

  isActive: Joi.boolean().default(true),
}).xor('systemDepartmentId', 'systemDepartmentCode');

const updateDepartmentSchema = Joi.object({
  // Only allow toggling + (optional) updating stored layout numbers.
  // NOTE: This does NOT auto-create rooms/beds. That is handled at activation time.
  isActive: Joi.boolean(),
  roomsCount: Joi.number().integer().min(0).max(500),
  bedsPerRoom: Joi.number().integer().min(0).max(50),
}).min(1);

module.exports = { createDepartmentSchema, updateDepartmentSchema };
