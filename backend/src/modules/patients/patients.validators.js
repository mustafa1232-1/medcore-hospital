// src/modules/patients/patients.validators.js
const Joi = require('joi');

const createPatientSchema = Joi.object({
  fullName: Joi.string().min(2).max(200).required(),

  phone: Joi.string().min(5).max(30).optional().allow(null, ''),
  email: Joi.string().email().optional().allow(null, ''),

  gender: Joi.string().valid('MALE', 'FEMALE', 'OTHER').optional().allow(null, ''),

  dateOfBirth: Joi.date().iso().optional().allow(null, ''),

  nationalId: Joi.string().max(50).optional().allow(null, ''),

  address: Joi.string().max(500).optional().allow(null, ''),

  notes: Joi.string().max(2000).optional().allow(null, ''),
});

const updatePatientSchema = Joi.object({
  fullName: Joi.string().min(2).max(200).optional(),

  phone: Joi.string().min(5).max(30).optional().allow(null, ''),
  email: Joi.string().email().optional().allow(null, ''),

  gender: Joi.string().valid('MALE', 'FEMALE', 'OTHER').optional().allow(null, ''),

  dateOfBirth: Joi.date().iso().optional().allow(null, ''),

  nationalId: Joi.string().max(50).optional().allow(null, ''),

  address: Joi.string().max(500).optional().allow(null, ''),

  notes: Joi.string().max(2000).optional().allow(null, ''),
}).min(1);

module.exports = { createPatientSchema, updatePatientSchema };
