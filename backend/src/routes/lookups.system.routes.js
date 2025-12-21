const express = require('express');
const pool = require('../db/pool');
const { requireAuth } = require('../middlewares/auth');

const router = express.Router();

/**
 * GET /api/lookups/system-departments
 * Returns fixed system departments catalog
 */
router.get('/system-departments', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await pool.query(`
      SELECT
        id,
        code,
        name_ar,
        name_en,
        sort_order
      FROM system_departments
      WHERE is_active = true
      ORDER BY sort_order ASC
    `);

    const items = rows.map(r => ({
      id: r.id,
      code: r.code,
      name_ar: r.name_ar,
      name_en: r.name_en,
      label: r.name_ar, // ✅ UI-friendly
    }));

    return res.json({ ok: true, items });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
