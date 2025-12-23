const svc = require('./lab_results.service');

function tenantId(req) {
  return req.user.tenantId;
}
function userId(req) {
  return req.user.id || req.user.sub;
}

async function create(req, res, next) {
  try {
    const out = await svc.createLabResultTx({
      tenantId: tenantId(req),
      orderId: req.body.orderId,
      result: req.body.result,
      notes: req.body.notes,
      createdByUserId: userId(req),
      markOrderCompleted: req.body.markOrderCompleted,
    });

    res.status(201).json({ data: out });
  } catch (e) {
    next(e);
  }
}

async function list(req, res, next) {
  try {
    const out = await svc.listLabResults({
      tenantId: tenantId(req),
      query: req.query,
    });
    res.json(out);
  } catch (e) {
    next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const out = await svc.getLabResult({
      tenantId: tenantId(req),
      id: req.params.id,
    });
    res.json({ data: out });
  } catch (e) {
    next(e);
  }
}

module.exports = { create, list, getOne };
