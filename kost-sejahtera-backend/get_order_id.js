const db = require('./src/database/db');

async function getCorrectOrderId() {
    try {
        const res = await db.query(`
      SELECT midtrans_order_id, midtrans_transaction_id, status, created_at
      FROM payments 
      WHERE midtrans_transaction_id IS NOT NULL 
      ORDER BY created_at DESC 
      LIMIT 1
    `);

        if (res.rows.length > 0) {
            const payment = res.rows[0];
            console.log('\n✅ Latest payment with token:');
            console.log(`   Order ID: ${payment.midtrans_order_id}`);
            console.log(`   Token: ${payment.midtrans_transaction_id}`);
            console.log(`   Status: ${payment.status}`);
            console.log(`\n📝 Update test_webhook.js line 5 with:`);
            console.log(`   const ORDER_ID = '${payment.midtrans_order_id}';`);
        } else {
            console.log('❌ No payments with token found');
        }
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

getCorrectOrderId();
