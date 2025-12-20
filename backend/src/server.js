// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const facilityRoutes = require('./modules/facility/facility.routes');
const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');
const rolesRoutes = require('./modules/roles/roles.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ ok: true }));

app.use('/api/auth', authRoutes);
app.use('/api', meRoutes);
app.use('/api/roles', rolesRoutes);
app.use('/api/facility', facilityRoutes);

// Error handler (آخر شيء)
app.use((err, req, res, next) => {
  const status = err.status || 500;
  res.status(status).json({
    message: err.message || 'Server error',
    // اختياري للتشخيص: لا تكشف stack في الإنتاج
    ...(process.env.NODE_ENV !== 'production' && err.details ? { details: err.details } : {}),
  });
});

// ✅ تشخيص أخطاء غير ممسوكة (لا يغير اللوجك)
process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
});

const port = process.env.PORT || 8080;

// ✅ امسك server object للتشخيص
const server = app.listen(port, () => console.log(`API listening on :${port}`));

server.on('error', (err) => {
  console.error('❌ Server error:', err);
});

// ✅ إبقاء تتبع الخروج كما طلبت
process.on('exit', (code) => {
  console.log('🧯 Process exiting with code:', code);
});
