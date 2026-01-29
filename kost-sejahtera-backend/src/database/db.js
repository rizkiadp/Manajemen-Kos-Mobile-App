/**
 * PostgreSQL connection (Neon compatible)
 * Environment: Local + Vercel
 */

const { Pool } = require("pg");
const path = require("path");
const fs = require("fs");

// Load .env ONLY for local development
const envPath = path.resolve(process.cwd(), ".env");
if (fs.existsSync(envPath)) {
  require("dotenv").config({ path: envPath });
  console.log("✅ .env loaded from", envPath);
} else {
  console.log("ℹ️ .env not found (likely running on Vercel)");
}

// Validate required env
if (!process.env.DATABASE_URL) {
  console.warn("⚠️ DATABASE_URL not set, using fallback DB_* variables");
}

// PostgreSQL Pool (Neon requires SSL)
const pool = new Pool({
  connectionString:
    process.env.DATABASE_URL ||
    `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}` +
    `@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}?sslmode=require`,
  ssl: {
    require: true,
    rejectUnauthorized: false,
  },
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// Debug tags
const CODE_VERSION = "v1.0.6-NEON-SSL-FINAL";

// Pool events
pool.on("connect", () => {
  console.log(`✅ [${CODE_VERSION}] PostgreSQL connected (SSL enabled)`);
});

pool.on("error", (err) => {
  console.error(`❌ [${CODE_VERSION}] PostgreSQL error`, err);
  process.exit(1);
});

// Export helpers
module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
