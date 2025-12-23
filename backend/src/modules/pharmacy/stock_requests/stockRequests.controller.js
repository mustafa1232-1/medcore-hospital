const svc = require('./stockRequests.service');

function tenantId(req) {
  return req.user.tenantId;
}
function userId(req) {
  return req.user.sub;
}

async function list(req, res, next) {
  try {
    const out = await svc.listRequests({ tenantId: tenantId(req), query: req.query });
    return res.json(out);
  } catch (e) { return next(e); }
}

async function getOne(req, res, next) {
  try {
    const out = await svc.getRequestDetails({ tenantId: tenantId(req), id: req.params.id });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

async function create(req, res, next) {
  try {
    const out = await svc.createRequest({
      tenantId: tenantId(req),
      data: req.body,
      createdByUserId: userId(req),
    });
    return res.status(201).json({ data: out });
  } catch (e) { return next(e); }
}

async function addLine(req, res, next) {
  try {
    const out = await svc.addLine({
      tenantId: tenantId(req),
      requestId: req.params.id,
      data: req.body,
    });
    return res.status(201).json({ data: out });
  } catch (e) { return next(e); }
}

async function updateLine(req, res, next) {
  try {
    const out = await svc.updateLine({
      tenantId: tenantId(req),
      requestId: req.params.id,
      lineId: req.params.lineId,
      patch: req.body,
    });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

async function removeLine(req, res, next) {
  try {
    const out = await svc.removeLine({
      tenantId: tenantId(req),
      requestId: req.params.id,
      lineId: req.params.lineId,
    });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

async function submit(req, res, next) {
  try {
    const out = await svc.submitRequest({
      tenantId: tenantId(req),
      id: req.params.id,
      submittedByUserId: userId(req),
      notes: req.body?.notes,
    });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

async function approve(req, res, next) {
  try {
    const out = await svc.approveRequestTx({
      tenantId: tenantId(req),
      id: req.params.id,
      approvedByUserId: userId(req),
      notes: req.body?.notes,
    });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

async function reject(req, res, next) {
  try {
    const out = await svc.rejectRequest({
      tenantId: tenantId(req),
      id: req.params.id,
      approvedByUserId: userId(req),
      notes: req.body?.notes,
    });
    return res.json({ data: out });
  } catch (e) { return next(e); }
}

module.exports = {
  list,
  getOne,
  create,
  addLine,
  updateLine,
  removeLine,
  submit,
  approve,
  reject,
};
