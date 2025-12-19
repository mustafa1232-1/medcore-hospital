// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');

const app = express();

// Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

// Health
app.get('/health', (req, res) => res.json({ ok: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api', meRoutes);

// 404 handler (اختياري لكنه مفيد)
app.use((req, res) => {
  res.status(404).json({ message: 'Not Found', path: req.path });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  const status = err.status || 500;
  res.status(status).json({
    message: err.message || 'Server error',
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on :${port}`));
