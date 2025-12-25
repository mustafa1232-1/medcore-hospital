const svc = require('./admissions.service');

function tenantId(req) {
  return req.user.tenantId;
}

function userId(req) {
  return req.user.sub; // ✅ مهم (كما في me.routes.js)
}

async function list(req, res, next) {
  try {
    const result = await svc.listAdmissions({ tenantId: tenantId(req), query: req.query });
    res.json(result);
  } catch (e) { next(e); }
}

async function create(req, res, next) {
  try {
    const admission = await svc.createAdmission({
      tenantId: tenantId(req),
      createdByUserId: userId(req),
      ...req.body,
    });
    res.status(201).json({ data: admission });
  } catch (e) { next(e); }
}

// ✅ NEW: Outpatient visit by doctor (ACTIVE immediately, no bed)
async function createOutpatient(req, res, next) {
  try {
    const admission = await svc.createOutpatientVisit({
      tenantId: tenantId(req),
      createdByUserId: userId(req),
      patientId: req.body.patientId,
      notes: req.body.notes,
    });
    res.status(201).json({ data: admission });
  } catch (e) { next(e); }
}

// ✅ NEW: get active admission for patient
async function getActiveForPatient(req, res, next) {
  try {
    const patientId = String(req.query.patientId || '').trim();
    if (!patientId) throw new HttpError(400, 'patientId required');

    const result = await svc.getActiveAdmissionForPatient({
      tenantId: tenantId(req),
      patientId,
    });
    res.json({ data: result });
  } catch (e) { next(e); }
}

async function getOne(req, res, next) {
  try {
    const admission = await svc.getAdmissionDetails({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: admission });
  } catch (e) { next(e); }
}

async function update(req, res, next) {
  try {
    const admission = await svc.updateAdmission({
      tenantId: tenantId(req),
      id: req.params.id,
      patch: req.body,
    });
    res.json({ data: admission });
  } catch (e) { next(e); }
}

async function assignBed(req, res, next) {
  try {
    const result = await svc.assignBedToAdmission({
      tenantId: tenantId(req),
      admissionId: req.params.id,
      bedId: req.body.bedId,
      assignedByUserId: userId(req),
    });
    res.json({ data: result });
  } catch (e) { next(e); }
}

async function releaseBed(req, res, next) {
  try {
    const result = await svc.releaseBedFromAdmission({
      tenantId: tenantId(req),
      admissionId: req.params.id,
    });
    res.json({ data: result });
  } catch (e) { next(e); }
}

async function discharge(req, res, next) {
  try {
    const admission = await svc.dischargeAdmission({
      tenantId: tenantId(req),
      admissionId: req.params.id,
      notes: req.body.notes,
    });
    res.json({ data: admission });
  } catch (e) { next(e); }
}

async function cancel(req, res, next) {
  try {
    const admission = await svc.cancelAdmission({
      tenantId: tenantId(req),
      admissionId: req.params.id,
      notes: req.body.notes,
    });
    res.json({ data: admission });
  } catch (e) { next(e); }
}

module.exports = {
  list,
  create,
  createOutpatient,     // ✅ new
  getActiveForPatient,  // ✅ new
  getOne,
  update,
  assignBed,
  releaseBed,
  discharge,
  cancel,
};
