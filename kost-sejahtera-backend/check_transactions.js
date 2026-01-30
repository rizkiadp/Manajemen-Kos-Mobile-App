const db = require('./src/database/db');

async function checkTransactions() {
    try {
        console.log('\n📋 Checking Transactions Table...\n');

        // Check if table exists
        const tableCheck = await db.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'transactions'
            );
        `);

        if (!tableCheck.rows[0].exists) {
            console.log('❌ Transactions table does NOT exist!');
            return;
        }

        console.log('✅ Transactions table exists');

        // Get all transactions
        const transactions = await db.query(`
            SELECT * FROM transactions 
            ORDER BY date DESC, created_at DESC 
            LIMIT 10
        `);

        console.log(`\n📊 Total transactions found: ${transactions.rows.length}\n`);

        if (transactions.rows.length > 0) {
            console.log('Recent Transactions:');
            transactions.rows.forEach((t, i) => {
                console.log(`\n${i + 1}. Transaction ID: ${t.id}`);
                console.log(`   Type: ${t.type}`);
                console.log(`   Category: ${t.category}`);
                console.log(`   Amount: Rp ${t.amount}`);
                console.log(`   Description: ${t.description}`);
                console.log(`   Date: ${t.date}`);
                console.log(`   Invoice ID: ${t.invoice_id || 'N/A'}`);
                console.log(`   Tenant ID: ${t.tenant_id || 'N/A'}`);
            });
        } else {
            console.log('⚠️  No transactions found in database!');
            console.log('\nThis means either:');
            console.log('1. No payments have been successfully processed');
            console.log('2. Webhook is not creating transaction records');
            console.log('3. Transaction creation is failing silently');
        }

        // Check payments
        const payments = await db.query(`
            SELECT id, invoice_id, amount, status, paid_at 
            FROM payments 
            WHERE status = 'success'
            ORDER BY paid_at DESC 
            LIMIT 5
        `);

        console.log(`\n\n💰 Successful Payments: ${payments.rows.length}`);
        if (payments.rows.length > 0) {
            payments.rows.forEach((p, i) => {
                console.log(`\n${i + 1}. Payment ID: ${p.id}`);
                console.log(`   Invoice ID: ${p.invoice_id}`);
                console.log(`   Amount: Rp ${p.amount}`);
                console.log(`   Paid At: ${p.paid_at}`);
            });
        }

    } catch (err) {
        console.error('❌ Error:', err.message);
        console.error(err);
    } finally {
        process.exit();
    }
}

checkTransactions();
