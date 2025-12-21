const svc = require('./orders.service');

function tenantId(req) {
  return req.user.tenantId;
}

function userId(req) {
  return req.user.sub;
}

async function createMedication(req, res, next) {
  try {
    const payload = {
      medicationName: req.body.medicationName,
      dose: req.body.dose,
      route: req.body.route,
      frequency: req.body.frequency,
      duration: req.body.duration,
      startNow: req.body.startNow,
    };

    const result = await svc.createOrderTx({
      tenantId: tenantId(req),
      admissionId: req.body.admissionId,
      kind: 'MEDICATION',
      payload,
      notes: req.body.notes,
      createdByUserId: userId(req),
      doctorUserId: userId(req),
    });

    res.status(201).json({ data: result });
  } catch (e) { next(e); }
}

async function createLab(req, res, next) {
  try {
    const payload = {
      testName: req.body.testName,
      priority: req.body.priority,
      specimen: req.body.specimen,
    };

    const result = await svc.createOrderTx({
      tenantId: tenantId(req),
      admissionId: req.body.admissionId,
      kind: 'LAB',
      payload,
      notes: req.body.notes,
      createdByUserId: userId(req),
      doctorUserId: userId(req),
    });

    res.status(201).json({ data: result });
  } catch (e) { next(e); }
}

async function createProcedure(req, res, next) {
  try {
    const payload = {
      procedureName: req.body.procedureName,
      urgency: req.body.urgency,
    };

    const result = await svc.createOrderTx({
      tenantId: tenantId(req),
      admissionId: req.body.admissionId,
      kind: 'PROCEDURE',
      payload,
      notes: req.body.notes,
      createdByUserId: userId(req),
      doctorUserId: userId(req),
    });

    res.status(201).json({ data: result });
  } catch (e) { next(e); }
}

async function list(req, res, next) {
  try {
    // validators ستنظف query في routes
    const result = await svc.listOrders({
      tenantId: tenantId(req),
      query: req.query,
    });
    res.json(result);
  } catch (e) { next(e); }
}

async function getOne(req, res, next) {
  try {
    const order = await svc.getOrder({ tenantId: tenantId(req), id: req.params.id });
    res.json({ data: order });
  } catch (e) { next(e); }
}

async function cancel(req, res, next) {
  try {
    const order = await svc.cancelOrder({
      tenantId: tenantId(req),
      id: req.params.id,
      notes: req.body.notes,
    });
    res.json({ data: order });
  } catch (e) { next(e); }
}

module.exports = {
  createMedication,
  createLab,
  createProcedure,
  list,
  getOne,
  cancel,
};
