const express = require('express');

const warehousesRoutes = require('./warehouses/warehouses.routes');
const drugsRoutes = require('./drugs/drugs.routes');
const stockRoutes = require('./stock/stock.routes');
const stockRequestsRoutes = require('./stock_requests/stockRequests.routes');

const router = express.Router();

// ملاحظة: requireAuth ينحط بالـ app.js أو بالـ parent router عادة
// وإذا تحبه هنا، خلي فقط requireAuth بدون requireRole عام

router.use('/warehouses', warehousesRoutes);
router.use('/drugs', drugsRoutes);
router.use('/stock', stockRoutes);
router.use('/stock-requests', stockRequestsRoutes);

module.exports = router;
