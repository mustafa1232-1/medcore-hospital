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
        u.id,
        u.tenant_id AS "tenantId",
        t.code      AS "tenantCode",
        u.staff_code AS "staffCode",
        u.full_name AS "fullName",
        u.email,
        u.phone,
        u.is_active AS "isActive"
      FROM users u
      JOIN tenants t ON t.id = u.tenant_id
      WHERE u.id = $1 AND u.tenant_id = $2
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
        id: u.id, // internal UUID (keep for backend ops)
        tenantId: u.tenantId, // internal UUID (keep)
        tenantCode: u.tenantCode, // ✅ UI-friendly facility code
        staffCode: u.staffCode, // ✅ UI-friendly staff code
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
