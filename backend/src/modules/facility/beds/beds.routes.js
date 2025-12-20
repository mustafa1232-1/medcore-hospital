const express = require('express');
const { requireAuth } = require('../../../middlewares/auth');
const { requirePermission } = require('../../../utils/requirePermission');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./beds.controller');
const { createBedSchema, updateBedSchema, changeStatusSchema } = require('./beds.validators');

const router = express.Router();

router.get('/', requireAuth, requirePermission('facility.read'), ctrl.list);
router.get('/:id', requireAuth, requirePermission('facility.read'), ctrl.getOne);

router.post('/', requireAuth, requirePermission('facility.write'), validateBody(createBedSchema), ctrl.create);
router.patch('/:id', requireAuth, requirePermission('facility.write'), validateBody(updateBedSchema), ctrl.update);

router.post('/:id/status', requireAuth, requirePermission('facility.write'), validateBody(changeStatusSchema), ctrl.changeStatus);

router.delete('/:id', requireAuth, requirePermission('facility.write'), ctrl.remove);

module.exports = router;
