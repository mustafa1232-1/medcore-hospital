// src/middlewares/validate.js
function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        message: 'Validation error',
        issues: result.error.issues,
      });
    }
    req.body = result.data;
    next();
  };
}

module.exports = { validateBody };
