const { Pool } = require('d:/Meal-backend/node_modules/pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'Meal',
  user: 'Narayan',
  password: 'Narayan',
});

(async () => {
  try {
    const res = await pool.query(`
      SELECT column_name, data_type, character_maximum_length 
      FROM information_schema.columns 
      WHERE table_name = 'admins' AND column_name = 'phone_number';
    `);
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
})();
