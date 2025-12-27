// src/middlewares/patientAuth.js
const jwt = require('jsonwebtoken');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

// ✅ Important: accept both secrets (patient-specific or fallback to staff secret)
const PATIENT_SECRET =
  process.env.PATIENT_JWT_ACCESS_SECRET ||
  process.env.JWT_ACCESS_SECRET ||
  mustEnv('JWT_ACCESS_SECRET');

function readBearer(req) {
  const h = req.headers?.authorization || req.headers?.Authorization;
  if (!h) return null;
  const s = String(h).trim();
  if (!s.toLowerCase().startsWith('bearer ')) return null;
  return s.slice(7).trim();
}

function requirePatientAuth(req, res, next) {
  try {
    const token = readBearer(req);
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    // ✅ verify token
    const payload = jwt.verify(token, PATIENT_SECRET);

    // ✅ enforce patient kind (if present)
    // Some tokens may not include kind (future-proof) so we allow missing kind.
    if (payload?.kind && payload.kind !== 'PATIENT') {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    // ✅ normalize "sub"
    const sub = payload?.sub;
    if (!sub) return res.status(401).json({ message: 'Unauthorized' });

    req.patientUser = payload; // {sub, kind, iat, exp, ...}
    return next();
  } catch (e) {
    // ✅ in non-production show reason for faster debugging
    if (process.env.NODE_ENV !== 'production') {
      return res.status(401).json({
        message: 'Unauthorized',
        reason: e?.message || String(e),
      });
    }
    return res.status(401).json({ message: 'Unauthorized' });
  }
}

module.exports = { requirePatientAuth };
