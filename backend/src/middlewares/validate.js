const { HttpError } = require('../utils/httpError');

/**
 * Supports:
 * - Joi schemas: schema.validate()
 * - Zod schemas: schema.safeParse()
 */
function validateBody(schema) {
  return (req, _res, next) => {
    // ✅ Joi
    if (schema && typeof schema.validate === 'function') {
      const { value, error } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        const details = Array.isArray(error.details)
          ? error.details.map(d => d.message)
          : ['Validation error'];

        return next(new HttpError(400, 'Validation error', details));
      }

      req.body = value;
      return next();
    }

    // ✅ Zod
    if (schema && typeof schema.safeParse === 'function') {
      const result = schema.safeParse(req.body);

      if (!result.success) {
        // Zod v3/v4: issues (الأصح)، وبعض البيئات قد تستخدم errors
        const issues = result.error?.issues || result.error?.errors || [];
        const details = Array.isArray(issues) ? issues.map(e => e.message) : ['Validation error'];

        return next(new HttpError(400, 'Validation error', details));
      }

      req.body = result.data;
      return next();
    }

    // ❌ Unsupported schema
    return next(new HttpError(500, 'Invalid validation schema'));
  };
}

module.exports = { validateBody };
