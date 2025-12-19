// src/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./modules/auth/auth.routes');
const meRoutes = require('./routes/me.routes');

// إذا عندك usersRoutes وتريدها، اترك السطر التالي.
// const usersRoutes = require('./modules/users/users.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ ok: true }));

app.use('/api/auth', authRoutes);
app.use('/api', meRoutes);

// إذا مفعل users:
// app.use('/api/users', usersRoutes);

app.use((err, req, res, next) => {
  const status = err.status || 500;
  res.status(status).json({ message: err.message || 'Server error' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on :${port}`));
