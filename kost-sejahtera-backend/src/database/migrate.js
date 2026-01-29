const fs = require('fs');
const path = require('path');
const db = require('./db');

async function migrate() {
    try {
        console.log('🔄 Running database migration...');

        // Read schema file
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');

        // Execute schema
        await db.query(schema);

        console.log('✅ Migration completed successfully!');
        console.log('📊 Tables created:');
        console.log('   - users');
        console.log('   - rooms');
        console.log('   - tenants');
        console.log('   - invoices');
        console.log('   - transactions');
        console.log('   - payments');

        process.exit(0);
    } catch (error) {
        console.error('❌ Migration error:', error.message);
        process.exit(1);
    }
}

migrate();
