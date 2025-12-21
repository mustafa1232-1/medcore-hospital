// src/modules/facility/departments/departments.controller.js
const svc = require('./departments.service');

function tenantId(req) {
  return req.user.tenantId;
}

function actor(req) {
  return {
    userId: req.user?.sub,
    tenantId: req.user?.tenantId,
    roles: Array.isArray(req.user?.roles) ? req.user.roles : [],
  };
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

// ✅ Activate department from system catalog
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

// ✅ Overview endpoint
async function overview(req, res, next) {
  try {
    const data = await svc.getDepartmentOverview({
      tenantId: tenantId(req),
      departmentId: req.params.id,
    });
    res.json({ ok: true, data });
  } catch (e) {
    next(e);
  }
}

// ✅ NEW: transfer staff
async function transferStaff(req, res, next) {
  try {
    const result = await svc.transferStaffBetweenDepartments({
      tenantId: tenantId(req),
      fromDepartmentId: req.params.id,
      staffUserId: req.body.staffUserId,
      toDepartmentId: req.body.toDepartmentId,
      actor: actor(req),
    });
    res.json({ ok: true, data: result });
  } catch (e) {
    next(e);
  }
}

// ✅ NEW: remove staff
async function removeStaff(req, res, next) {
  try {
    const result = await svc.removeStaffFromDepartment({
      tenantId: tenantId(req),
      departmentId: req.params.id,
      staffUserId: req.body.staffUserId,
      actor: actor(req),
    });
    res.json({ ok: true, data: result });
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
  overview,

  // ✅ new
  transferStaff,
  removeStaff,
};
