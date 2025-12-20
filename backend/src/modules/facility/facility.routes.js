const express = require('express');

const departmentsRoutes = require('./departments/departments.routes');
const roomsRoutes = require('./rooms/rooms.routes');
const bedsRoutes = require('./beds/beds.routes');

const router = express.Router();

router.use('/departments', departmentsRoutes);
router.use('/rooms', roomsRoutes);
router.use('/beds', bedsRoutes);

module.exports = router;
