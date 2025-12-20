const { HttpError } = require('./httpError');

function extractRoleName(role) {
  if (!role) return null;
  if (typeof role === 'string') return role;
  if (typeof role === 'object' && role.name) return role.name;
  return null;
}

function normalize(str) {
  return String(str || '').toLowerCase().trim();
}

function requirePermission(permission) {
  return (req, _res, next) => {
    const user = req.user || {};

    // 1️⃣ لو عندنا permissions صريحة داخل التوكن
    const permissions = Array.isArray(user.permissions) ? user.permissions : [];
    if (permissions.includes(permission)) {
      return next();
    }

    // 2️⃣ fallback على roles (وضعك الحالي)
    const rolesRaw = Array.isArray(user.roles) ? user.roles : [];
    const roles = rolesRaw
      .map(extractRoleName)
      .map(normalize)
      .filter(Boolean);

    const isAdmin =
      roles.includes('admin') ||
      roles.includes('owner') ||
      roles.includes('superadmin') ||
      roles.includes('super admin');

    if (isAdmin) {
      return next();
    }

    return next(new HttpError(403, 'Forbidden'));
  };
}

module.exports = { requirePermission };
