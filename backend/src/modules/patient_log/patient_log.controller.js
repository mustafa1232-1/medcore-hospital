const svc = require('./patient_log.service');

function tenantId(req) {
  return req.user.tenantId;
}
function userId(req) {
  return req.user.id;
}

async function listByPatient(req, res, next) {
  try {
    const patientId = String(req.params.patientId);
    const admissionId = req.query.admissionId ? String(req.query.admissionId) : undefined;
    const limit = req.query.limit;
    const offset = req.query.offset;

    const out = await svc.listPatientLog({
      tenantId: tenantId(req),
      patientId,
      admissionId,
      limit,
      offset,
    });

    res.json({ data: out.items, meta: out.meta });
  } catch (e) {
    next(e);
  }
}

async function create(req, res, next) {
  try {
    const patientId = String(req.params.patientId);

    const row = await svc.createPatientLog({
      tenantId: tenantId(req),
      patientId,
      admissionId: req.body.admissionId || null,
      actorUserId: userId(req),
      eventType: req.body.eventType,
      message: req.body.message || null,
      meta: req.body.meta || {},
    });

    res.status(201).json({ data: row });
  } catch (e) {
    next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const row = await svc.getPatientLogEntry({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: row });
  } catch (e) {
    next(e);
  }
}

module.exports = { listByPatient, create, getOne };
