// src/modules/users/users.department.validators.js
const { z } = require('zod');

const updateUserDepartmentSchema = z.object({
  // null => remove from department
  departmentId: z.string().uuid().nullable().optional(),
});

module.exports = {
  updateUserDepartmentSchema,
};
