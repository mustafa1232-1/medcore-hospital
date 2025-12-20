const { HttpError } = require('../utils/httpError');

/**
 * Supports:
 * - Joi schemas (schema.validate)
 * - Zod schemas (schema.safeParse)
 */
function validateBody(schema) {
  return (req, _res, next) => {
    // 🟢 Joi
    if (typeof schema.validate === 'function') {
      const { value, error } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return next(
          new HttpError(
            400,
            'Validation error',
            error.details.map(d => d.message)
          )
        );
      }

      req.body = value;
      return next();
    }

    // 🔵 Zod
    if (typeof schema.safeParse === 'function') {
      const result = schema.safeParse(req.body);

      if (!result.success) {
        return next(
          new HttpError(
            400,
            'Validation error',
            result.error.errors.map(e => e.message)
          )
        );
      }

      req.body = result.data;
      return next();
    }

    // 🔴 Unsupported schema
    return next(new HttpError(500, 'Invalid validation schema'));
  };
}

module.exports = { validateBody };
