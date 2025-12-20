// src/modules/auth/password.service.js
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool'); // ✅ FIX PATH

async function changeOwnPassword({ tenantId, userId, currentPassword, newPassword }) {
  const { rows, rowCount } = await pool.query(
    `
    SELECT password_hash AS "passwordHash", is_active AS "isActive"
    FROM users
    WHERE id = $1 AND tenant_id = $2
    LIMIT 1
    `,
    [userId, tenantId]
  );

  if (rowCount === 0) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }

  if (!rows[0].isActive) {
    const err = new Error('User is inactive');
    err.status = 403;
    throw err;
  }

  const ok = await bcrypt.compare(currentPassword, rows[0].passwordHash);
  if (!ok) {
    const err = new Error('Invalid current password');
    err.status = 400;
    throw err;
  }

  const newHash = await bcrypt.hash(newPassword, 10);

  await pool.query(
    `
    UPDATE users
    SET password_hash = $1
    WHERE id = $2 AND tenant_id = $3
    `,
    [newHash, userId, tenantId]
  );

  return { ok: true };
}

async function adminResetPassword({ tenantId, targetUserId, newPassword }) {
  const { rowCount } = await pool.query(
    `
    SELECT 1
    FROM users
    WHERE id = $1 AND tenant_id = $2
    LIMIT 1
    `,
    [targetUserId, tenantId]
  );

  if (rowCount === 0) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }

  const newHash = await bcrypt.hash(newPassword, 10);

  await pool.query(
    `
    UPDATE users
    SET password_hash = $1
    WHERE id = $2 AND tenant_id = $3
    `,
    [newHash, targetUserId, tenantId]
  );

  return { ok: true };
}

module.exports = {
  changeOwnPassword,
  adminResetPassword,
};
