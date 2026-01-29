const db = require('./src/database/db');

async function checkInvoiceAndPayments() {
    try {
        // Check invoice
        const invoice = await db.query(`
      SELECT id, invoice_number, tenant_id, total, status 
      FROM invoices 
      WHERE id = 1
    `);
        console.log('\n📄 Invoice Details:');
        console.log(JSON.stringify(invoice.rows[0], null, 2));

        // Check all payments for this invoice
        const payments = await db.query(`
      SELECT id, invoice_id, status, midtrans_order_id, midtrans_transaction_id, created_at
      FROM payments 
      WHERE invoice_id = 1
      ORDER BY created_at DESC
    `);
        console.log('\n💳 All Payments for Invoice #1:');
        console.log(JSON.stringify(payments.rows, null, 2));

        if (payments.rows.length > 0) {
            const latestPending = payments.rows.find(p => p.status === 'pending' && p.midtrans_transaction_id);
            if (latestPending) {
                console.log('\n✅ Use this Order ID for webhook test:');
                console.log(`   ${latestPending.midtrans_order_id}`);
            }
        }
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkInvoiceAndPayments();
