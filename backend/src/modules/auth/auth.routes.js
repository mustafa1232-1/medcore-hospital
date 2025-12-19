const express = require('express');

const {
  registerTenantSchema,
  loginSchema,
  refreshSchema,
} = require('./auth.validators');

const {
  registerTenant,
  loginHandler,
  refreshHandler,
  logoutHandler,
} = require('./auth.controller');

const router = express.Router();

function wrap(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

function validate(schema) {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      return next();
    } catch (e) {
      return res.status(400).json({
        message: 'Validation error',
        issues: e.issues || e.errors || [],
      });
    }
  };
}

router.post('/register-tenant', validate(registerTenantSchema), wrap(registerTenant));
router.post('/login', validate(loginSchema), wrap(loginHandler));
router.post('/refresh', validate(refreshSchema), wrap(refreshHandler));
router.post('/logout', validate(refreshSchema), wrap(logoutHandler));

module.exports = router;
