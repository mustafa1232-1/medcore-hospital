const express = require('express');

const drugsRoutes = require('./drugs/drugs.routes');
const warehousesRoutes = require('./warehouses/warehouses.routes');
const stockRequestsRoutes = require('./stock_requests/stockRequests.routes');
const stockRoutes = require('./stock/stock.routes');

const router = express.Router();

router.use('/drugs', drugsRoutes);
router.use('/warehouses', warehousesRoutes);
router.use('/stock-requests', stockRequestsRoutes);
router.use('/stock', stockRoutes);

module.exports = router;
