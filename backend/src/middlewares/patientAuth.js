// src/middlewares/patientAuth.js
const jwt = require('jsonwebtoken');

function pickSecret() {
  // اجعل المصدر واحداً واضحاً
  const s =
    process.env.PATIENT_JWT_ACCESS_SECRET ||
    process.env.JWT_ACCESS_SECRET;

  if (!s) throw new Error('Missing JWT secret (PATIENT_JWT_ACCESS_SECRET or JWT_ACCESS_SECRET)');
  return s;
}

function readBearer(req) {
  const h = req.headers?.authorization || req.headers?.Authorization;
  if (!h) return null;
  const s = String(h).trim();
  if (!s.toLowerCase().startsWith('bearer ')) return null;
  return s.slice(7).trim();
}

function requirePatientAuth(req, res, next) {
  const token = readBearer(req);
  if (!token) return res.status(401).json({ message: 'Unauthorized', reason: 'Missing bearer token' });

  try {
    const secret = pickSecret();

    // ✅ قيّد الخوارزمية لتجنب أي اختلاف
    const payload = jwt.verify(token, secret, { algorithms: ['HS256'] });

    if (payload?.kind && payload.kind !== 'PATIENT') {
      return res.status(401).json({ message: 'Unauthorized', reason: 'Token kind is not PATIENT' });
    }

    const sub = payload?.sub;
    if (!sub) return res.status(401).json({ message: 'Unauthorized', reason: 'Missing sub in token' });

    req.patientUser = payload;
    return next();
  } catch (e) {
    // ✅ دائماً أظهر reason مؤقتاً لحين ما نغلق المشكلة
    return res.status(401).json({
      message: 'Unauthorized',
      reason: e?.message || String(e),
    });
  }
}

module.exports = { requirePatientAuth };
