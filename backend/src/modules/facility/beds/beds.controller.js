const svc = require('./beds.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function create(req, res, next) {
  try {
    const bed = await svc.createBed({ tenantId: tenantId(req), ...req.body });
    res.status(201).json({ data: bed });
  } catch (e) { next(e); }
}

async function list(req, res, next) {
  try {
    const roomId = req.query.roomId ? String(req.query.roomId) : undefined;
    const departmentId = req.query.departmentId ? String(req.query.departmentId) : undefined;
    const status = req.query.status ? String(req.query.status) : undefined;
    const active = req.query.active === undefined ? undefined : req.query.active === 'true';

    const beds = await svc.listBeds({ tenantId: tenantId(req), roomId, departmentId, status, active });
    res.json({ data: beds });
  } catch (e) { next(e); }
}

async function getOne(req, res, next) {
  try {
    const bed = await svc.getBed({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: bed });
  } catch (e) { next(e); }
}

async function update(req, res, next) {
  try {
    const bed = await svc.updateBed({ tenantId: tenantId(req), id: req.params.id, patch: req.body });
    res.json({ data: bed });
  } catch (e) { next(e); }
}

async function changeStatus(req, res, next) {
  try {
    const bed = await svc.changeBedStatus({
      tenantId: tenantId(req),
      id: req.params.id,
      nextStatus: req.body.status,
    });
    res.json({ data: bed });
  } catch (e) { next(e); }
}

async function remove(req, res, next) {
  try {
    const bed = await svc.softDeleteBed({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: bed });
  } catch (e) { next(e); }
}

module.exports = { create, list, getOne, update, changeStatus, remove };
