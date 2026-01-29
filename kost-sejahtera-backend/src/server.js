const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

// Trigger redeploy for SSL fix
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.FRONTEND_URL || '*',
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', routes);

// DEBUG DATABASE ROUTE (Temporary)
const db = require('./database/db');
app.get('/api/test-db', async (req, res) => {
    try {
        const result = await db.query('SELECT NOW() as time');
        res.json({
            success: true,
            message: 'Database Connected!',
            time: result.rows[0].time,
            config_check: {
                host: process.env.DB_HOST,
                user: process.env.DB_USER,
                db: process.env.DB_NAME,
                ssl_mode: 'required'
            }
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: 'Database Connection Failed',
            error: err.message,
            env_debug: {
                HOST_Set: !!process.env.DB_HOST,
                USER_Set: !!process.env.DB_USER,
                PASS_Set: !!process.env.DB_PASSWORD,
                DB_Set: !!process.env.DB_NAME
            }
        });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint tidak ditemukan'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Terjadi kesalahan server'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    console.log(`🔗 API URL: http://localhost:${PORT}/api`);
});

module.exports = app;
