require('dotenv').config();
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is missing in .env');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// اختياري: فحص اتصال عند التشغيل (يساعد بالتشخيص)
pool.on('error', (err) => {
  console.error('Unexpected PG pool error:', err);
});

module.exports = pool;
