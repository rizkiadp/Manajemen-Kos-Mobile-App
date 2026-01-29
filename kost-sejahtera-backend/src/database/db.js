const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');

const envPath = path.resolve(process.cwd(), '.env');
console.log('📂 CWD:', process.cwd());
console.log('📄 Looking for .env at:', envPath);
console.log('   File exists?', fs.existsSync(envPath));

require('dotenv').config({ path: envPath });

// Debug environment loading
console.log('🔌 Database Config:');
console.log('   Host:', process.env.DB_HOST);
console.log('   User:', process.env.DB_USER);
console.log('   Db:', process.env.DB_NAME);
console.log('   Password set?', !!process.env.DB_PASSWORD);
console.log('   Pass Length:', process.env.DB_PASSWORD?.length);
console.log('   Trimmed Length:', process.env.DB_PASSWORD?.trim().length);
console.log('   First/Last Char:', process.env.DB_PASSWORD?.[0], process.env.DB_PASSWORD?.slice(-1));

const pool = new Pool({
  host: process.env.DB_HOST?.trim(),
  port: process.env.DB_PORT?.trim(),
  database: process.env.DB_NAME?.trim(),
  user: process.env.DB_USER?.trim(),
  password: process.env.DB_PASSWORD?.trim(),
  ssl: {
    rejectUnauthorized: false // Required for Neon/Render
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000, // Increased timeout
});

// Test connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
