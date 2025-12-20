// src/routes/me.routes.js
const express = require('express');
const { requireAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/me
router.get('/me', requireAuth, (req, res) => {
  // يرجع بيانات المستخدم المستخرجة من JWT
  res.json({ ok: true, user: req.user });
});

module.exports = router;
