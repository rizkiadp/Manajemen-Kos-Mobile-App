const db = require('./src/database/db');

async function checkPayments() {
    try {
        const res = await db.query('SELECT id, invoice_id, amount, status, midtrans_order_id, midtrans_transaction_id, created_at FROM payments ORDER BY created_at DESC LIMIT 5');
        console.log('\n📋 Recent Payments:');
        console.log(JSON.stringify(res.rows, null, 2));

        if (res.rows.length > 0) {
            const latestPending = res.rows.find(p => p.status === 'pending');
            if (latestPending) {
                console.log('\n✅ Latest PENDING payment found:');
                console.log(`   Order ID: ${latestPending.midtrans_order_id}`);
                console.log(`   Token: ${latestPending.midtrans_transaction_id}`);
                console.log('\n💡 Use this Order ID in test_webhook.js');
            }
        }
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkPayments();
