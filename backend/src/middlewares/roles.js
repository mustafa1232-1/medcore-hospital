// src/middlewares/roles.js
const { HttpError } = require('../utils/httpError');

function roleNameOf(r) {
  if (!r) return '';
  if (typeof r === 'string') return r;
  if (typeof r === 'object' && r.name) return String(r.name);
  return '';
}

function normalize(name) {
  return String(name || '').toUpperCase().trim();
}

function requireRole(role) {
  const needed = normalize(role);

  return (req, _res, next) => {
    const rolesRaw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const roles = rolesRaw.map(roleNameOf).map(normalize).filter(Boolean);

    if (!roles.includes(needed)) {
      return next(new HttpError(403, 'Forbidden'));
    }

    return next();
  };
}

module.exports = { requireRole };
