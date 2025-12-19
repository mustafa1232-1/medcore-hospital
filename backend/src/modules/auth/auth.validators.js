const { z } = require('zod');

const tenantTypes = ['HOSPITAL', 'CLINIC', 'PHARMACY', 'LAB', 'STORE'];

const registerTenantSchema = z.object({
  name: z.string().min(2),
  type: z.enum(tenantTypes),
  phone: z.string().min(7).optional(),
  email: z.string().email().optional(),

  adminFullName: z.string().min(2),
  adminEmail: z.string().email().optional(),
  adminPhone: z.string().min(7).optional(),
  adminPassword: z.string().min(8),
}).refine((v) => v.adminEmail || v.adminPhone, {
  message: 'adminEmail أو adminPhone مطلوب',
  path: ['adminEmail'],
});

const loginSchema = z.object({
  tenantId: z.string().uuid(),
  email: z.string().email().optional(),
  phone: z.string().min(7).optional(),
  password: z.string().min(1),
}).refine((v) => v.email || v.phone, {
  message: 'email أو phone مطلوب',
  path: ['email'],
});

const refreshSchema = z.object({
  refreshToken: z.string().min(20),
});

module.exports = {
  registerTenantSchema,
  loginSchema,
  refreshSchema,
};
