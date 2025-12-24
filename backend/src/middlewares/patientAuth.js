const jwt = require('jsonwebtoken');

function mustEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

// You can reuse JWT_ACCESS_SECRET, or (better) make a dedicated secret:
// PATIENT_JWT_ACCESS_SECRET
const PATIENT_JWT_ACCESS_SECRET = process.env.PATIENT_JWT_ACCESS_SECRET || mustEnv('JWT_ACCESS_SECRET');

function requirePatientAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) return res.status(401).json({ message: 'Unauthorized' });

    const payload = jwt.verify(token, PATIENT_JWT_ACCESS_SECRET);

    // ✅ Must be PATIENT token
    if (payload?.kind !== 'PATIENT' || !payload?.sub) {
      return res.status(401).json({ message: 'Unauthorized: invalid patient token' });
    }

    req.patientUser = payload; // keep separate from req.user
    return next();
  } catch {
    return res.status(401).json({ message: 'Unauthorized: invalid token' });
  }
}

module.exports = { requirePatientAuth };
