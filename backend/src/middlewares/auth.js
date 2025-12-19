// src/middlewares/auth.js
const jwt = require('jsonwebtoken');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

const JWT_ACCESS_SECRET = mustEnv('JWT_ACCESS_SECRET');

function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const payload = jwt.verify(token, JWT_ACCESS_SECRET);

    // payload يحتوي sub + tenantId + roles + iat + exp
    req.user = payload;

    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Unauthorized: invalid token' });
  }
}

module.exports = { requireAuth };
