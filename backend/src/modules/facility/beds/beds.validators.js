const Joi = require('joi');

const BedStatus = [
  'AVAILABLE',
  'OCCUPIED',
  'CLEANING',
  'MAINTENANCE',
  'RESERVED',
  'OUT_OF_SERVICE',
];

const createBedSchema = Joi.object({
  roomId: Joi.string().uuid().required(),
  code: Joi.string().trim().min(2).max(80).required(),
  status: Joi.string().valid(...BedStatus).default('AVAILABLE'),
  notes: Joi.string().allow('', null).max(500).default(null),
  isActive: Joi.boolean().default(true),
});

const updateBedSchema = Joi.object({
  roomId: Joi.string().uuid(),
  code: Joi.string().trim().min(2).max(80),
  notes: Joi.string().allow('', null).max(500),
  isActive: Joi.boolean(),
}).min(1);

const changeStatusSchema = Joi.object({
  status: Joi.string().valid(...BedStatus).required(),
});

module.exports = { BedStatus, createBedSchema, updateBedSchema, changeStatusSchema };
