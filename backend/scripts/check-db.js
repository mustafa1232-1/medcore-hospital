require('dotenv').config();
const pool = require('../src/db/pool');

(async () => {
  try {
    const r = await pool.query("select to_regclass('public.tenants') as t");
    console.log(r.rows[0]);
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
})();
