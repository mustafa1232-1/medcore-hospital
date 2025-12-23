// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const crypto = require('crypto');

const app = express();

// ==========================
// Core runtime settings
// ==========================
// Important behind proxies (Railway/Render/Nginx). Enables correct req.ip, secure cookies, etc.
app.set('trust proxy', 1);

// ==========================
// Middleware
// ==========================
app.use(helmet());

// CORS (keep permissive default like current behavior)
// Optionally restrict via CORS_ORIGINS="https://a.com,https://b.com"
const corsOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: corsOrigins.length ? corsOrigins : true,
    credentials: true,
  })
);

// Body parsing
app.use(express.json({ limit: process.env.JSON_LIMIT || '1mb' }));

// Request ID (for tracing)
app.use((req, res, next) => {
  const rid = req.headers['x-request-id'] || crypto.randomUUID();
  req.requestId = rid;
  res.setHeader('x-request-id', rid);
  next();
});

// Logging
app.use(
  morgan(':method :url :status :res[content-length] - :response-time ms - rid=:req[x-request-id]')
);

// ==========================
// Health
// ==========================
app.get('/health', (_req, res) => res.json({ ok: true }));

// ==========================
// Routes
// ==========================
const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');
const rolesRoutes = require('./modules/roles/roles.routes');
const facilityRoutes = require('./modules/facility/facility.routes');
const usersRoutes = require('./modules/users/users.routes');
const lookupsRoutes = require('./routes/lookups.routes');
const patientsRoutes = require('./modules/patients/patients.routes');
const admissionsRoutes = require('./modules/admissions/admissions.routes');
const bedHistoryRoutes = require('./modules/bed_history/bed_history.routes');

// New modules
const ordersRoutes = require('./modules/orders/orders.routes');
const tasksRoutes = require('./modules/tasks/tasks.routes');
const patientLogRoutes = require('./modules/patient_log/patient_log.routes');
const labResultsRoutes = require('./modules/lab_results/lab_results.routes');
const pharmacyRoutes = require('./modules/pharmacy/pharmacy.routes');
const medAdminRoutes = require('./modules/med_admin/med_admin.routes');

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api', meRoutes); // contains /me
app.use('/api/roles', rolesRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/facility', facilityRoutes);
app.use('/api/lookups', lookupsRoutes);

app.use('/api/patients', patientsRoutes);
app.use('/api/admissions', admissionsRoutes);
app.use('/api/bed-history', bedHistoryRoutes);

app.use('/api/orders', ordersRoutes);
app.use('/api/tasks', tasksRoutes);
app.use('/api', patientLogRoutes); // keep as-is (module decides paths)
app.use('/api/lab-results', labResultsRoutes);
app.use('/api/med-admin', medAdminRoutes);
app.use('/api/pharmacy', pharmacyRoutes);

// ==========================
// 404
// ==========================
app.use((req, res) => {
  res.status(404).json({
    message: `Route not found: ${req.method} ${req.originalUrl}`,
    requestId: req.requestId,
  });
});

// ==========================
// Error handler
// ==========================
app.use((err, req, res, _next) => {
  const status = err.status || 500;

  const details =
    err.details && Array.isArray(err.details) ? err.details : undefined;

  const payload = {
    message: err.message || 'Server error',
    requestId: req.requestId,
  };

  if (process.env.NODE_ENV !== 'production') {
    if (details) payload.details = details;
    if (err.stack) payload.stack = err.stack;
  }

  res.status(status).json(payload);
});

// ==========================
// Process-level safety logs
// ==========================
process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
});

// ==========================
// Listen
// ==========================
const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on :${port}`));
