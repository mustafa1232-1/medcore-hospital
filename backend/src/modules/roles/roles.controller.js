// src/modules/roles/roles.controller.js
const rolesService = require('./roles.service');

async function listRoles(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    if (!tenantId) {
      return res.status(401).json({ message: 'Unauthorized: invalid payload' });
    }

    const roles = await rolesService.listRoles(tenantId);
    return res.json({ ok: true, roles });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listRoles };
