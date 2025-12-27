// src/middlewares/patientAuth.js
const jwt = require('jsonwebtoken');

function readBearer(req) {
  const h = req.headers?.authorization || req.headers?.Authorization;
  if (!h) return null;
  const s = String(h).trim();
  if (!s.toLowerCase().startsWith('bearer ')) return null;
  return s.slice(7).trim();
}

function requirePatientAuth(req, res, next) {
  const debug = String(req.headers['x-debug-auth'] || '') === '1';

  try {
    const token = readBearer(req);
    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    const secretsToTry = [
      process.env.PATIENT_JWT_ACCESS_SECRET,
      process.env.JWT_ACCESS_SECRET,
    ].filter(Boolean);

    let payload = null;
    let lastErr = null;

    for (const secret of secretsToTry) {
      try {
        payload = jwt.verify(token, secret);
        break;
      } catch (e) {
        lastErr = e;
      }
    }

    if (!payload) {
      if (debug) {
        return res.status(401).json({
          message: 'Unauthorized',
          reason: lastErr?.message || 'verify_failed',
          triedSecrets: secretsToTry.map((_, i) => `secret#${i + 1}`),
        });
      }
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (payload?.kind && payload.kind !== 'PATIENT') {
      return res.status(401).json({ message: 'Unauthorized', ...(debug ? { reason: 'wrong_kind' } : {}) });
    }

    if (!payload?.sub) {
      return res.status(401).json({ message: 'Unauthorized', ...(debug ? { reason: 'missing_sub' } : {}) });
    }

    req.patientUser = payload;
    return next();
  } catch (e) {
    if (debug) {
      return res.status(401).json({ message: 'Unauthorized', reason: e?.message || String(e) });
    }
    return res.status(401).json({ message: 'Unauthorized' });
  }
}

module.exports = { requirePatientAuth };
