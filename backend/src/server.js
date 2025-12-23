// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// Routes
const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');
const rolesRoutes = require('./modules/roles/roles.routes');
const facilityRoutes = require('./modules/facility/facility.routes');
const usersRoutes = require('./modules/users/users.routes');
const lookupsRoutes = require('./routes/lookups.routes');
const patientsRoutes = require('./modules/patients/patients.routes');
const admissionsRoutes = require('./modules/admissions/admissions.routes');
const bedHistoryRoutes = require('../modules/bed_history/bed_history.routes');
// ✅ NEW
const ordersRoutes = require('./modules/orders/orders.routes');
const tasksRoutes = require('./modules/tasks/tasks.routes');
const patientLogRoutes = require('./modules/patient_log/patient_log.routes');
const labResultsRoutes = require('./modules/lab_results/lab_results.routes');
const pharmacyRoutes = require('./modules/pharmacy/pharmacy.routes');
const medAdminRoutes = require('./modules/med_admin/med_admin.routes');
const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/api/auth', authRoutes);
app.use('/api', meRoutes); // contains /me
app.use('/api/roles', rolesRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/facility', facilityRoutes);
app.use('/api/lookups', lookupsRoutes);
app.use('/api/patients', patientsRoutes);
app.use('/api/admissions', admissionsRoutes);
app.use('/api', bedHistoryRoutes);
// ✅ Orders & Tasks
app.use('/api/orders', ordersRoutes);
app.use('/api/tasks', tasksRoutes);
app.use('/api', patientLogRoutes);
app.use('/api/lab-results', labResultsRoutes);
app.use('/api/med-admin', medAdminRoutes);
app.use('/api/pharmacy', pharmacyRoutes);
// 404 JSON
app.use((req, res) => {
  res.status(404).json({
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

// Error handler
app.use((err, _req, res, _next) => {
  const status = err.status || 500;

  const details =
    err.details && Array.isArray(err.details)
      ? err.details
      : undefined;

  res.status(status).json({
    message: err.message || 'Server error',
    ...(process.env.NODE_ENV !== 'production' && details ? { details } : {}),
  });
});

process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on :${port}`));
