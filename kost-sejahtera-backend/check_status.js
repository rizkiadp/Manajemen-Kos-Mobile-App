const db = require('./src/database/db');

async function checkStatus() {
    try {
        // Check invoice status
        const invoice = await db.query('SELECT id, invoice_number, status, paid_at FROM invoices WHERE id = 1');
        console.log('\n📄 Invoice Status:');
        console.log(`   ID: ${invoice.rows[0].id}`);
        console.log(`   Number: ${invoice.rows[0].invoice_number}`);
        console.log(`   Status: ${invoice.rows[0].status}`);
        console.log(`   Paid At: ${invoice.rows[0].paid_at}`);

        // Check payment status
        const payment = await db.query(`
      SELECT id, status, paid_at, midtrans_order_id 
      FROM payments 
      WHERE midtrans_order_id = 'INV-2024-001-1769688871'
    `);
        console.log('\n💳 Payment Status:');
        if (payment.rows.length > 0) {
            payment.rows.forEach(p => {
                console.log(`   ID: ${p.id}, Status: ${p.status}, Paid: ${p.paid_at}`);
            });
        } else {
            console.log('   No payment found with that order ID');
        }

        // Check tenant status
        const tenant = await db.query('SELECT id, payment_status, last_payment_date FROM tenants WHERE id = 1');
        console.log('\n👤 Tenant Status:');
        console.log(`   Payment Status: ${tenant.rows[0].payment_status}`);
        console.log(`   Last Payment: ${tenant.rows[0].last_payment_date}`);

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkStatus();
