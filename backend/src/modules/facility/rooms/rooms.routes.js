const express = require('express');
const { requireAuth } = require('../../../middlewares/auth');
const { requirePermission } = require('../../../utils/requirePermission');
const { validateBody } = require('../../../middlewares/validate');

const ctrl = require('./rooms.controller');
const { createRoomSchema, updateRoomSchema } = require('./rooms.validators');

const router = express.Router();

router.get('/', requireAuth, requirePermission('facility.read'), ctrl.list);
router.get('/:id', requireAuth, requirePermission('facility.read'), ctrl.getOne);

router.post('/', requireAuth, requirePermission('facility.write'), validateBody(createRoomSchema), ctrl.create);
router.patch('/:id', requireAuth, requirePermission('facility.write'), validateBody(updateRoomSchema), ctrl.update);
router.delete('/:id', requireAuth, requirePermission('facility.write'), ctrl.remove);

module.exports = router;
