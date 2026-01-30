const db = require('./src/database/db');

async function up() {
    try {
        console.log('🛠️ Creating maintenance_reports table...');

        await db.query(`
            CREATE TABLE IF NOT EXISTS maintenance_reports (
                id SERIAL PRIMARY KEY,
                tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
                room_id INTEGER REFERENCES rooms(id) ON DELETE SET NULL,
                title VARCHAR(255) NOT NULL,
                description TEXT NOT NULL,
                category VARCHAR(50) NOT NULL,
                priority VARCHAR(20) DEFAULT 'medium',
                status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed')),
                image_url TEXT,
                resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
                resolved_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_maintenance_tenant ON maintenance_reports(tenant_id);
            CREATE INDEX IF NOT EXISTS idx_maintenance_status ON maintenance_reports(status);
            
            -- Trigger for updated_at
            DROP TRIGGER IF EXISTS update_maintenance_updated_at ON maintenance_reports;
            CREATE TRIGGER update_maintenance_updated_at BEFORE UPDATE ON maintenance_reports
                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        `);

        console.log('✅ Success! Table maintenance_reports created.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error:', err.message);
        process.exit(1);
    }
}

up();
