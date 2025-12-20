// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');
const rolesRoutes = require('./modules/roles/roles.routes');
const facilityRoutes = require('./modules/facility/facility.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/api/auth', authRoutes);
app.use('/api', meRoutes);
app.use('/api/roles', rolesRoutes);
app.use('/api/facility', facilityRoutes);

// Error handler (آخر شيء)
app.use((err, _req, res, _next) => {
  const status = err.status || 500;
  res.status(status).json({
    message: err.message || 'Server error',
    ...(process.env.NODE_ENV !== 'production' && err.details ? { details: err.details } : {}),
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
