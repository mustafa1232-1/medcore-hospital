const { HttpError } = require('./httpError');

function validateBody(schema) {
  return (req, _res, next) => {
    const { value, error } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
      return next(new HttpError(400, 'Validation error', error.details.map(d => d.message)));
    }
    req.body = value;
    next();
  };
}

module.exports = { validateBody };
