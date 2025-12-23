// src/modules/pharmacy/stock/stock.controller.js
const svc = require('./stock.service');

function tenantId(req) {
  return req.user.tenantId;
}

async function balance(req, res, next) {
  try {
    const out = await svc.getBalance({
      tenantId: tenantId(req),
      query: req.query,
    });
    return res.json(out);
  } catch (e) {
    return next(e);
  }
}

async function ledger(req, res, next) {
  try {
    const out = await svc.getLedger({
      tenantId: tenantId(req),
      query: req.query,
    });
    return res.json(out);
  } catch (e) {
    return next(e);
  }
}

module.exports = { balance, ledger };
