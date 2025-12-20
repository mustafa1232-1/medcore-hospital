// src/modules/users/users.controller.js
const usersService = require('./users.service');
const passwordService = require('../auth/password.service'); // ✅ reuse the same service

async function listUsers(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    const { q, active, limit, offset } = req.query;

    const users = await usersService.listUsers({
      tenantId,
      q: q || undefined,
      active: active === undefined ? undefined : active === 'true',
      limit,
      offset,
    });

    return res.json({ ok: true, users });
  } catch (err) {
    return next(err);
  }
}

async function createUser(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;

    const user = await usersService.createUser({
      tenantId,
      ...req.body,
    });

    return res.status(201).json({ ok: true, user });
  } catch (err) {
    return next(err);
  }
}

async function setActive(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    const userId = req.params.id;

    const user = await usersService.setUserActive({
      tenantId,
      userId,
      isActive: req.body.isActive,
    });

    return res.json({ ok: true, user });
  } catch (err) {
    return next(err);
  }
}

// ✅ NEW: reset password (ADMIN)
async function resetPassword(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    const targetUserId = req.params.id;

    if (!tenantId) {
      return res.status(401).json({ message: 'Unauthorized: invalid payload' });
    }

    const { newPassword } = req.body;

    const result = await passwordService.adminResetPassword({
      tenantId,
      targetUserId,
      newPassword,
    });

    return res.json(result);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listUsers,
  createUser,
  setActive,
  resetPassword, // ✅ export
};
