// src/modules/facility/departments/departments.activate.controller.js
const svc = require('./departments.activate.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function activate(req, res, next) {
  try {
    const result = await svc.activateDepartment({
      tenantId: tenantId(req),
      ...req.body,
    });

    res.status(201).json({ data: result });
  } catch (e) {
    next(e);
  }
}

module.exports = { activate };
