const db = require('../db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
    try {
        console.log('🔄 Running maintenance and messages migration...\n');

        const migrationSQL = fs.readFileSync(
            path.join(__dirname, '002_maintenance_and_messages.sql'),
            'utf8'
        );

        await db.query(migrationSQL);

        console.log('✅ Migration completed successfully!');
        console.log('\nTables created:');
        console.log('  - maintenance_reports');
        console.log('  - messages');
        console.log('\nIndexes created for better performance');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        console.error(error);
    } finally {
        process.exit();
    }
}

runMigration();
