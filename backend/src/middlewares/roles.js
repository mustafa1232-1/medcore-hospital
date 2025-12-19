// src/middlewares/roles.js

function requireRole(...allowed) {
  const allowedSet = new Set(allowed);

  return (req, res, next) => {
    const roles = req.user?.roles || [];

    const ok = roles.some((r) => allowedSet.has(r));
    if (!ok) {
      return res.status(403).json({ message: 'Forbidden: insufficient role' });
    }

    return next();
  };
}

module.exports = { requireRole };
