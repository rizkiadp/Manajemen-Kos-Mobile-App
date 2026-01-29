const db = require('./src/database/db');

async function listTenants() {
    try {
        console.log('Querying tenants...');
        const res = await db.query('SELECT id, user_id, nik, status FROM tenants');
        console.log('Tenants:');
        res.rows.forEach(t => {
            console.log(`ID: ${t.id}, UserId: ${t.user_id}, Status: ${t.status}`);
        });
        process.exit(0);
    } catch (err) {
        console.error('Error listing tenants:', err);
        process.exit(1);
    }
}

listTenants();
