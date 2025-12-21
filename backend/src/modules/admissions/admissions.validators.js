const Joi = require('joi');

const createAdmissionSchema = Joi.object({
  patientId: Joi.string().uuid().required(),
  assignedDoctorUserId: Joi.string().uuid().allow(null).optional(),
  reason: Joi.string().allow('', null).max(500).default(null),
  notes: Joi.string().allow('', null).max(2000).default(null),
});

const updateAdmissionSchema = Joi.object({
  assignedDoctorUserId: Joi.string().uuid().allow(null),
  reason: Joi.string().allow('', null).max(500),
  notes: Joi.string().allow('', null).max(2000),
}).min(1);

const assignBedSchema = Joi.object({
  bedId: Joi.string().uuid().required(),
});

const closeAdmissionSchema = Joi.object({
  notes: Joi.string().allow('', null).max(2000).default(null),
});

module.exports = {
  createAdmissionSchema,
  updateAdmissionSchema,
  assignBedSchema,
  closeAdmissionSchema,
};
