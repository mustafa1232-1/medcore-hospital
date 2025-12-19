// src/modules/auth/auth.validators.js
const { z } = require('zod');

const registerTenantSchema = z.object({
  name: z.string().min(2),
  type: z.string().min(2),
  phone: z.string().optional().nullable(),
  email: z.string().email().optional().nullable(),

  adminFullName: z.string().min(2),
  adminEmail: z.string().email().optional().nullable(),
  adminPhone: z.string().optional().nullable(),
  adminPassword: z.string().min(6),
});

const loginSchema = z
  .object({
    tenantId: z.string().uuid(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    password: z.string().min(1),
  })
  .refine((d) => d.email || d.phone, {
    message: 'email or phone is required',
    path: ['email'],
  });

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

const logoutSchema = z.object({
  refreshToken: z.string().min(1),
});

// ✅ NEW: Change password (logged-in user)
const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6),
});

module.exports = {
  registerTenantSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  changePasswordSchema,
};
