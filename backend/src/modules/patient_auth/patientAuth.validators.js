const Joi = require('joi');

const registerSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(200).required(),
  email: Joi.string().email().optional().allow(null, ''),
  phone: Joi.string().trim().min(5).max(30).optional().allow(null, ''),
  password: Joi.string().min(6).max(200).required(),
}).custom((obj, helpers) => {
  if (!obj.email && !obj.phone) {
    return helpers.error('any.custom', { message: 'email or phone is required' });
  }
  return obj;
}, 'email/phone rule');

const loginSchema = Joi.object({
  email: Joi.string().email().optional().allow(null, ''),
  phone: Joi.string().trim().min(5).max(30).optional().allow(null, ''),
  password: Joi.string().min(1).max(200).required(),
}).custom((obj, helpers) => {
  if (!obj.email && !obj.phone) {
    return helpers.error('any.custom', { message: 'email or phone is required' });
  }
  return obj;
}, 'email/phone rule');

module.exports = { registerSchema, loginSchema };
