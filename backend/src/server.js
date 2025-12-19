require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { requireAuth } = require('./middlewares/auth');
const authRoutes = require('./modules/auth/auth.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ ok: true }));
console.log('authRoutes typeof =', typeof authRoutes, 'keys=', authRoutes && Object.keys(authRoutes));

app.use('/api/auth', authRoutes);

// Error handler
app.use((err, req, res, next) => {
  const status = err.status || 500;
  res.status(status).json({
    message: err.message || 'Server error',
    
  });
  app.get('/api/me', requireAuth, (req, res) => {
  res.json({ ok: true, user: req.user });
});
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`API listening on :${port}`));
