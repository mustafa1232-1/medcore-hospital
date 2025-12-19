// src/db/pool.js
require('dotenv').config();
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  throw new Error('Missing env: DATABASE_URL');
}

// Railway Postgres يحتاج SSL غالباً في الإنتاج
const isProd = process.env.NODE_ENV === 'production';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isProd ? { rejectUnauthorized: false } : false,
});

module.exports = pool;
