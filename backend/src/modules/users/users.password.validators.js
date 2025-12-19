// src/modules/users/users.password.validators.js
const { z } = require('zod');

const adminResetPasswordSchema = z.object({
  newPassword: z.string().min(6),
});

module.exports = { adminResetPasswordSchema };
