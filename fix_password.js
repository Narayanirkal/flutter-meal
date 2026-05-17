const { Pool } = require('D:/Meal-backend/node_modules/pg');

const pool = new Pool({
  user: 'Narayan',
  host: 'localhost',
  database: 'Meal',
  password: 'Narayan',
  port: 5432,
});

async function updatePassword() {
  try {
    const newHash = '$2b$10$rdVdUwJkTz1zyrbZ0X2dhu5WWdpGWGoEnrvBymNxMGnbrGH7pNeca'; // hash for 'rohit'
    const result = await pool.query(
      'UPDATE admins SET password = $1 WHERE phone_number = $2 RETURNING *',
      [newHash, '+917019244344']
    );
    console.log('Password updated successfully for admin:', result.rows[0].username);
  } catch (err) {
    console.error('Error updating password:', err);
  } finally {
    pool.end();
  }
}

updatePassword();
