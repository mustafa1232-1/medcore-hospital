// src/routes/me.routes.js
const express = require('express');
const pool = require('../db/pool');
const { requireAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/me
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user?.sub;
    const tenantId = req.user?.tenantId;

    if (!userId || !tenantId) {
      return res.status(401).json({ message: 'Unauthorized: invalid payload' });
    }

    // 1) user profile
    const userQ = await pool.query(
      `
      SELECT 
        id,
        tenant_id AS "tenantId",
        full_name AS "fullName",
        email,
        phone,
        is_active AS "isActive",
        created_at AS "createdAt"
      FROM users
      WHERE id = $1 AND tenant_id = $2
      LIMIT 1
      `,
      [userId, tenantId]
    );

    if (userQ.rowCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    // 2) roles
    const rolesQ = await pool.query(
      `
      SELECT r.name
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = $1
      ORDER BY r.name
      `,
      [userId]
    );

    const user = userQ.rows[0];
    const roles = rolesQ.rows.map((x) => x.name);

    return res.json({
      ok: true,
      user: {
        ...user,
        roles,
      },
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
