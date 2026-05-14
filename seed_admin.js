const { Pool } = require('d:/Meal-backend/node_modules/pg');
const bcrypt = require('d:/Meal-backend/node_modules/bcrypt');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'Meal',
  user: 'Narayan',
  password: 'Narayan',
});

(async () => {
  try {
    console.log('Deleting all admins...');
    await pool.query('DELETE FROM admins');

    console.log('Hashing password...');
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('654321', salt);

    console.log('Inserting new admin with 10-digit number...');
    const res = await pool.query(
      'INSERT INTO admins (id, phone_number, password, username) VALUES ($1, $2, $3, $4) RETURNING *',
      [1, '+917019244344', hashedPassword, 'admin']
    );

    console.log('Successfully inserted admin:');
    console.log(JSON.stringify(res.rows[0], null, 2));
  } catch (err) {
    console.error('Error:', err);
  } finally {
    pool.end();
  }
})();
