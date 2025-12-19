require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./pool');

async function run() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        filename TEXT UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    const applied = await client.query(`SELECT filename FROM schema_migrations`);
    const appliedSet = new Set(applied.rows.map(r => r.filename));

    const dir = path.join(process.cwd(), 'migrations');
    if (!fs.existsSync(dir)) {
      throw new Error(`Migrations folder not found: ${dir}`);
    }

    const files = fs.readdirSync(dir).filter(f => f.endsWith('.sql')).sort();
    if (files.length === 0) {
      console.log('ℹ️ No migration files found.');
      return;
    }

    for (const file of files) {
      if (appliedSet.has(file)) {
        console.log(`↩️ Skipping ${file} (already applied)`);
        continue;
      }

      const filePath = path.join(dir, file);
      const sql = fs.readFileSync(filePath, 'utf8');

      console.log(`➡️ Applying ${file} (${sql.length} chars)`);

      if (!sql.trim()) {
        throw new Error(`Migration file is empty: ${file}`);
      }

      await client.query('BEGIN');
      await client.query(sql);
      await client.query(`INSERT INTO schema_migrations (filename) VALUES ($1)`, [file]);
      await client.query('COMMIT');
    }

    console.log('✅ Migrations completed');
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch {}
    console.error('❌ Migration failed:', e);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
