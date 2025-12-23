const svc = require('./med_admin.service');

function tenantId(req) {
  return req.user.tenantId;
}
function userId(req) {
  return req.user.id || req.user.sub;
}

async function create(req, res, next) {
  try {
    const out = await svc.createMedicationAdminTx({
      tenantId: tenantId(req),
      orderId: req.body.orderId,
      scheduledAt: req.body.scheduledAt,
      giveNow: req.body.giveNow,
      status: req.body.status,
      notes: req.body.notes,
      administeredByUserId: userId(req),
      markOrderCompleted: req.body.markOrderCompleted,
    });

    res.status(201).json({ data: out });
  } catch (e) {
    next(e);
  }
}

async function list(req, res, next) {
  try {
    const out = await svc.listMedicationAdmins({ tenantId: tenantId(req), query: req.query });
    res.json(out);
  } catch (e) {
    next(e);
  }
}

async function getOne(req, res, next) {
  try {
    const out = await svc.getMedicationAdmin({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: out });
  } catch (e) {
    next(e);
  }
}

module.exports = { create, list, getOne };
