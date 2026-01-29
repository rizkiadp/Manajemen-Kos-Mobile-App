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
  connectionString: process.env.DATABASE_URL || `postgres://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}?sslmode=require`,
  ssl: true, // Shorthand for "require" and usually implies rejectUnauthorized: false in some cloud envs, but let's be safe:
  // ssl: { rejectUnauthorized: false } <-- Neon often needs this explicitly if CA not provided.
  // Let's stick to object but simpler:
});

// OVERRIDE for safety (some pg versions need object)
pool.options.ssl = { rejectUnauthorized: false, require: true };

// Debug tag
const CODE_VERSION = 'v1.0.5-FIX-SSL';

// Test connection
pool.on('connect', () => {
  console.log(`✅ [${CODE_VERSION}] Connected to PostgreSQL`);
});
pool.on('error', (err) => {
  console.error(`❌ [${CODE_VERSION}] Idle Client Error:`, err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
