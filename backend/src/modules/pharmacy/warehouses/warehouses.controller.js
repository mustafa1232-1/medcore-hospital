const svc = require('./warehouses.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function list(req, res, next) {
  try {
    const out = await svc.listWarehouses({
      tenantId: tenantId(req),
      query: req.query,
    });
    return res.json(out);
  } catch (e) {
    return next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const out = await svc.getWarehouse({
      tenantId: tenantId(req),
      id: req.params.id,
    });
    return res.json({ data: out });
  } catch (e) {
    return next(e);
  }
}

async function create(req, res, next) {
  try {
    const out = await svc.createWarehouse({
      tenantId: tenantId(req),
      data: req.body,
    });
    return res.status(201).json({ data: out });
  } catch (e) {
    return next(e);
  }
}

async function update(req, res, next) {
  try {
    const out = await svc.updateWarehouse({
      tenantId: tenantId(req),
      id: req.params.id,
      patch: req.body,
    });
    return res.json({ data: out });
  } catch (e) {
    return next(e);
  }
}

async function remove(req, res, next) {
  try {
    const out = await svc.softDeleteWarehouse({
      tenantId: tenantId(req),
      id: req.params.id,
    });
    return res.json({ data: out });
  } catch (e) {
    return next(e);
  }
}

module.exports = { list, getOne, create, update, remove };
