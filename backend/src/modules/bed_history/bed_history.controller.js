const svc = require('./bed_history.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function listByBed(req, res, next) {
  try {
    const bedId = String(req.params.bedId);
    const limit = req.query.limit;
    const offset = req.query.offset;

    const data = await svc.listBedHistory({ tenantId: tenantId(req), bedId, limit, offset });
    res.json({ data: data.items, meta: data.meta });
  } catch (e) {
    next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const data = await svc.getBedHistoryEntry({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data });
  } catch (e) {
    next(e);
  }
}

module.exports = { listByBed, getOne };
