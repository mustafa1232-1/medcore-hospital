// src/modules/orders/orders.controller.js
const svc = require('./orders.service');

function tenantId(req) {
  return req.user.tenantId;
}

function userId(req) {
  return req.user.id || req.user.sub;
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

      // ✅ optional (new)
      drugId: req.body.drugId || null,
      requestedQty: req.body.requestedQty ?? null,

      patientInstructionsAr: req.body.patientInstructionsAr ?? null,
      patientInstructionsEn: req.body.patientInstructionsEn ?? null,
      dosageText: req.body.dosageText ?? null,
      frequencyText: req.body.frequencyText ?? null,
      durationText: req.body.durationText ?? null,
      withFood: req.body.withFood ?? null,
      warningsText: req.body.warningsText ?? null,
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
    const order = await svc.cancelOrderTx({
      tenantId: tenantId(req),
      id: req.params.id,
      notes: req.body.notes,
      cancelledByUserId: userId(req),
    });
    res.json({ data: order });
  } catch (e) { next(e); }
}

/** =========================
 * ✅ Pharmacy actions
 * ========================= */

async function pharmacyPrepare(req, res, next) {
  try {
    const out = await svc.pharmacyPrepareTx({
      tenantId: tenantId(req),
      orderId: req.params.id,
      actorUserId: userId(req),
      notes: req.body.notes,
    });
    res.json({ data: out });
  } catch (e) { next(e); }
}

async function pharmacyPartial(req, res, next) {
  try {
    const out = await svc.pharmacyPartialTx({
      tenantId: tenantId(req),
      orderId: req.params.id,
      preparedQty: req.body.preparedQty,
      actorUserId: userId(req),
      notes: req.body.notes,
    });
    res.json({ data: out });
  } catch (e) { next(e); }
}

async function pharmacyOutOfStock(req, res, next) {
  try {
    const out = await svc.pharmacyOutOfStockTx({
      tenantId: tenantId(req),
      orderId: req.params.id,
      actorUserId: userId(req),
      notes: req.body.notes,
    });
    res.json({ data: out });
  } catch (e) { next(e); }
}

/** =========================
 * ✅ Patient view (بدون status)
 * ========================= */
async function listPatientMedications(req, res, next) {
  try {
    const out = await svc.listPatientMedicationView({
      tenantId: tenantId(req),
      patientId: req.user.patientId, // إذا JWT للمريض يحتوي patientId
      limit: Number(req.query.limit || 50),
      offset: Number(req.query.offset || 0),
    });
    res.json(out);
  } catch (e) { next(e); }
}

module.exports = {
  createMedication,
  createLab,
  createProcedure,
  list,
  getOne,
  cancel,

  pharmacyPrepare,
  pharmacyPartial,
  pharmacyOutOfStock,

  listPatientMedications,
};
