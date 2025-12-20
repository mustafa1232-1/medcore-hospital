// src/modules/users/users.validators.js
const { z } = require('zod');

const createUserSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email().optional().nullable(),
  phone: z.string().optional().nullable(),
  password: z.string().min(6),
  roles: z.array(z.string().min(2)).min(1),
}).refine((d) => d.email || d.phone, {
  message: 'email or phone is required',
  path: ['email'],
});

const setActiveSchema = z.object({
  isActive: z.boolean(),
});

module.exports = {
  createUserSchema,
  setActiveSchema,
};
