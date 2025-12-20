// src/routes/me.routes.js
const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth } = require('../middlewares/auth');

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.sub;
    const tenantId = req.user?.tenantId;
    const roles = req.user?.roles || [];

    if (!userId || !tenantId) {
      return res.status(401).json({ message: 'Unauthorized: invalid payload' });
    }

    const q = await pool.query(
      `
      SELECT
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone,
        is_active AS "isActive"
      FROM users
      WHERE id = $1 AND tenant_id = $2
      LIMIT 1
      `,
      [userId, tenantId]
    );

    if (q.rowCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const u = q.rows[0];

    return res.json({
      ok: true,
      user: {
        id: u.id,
        tenantId: u.tenantId,
        fullName: u.fullName,
        email: u.email,
        phone: u.phone,
        roles,
        isActive: u.isActive,
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
