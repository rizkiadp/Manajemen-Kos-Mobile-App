const db = require('./src/database/db');

async function up() {
    try {
        console.log('💬 Creating messages table...');

        await db.query(`
            CREATE TABLE IF NOT EXISTS messages (
                id SERIAL PRIMARY KEY,
                sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                message TEXT NOT NULL,
                is_read BOOLEAN DEFAULT false,
                report_id INTEGER REFERENCES maintenance_reports(id) ON DELETE SET NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
            CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
            CREATE INDEX IF NOT EXISTS idx_messages_report ON messages(report_id);
        `);

        console.log('✅ Success! Table messages created.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error:', err.message);
        process.exit(1);
    }
}

up();
