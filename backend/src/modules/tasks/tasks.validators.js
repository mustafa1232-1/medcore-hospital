const Joi = require('joi');

const listMyTasksQuerySchema = Joi.object({
  status: Joi.string().valid('PENDING', 'STARTED', 'COMPLETED', 'CANCELLED').optional(),
  limit: Joi.number().integer().min(1).max(100).default(30),
  offset: Joi.number().integer().min(0).max(1000000).default(0),
});

const startTaskSchema = Joi.object({}).unknown(false);
const completeTaskSchema = Joi.object({
  note: Joi.string().allow('', null).max(2000).default(null),
});
const cancelTaskSchema = Joi.object({
  note: Joi.string().allow('', null).max(2000).default(null),
});

module.exports = {
  listMyTasksQuerySchema,
  startTaskSchema,
  completeTaskSchema,
  cancelTaskSchema,
};
