const express = require('express');
const { requireAuth } = require('../../../middlewares/auth');
const { requirePermission } = require('../../../utils/requirePermission');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./departments.controller');
const { createDepartmentSchema, updateDepartmentSchema } = require('./departments.validators');

const router = express.Router();

router.get('/', requireAuth, requirePermission('facility.read'), ctrl.list);
router.get('/:id', requireAuth, requirePermission('facility.read'), ctrl.getOne);

router.post('/', requireAuth, requirePermission('facility.write'), validateBody(createDepartmentSchema), ctrl.create);
router.patch('/:id', requireAuth, requirePermission('facility.write'), validateBody(updateDepartmentSchema), ctrl.update);
router.delete('/:id', requireAuth, requirePermission('facility.write'), ctrl.remove);

module.exports = router;
