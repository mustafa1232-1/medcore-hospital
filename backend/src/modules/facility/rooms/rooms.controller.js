const svc = require('./rooms.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function create(req, res, next) {
  try {
    const room = await svc.createRoom({ tenantId: tenantId(req), ...req.body });
    res.status(201).json({ data: room });
  } catch (e) { next(e); }
}

async function list(req, res, next) {
  try {
    const departmentId = req.query.departmentId ? String(req.query.departmentId) : undefined;
    const q = req.query.query ? String(req.query.query) : undefined;
    const active = req.query.active === undefined ? undefined : req.query.active === 'true';
    const rooms = await svc.listRooms({ tenantId: tenantId(req), departmentId, q, active });
    res.json({ data: rooms });
  } catch (e) { next(e); }
}

async function getOne(req, res, next) {
  try {
    const room = await svc.getRoom({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: room });
  } catch (e) { next(e); }
}

async function update(req, res, next) {
  try {
    const room = await svc.updateRoom({ tenantId: tenantId(req), id: req.params.id, patch: req.body });
    res.json({ data: room });
  } catch (e) { next(e); }
}

async function remove(req, res, next) {
  try {
    const room = await svc.softDeleteRoom({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: room });
  } catch (e) { next(e); }
}

module.exports = { create, list, getOne, update, remove };
