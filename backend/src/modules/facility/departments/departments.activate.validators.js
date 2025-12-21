// src/modules/facility/departments/departments.activate.validators.js
const Joi = require('joi');

const activateDepartmentSchema = Joi.object({
  systemDepartmentId: Joi.string().uuid().required(),

  roomsCount: Joi.number()
    .integer()
    .min(1)
    .max(200)
    .required(),

  bedsPerRoom: Joi.number()
    .integer()
    .min(1)
    .max(50)
    .required(),

  floor: Joi.number()
    .integer()
    .min(-5)
    .max(200)
    .allow(null)
    .default(null),
});

module.exports = { activateDepartmentSchema };
