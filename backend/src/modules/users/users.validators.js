// src/modules/users/users.validators.js
const { z } = require('zod');

const listUsersQuerySchema = z.object({
  q: z.string().optional(),
  active: z.enum(['true', 'false']).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

const createUserSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email().optional().nullable(),
  phone: z.string().optional().nullable(),
  password: z.string().min(6),
  roles: z.array(z.string().min(2)).min(1), // e.g. ["DOCTOR"] or ["NURSE"]
}).refine((d) => d.email || d.phone, {
  message: 'email or phone is required',
  path: ['email'],
});

const setActiveSchema = z.object({
  isActive: z.boolean(),
});

module.exports = {
  listUsersQuerySchema,
  createUserSchema,
  setActiveSchema,
};
