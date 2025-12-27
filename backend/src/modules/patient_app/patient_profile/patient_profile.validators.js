const Joi = require('joi');

const allergyItem = Joi.object({
  drugName: Joi.string().trim().min(1).max(120).required(),
  reaction: Joi.string().trim().max(200).optional().allow(null, ''),
  severity: Joi.string().valid('LOW', 'MEDIUM', 'HIGH').optional().allow(null, ''),
});

const patchProfileSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(200).optional(),
  dateOfBirth: Joi.date().iso().optional().allow(null, ''),
  gender: Joi.string().valid('MALE', 'FEMALE', 'OTHER').optional().allow(null, ''),

  maritalStatus: Joi.string().valid('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED')
    .optional()
    .allow(null, ''),
  childrenCount: Joi.number().integer().min(0).max(30).optional().allow(null),

  phone: Joi.string().trim().min(5).max(30).optional().allow(null, ''),
  emergencyPhone: Joi.string().trim().min(5).max(30).optional().allow(null, ''),
  emergencyRelation: Joi.string().trim().max(60).optional().allow(null, ''),
  emergencyContactName: Joi.string().trim().max(120).optional().allow(null, ''),

  chronicConditions: Joi.array().items(Joi.string().trim().min(1).max(120)).optional(),
  chronicMedications: Joi.array().items(Joi.string().trim().min(1).max(120)).optional(),
  drugAllergies: Joi.array().items(allergyItem).optional(),

  governorate: Joi.string().trim().max(120).optional().allow(null, ''),
  area: Joi.string().trim().max(120).optional().allow(null, ''),
  addressDetails: Joi.string().trim().max(500).optional().allow(null, ''),

  locationLat: Joi.number().min(-90).max(90).optional().allow(null),
  locationLng: Joi.number().min(-180).max(180).optional().allow(null),

  primaryDoctorName: Joi.string().trim().max(120).optional().allow(null, ''),
  primaryDoctorPhone: Joi.string().trim().max(30).optional().allow(null, ''),

  bloodType: Joi.string()
    .valid('A+','A-','B+','B-','AB+','AB-','O+','O-')
    .optional()
    .allow(null, ''),
  heightCm: Joi.number().integer().min(30).max(250).optional().allow(null),
  weightKg: Joi.number().integer().min(2).max(500).optional().allow(null),
}).min(1);

module.exports = { patchProfileSchema };
