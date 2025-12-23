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

/**
 * ✅ يدعم:
 * requireRole('ADMIN')
 * requireRole('ADMIN', 'DOCTOR')
 * requireRole(['ADMIN', 'DOCTOR'])
 * requireRole(['PHARMACY','ADMIN'], 'DOCTOR')
 */
function requireRole(...required) {
  const flat = required.flat().filter(Boolean);
  const neededRoles = flat.map(normalize).filter(Boolean);

  // حماية لو تم استدعاؤه بدون أدوار (خطأ برمجي)
  if (neededRoles.length === 0) {
    return (_req, _res, next) =>
      next(new HttpError(500, 'Server misconfiguration: requireRole has no roles'));
  }

  return (req, _res, next) => {
    const rolesRaw = Array.isArray(req.user?.roles) ? req.user.roles : [];
    const userRoles = rolesRaw
      .map(roleNameOf)
      .map(normalize)
      .filter(Boolean);

    const allowed = neededRoles.some((r) => userRoles.includes(r));

    if (!allowed) {
      return next(new HttpError(403, 'Forbidden: insufficient role'));
    }

    return next();
  };
}

module.exports = { requireRole };
