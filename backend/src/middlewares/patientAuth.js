// src/middlewares/patientAuth.js
const jwt = require('jsonwebtoken');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

// الأفضل: Secret مستقل للمرضى
// إذا لم يوجد، نرجع للـ JWT_ACCESS_SECRET (للتوافق)
const PATIENT_JWT_ACCESS_SECRET =
  process.env.PATIENT_JWT_ACCESS_SECRET || mustEnv('JWT_ACCESS_SECRET');

// (اختياري) لو تريد تضيف issuer/audience لاحقاً بدون كسر
const PATIENT_JWT_ISSUER = process.env.PATIENT_JWT_ISSUER || null;
const PATIENT_JWT_AUDIENCE = process.env.PATIENT_JWT_AUDIENCE || null;

function _extractBearerToken(req) {
  // Normal: Authorization: Bearer <token>
  const header = req.headers.authorization || req.headers.Authorization || '';
  if (typeof header === 'string' && header.startsWith('Bearer ')) {
    return header.slice(7).trim();
  }

  // Optional fallback for local testing only:
  // /path?accessToken=...  or  /path?token=...
  const qToken = req.query?.accessToken || req.query?.token;
  if (qToken && typeof qToken === 'string') return qToken.trim();

  return null;
}

function requirePatientAuth(req, res, next) {
  try {
    const token = _extractBearerToken(req);
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    const verifyOptions = {};

    // لا تفعلها إلا إذا فعلاً ستستخدم issuer/audience في التوكن عند الإصدار
    if (PATIENT_JWT_ISSUER) verifyOptions.issuer = PATIENT_JWT_ISSUER;
    if (PATIENT_JWT_AUDIENCE) verifyOptions.audience = PATIENT_JWT_AUDIENCE;

    const payload = jwt.verify(token, PATIENT_JWT_ACCESS_SECRET, verifyOptions);

    // ✅ Must be PATIENT token
    if (payload?.kind !== 'PATIENT' || !payload?.sub) {
      return res
        .status(401)
        .json({ message: 'Unauthorized: invalid patient token' });
    }

    // نخليها منفصلة عن staff token
    req.patientUser = payload;
    return next();
  } catch (err) {
    // لا نكشف التفاصيل في production
    return res.status(401).json({ message: 'Unauthorized: invalid token' });
  }
}

module.exports = { requirePatientAuth };
