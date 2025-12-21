const svc = require('./departments.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function create(req, res, next) {
  try {
    const dep = await svc.createDepartment({
      tenantId: tenantId(req),
      ...req.body,
    });
    res.status(201).json({ data: dep });
  } catch (e) {
    next(e);
  }
}

async function list(req, res, next) {
  try {
    const q = req.query.query ? String(req.query.query) : undefined;
    const active =
      req.query.active === undefined ? undefined : req.query.active === 'true';

    const deps = await svc.listDepartments({
      tenantId: tenantId(req),
      q,
      active,
    });
    res.json({ data: deps });
  } catch (e) {
    next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const dep = await svc.getDepartment({
      tenantId: tenantId(req),
      id: req.params.id,
    });
    res.json({ data: dep });
  } catch (e) {
    next(e);
  }
}

async function update(req, res, next) {
  try {
    const dep = await svc.updateDepartment({
      tenantId: tenantId(req),
      id: req.params.id,
      patch: req.body,
    });
    res.json({ data: dep });
  } catch (e) {
    next(e);
  }
}

async function remove(req, res, next) {
  try {
    const dep = await svc.softDeleteDepartment({
      tenantId: tenantId(req),
      id: req.params.id,
    });
    res.json({ data: dep });
  } catch (e) {
    next(e);
  }
}

// ✅ NEW
async function activate(req, res, next) {
  try {
    const dep = await svc.activateDepartmentFromSystemCatalog({
      tenantId: tenantId(req),
      systemDepartmentId: req.body.systemDepartmentId,
      roomsCount: req.body.roomsCount,
      bedsPerRoom: req.body.bedsPerRoom,
    });
    res.status(201).json({ data: dep });
  } catch (e) {
    next(e);
  }
}

module.exports = {
  create,
  list,
  getOne,
  update,
  remove,
  activate,
};
