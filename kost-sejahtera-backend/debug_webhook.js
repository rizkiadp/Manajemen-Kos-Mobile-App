const db = require('./src/database/db');

async function debugWebhook() {
    try {
        console.log('\n🔍 Debugging Webhook Issue...\n');

        // 1. Check invoice
        const inv = await db.query('SELECT invoice_number FROM invoices WHERE id = 1');
        console.log(`1️⃣  Invoice Number in DB: "${inv.rows[0].invoice_number}"`);

        // 2. Check payments with that invoice
        const payments = await db.query(`
      SELECT id, midtrans_order_id, status 
      FROM payments 
      WHERE invoice_id = 1 
      ORDER BY created_at DESC
    `);
        console.log(`\n2️⃣  Payments for Invoice #1:`);
        payments.rows.forEach(p => {
            console.log(`   - Payment #${p.id}: Order ID = "${p.midtrans_order_id}", Status = ${p.status}`);
        });

        // 3. Try to find payment by order_id used in webhook
        const webhookOrderId = 'INV-2024-001-1769688871';
        const found = await db.query('SELECT * FROM payments WHERE midtrans_order_id = $1', [webhookOrderId]);
        console.log(`\n3️⃣  Looking for Order ID: "${webhookOrderId}"`);
        console.log(`   Found: ${found.rows.length > 0 ? 'YES ✅' : 'NO ❌'}`);

        if (found.rows.length > 0) {
            console.log(`   Status: ${found.rows[0].status}`);
            console.log(`   Paid At: ${found.rows[0].paid_at}`);
        }

        console.log(`\n💡 Solution:`);
        if (found.rows.length === 0) {
            console.log(`   The webhook order_id doesn't match any payment in DB.`);
            console.log(`   Use one of the Order IDs listed above in test_webhook.js`);
        } else if (found.rows[0].status === 'success') {
            console.log(`   Payment is already marked as SUCCESS!`);
            console.log(`   Check if invoice was updated...`);
            const invCheck = await db.query('SELECT status FROM invoices WHERE invoice_number = $1', [webhookOrderId]);
            if (invCheck.rows.length > 0) {
                console.log(`   Invoice status: ${invCheck.rows[0].status}`);
            } else {
                console.log(`   ❌ Invoice not found with number: ${webhookOrderId}`);
                console.log(`   This is the problem! Invoice number doesn't match order_id`);
            }
        }

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

debugWebhook();
