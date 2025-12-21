// src/modules/users/users.validators.js
const { z } = require('zod');

const DOCTOR_NURSE_ROLES = new Set(['DOCTOR', 'NURSE']);

const createUserSchema = z
  .object({
    fullName: z.string().min(2),
    email: z.string().email().optional().nullable(),
    phone: z.string().optional().nullable(),
    password: z.string().min(6),
    roles: z.array(z.string().min(2)).min(1),

    // ✅ NEW
    // إلزامي للطبيب/الممرض فقط (والباقي اختياري)
    departmentId: z.string().uuid().optional().nullable(),
  })
  .refine((d) => d.email || d.phone, {
    message: 'email or phone is required',
    path: ['email'],
  })
  .refine(
    (d) => {
      const rolesUpper = (d.roles || []).map((r) => String(r).toUpperCase().trim());
      const needsDept = rolesUpper.some((r) => DOCTOR_NURSE_ROLES.has(r));
      if (!needsDept) return true;
      return Boolean(d.departmentId);
    },
    {
      message: 'departmentId is required for DOCTOR/NURSE',
      path: ['departmentId'],
    }
  );

const setActiveSchema = z.object({
  isActive: z.boolean(),
});

module.exports = {
  createUserSchema,
  setActiveSchema,
};
