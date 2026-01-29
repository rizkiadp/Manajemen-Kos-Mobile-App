const midtransClient = require('midtrans-client');
const db = require('../database/db');

const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
    clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// Create payment transaction
exports.createTransaction = async (req, res) => {
    try {
        const { invoice_id, payment_method } = req.body;

        // Get invoice details
        const invoiceResult = await db.query(
            `SELECT i.*, t.user_id, u.name, u.email, u.phone, r.room_number
       FROM invoices i
       JOIN tenants t ON i.tenant_id = t.id
       JOIN users u ON t.user_id = u.id
       LEFT JOIN rooms r ON i.room_id = r.id
       WHERE i.id = $1`,
            [invoice_id]
        );

        if (invoiceResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invoice tidak ditemukan'
            });
        }

        const invoice = invoiceResult.rows[0];

        if (invoice.status === 'paid') {
            return res.status(400).json({
                success: false,
                message: 'Invoice sudah dibayar'
            });
        }

        // Check for existing pending payment
        const existingPayment = await db.query(
            `SELECT * FROM payments 
             WHERE invoice_id = $1 AND status = 'pending'
             ORDER BY created_at DESC LIMIT 1`,
            [invoice_id]
        );

        if (existingPayment.rows.length > 0) {
            const payment = existingPayment.rows[0];

            // If we have token, return it
            if (payment.midtrans_transaction_id) {
                // If snap token is still valid (Midtrans tokens usually last > 1 hour)
                // In production, we might want to check status with Midtrans here
                return res.json({
                    success: true,
                    message: 'Transaksi pembayaran sudah ada',
                    data: {
                        payment_id: payment.id,
                        token: payment.midtrans_transaction_id,
                        redirect_url: `https://app.sandbox.midtrans.com/snap/v2/vtweb/${payment.midtrans_transaction_id}`
                    }
                });
            }
        }

        // Generate unique Order ID for Midtrans if retrying
        // We append a timestamp to ensure uniqueness against failed/expired attempts
        const timestamp = Math.floor(Date.now() / 1000);
        const orderId = `${invoice.invoice_number}-${timestamp}`;

        // Create payment record
        const paymentResult = await db.query(
            `INSERT INTO payments (invoice_id, tenant_id, amount, method, provider, midtrans_order_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
            [
                invoice_id,
                invoice.tenant_id,
                invoice.total,
                payment_method,
                payment_method,
                orderId
            ]
        );

        const payment = paymentResult.rows[0];

        // Prepare Midtrans parameter
        const parameter = {
            transaction_details: {
                order_id: orderId,
                gross_amount: parseInt(invoice.total)
            },
            customer_details: {
                first_name: invoice.name,
                email: invoice.email,
                phone: invoice.phone
            },
            item_details: invoice.items.map(item => ({
                id: item.description.replace(/\s+/g, '_').toLowerCase(),
                price: parseInt(item.amount),
                quantity: 1,
                name: item.description
            })),
            enabled_payments: getEnabledPayments(payment_method)
        };

        // Create transaction with Midtrans
        console.log('Calling Midtrans with param:', JSON.stringify(parameter));
        const transaction = await snap.createTransaction(parameter);
        console.log('Midtrans response:', JSON.stringify(transaction));

        // Update payment with transaction token
        await db.query(
            'UPDATE payments SET midtrans_transaction_id = $1 WHERE id = $2',
            [transaction.token, payment.id]
        );
        console.log('Payment updated with token:', transaction.token);

        res.json({
            success: true,
            message: 'Transaksi berhasil dibuat',
            data: {
                payment_id: payment.id,
                token: transaction.token,
                redirect_url: transaction.redirect_url
            }
        });
    } catch (error) {
        console.error('Create transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server',
            error: error.message
        });
    }
};

// Midtrans webhook handler
exports.handleWebhook = async (req, res) => {
    try {
        const notification = req.body;

        let statusResponse;

        // For testing with dummy signature, skip Midtrans validation
        if (notification.signature_key === 'dummy-signature-for-testing') {
            console.log('⚠️  Using test mode - skipping signature validation');
            statusResponse = notification; // Use notification directly
        } else {
            // Production: validate with Midtrans
            statusResponse = await snap.transaction.notification(notification);
        }

        const orderId = statusResponse.order_id;
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;

        console.log(`Transaction notification: Order ID: ${orderId}, Status: ${transactionStatus}, Fraud: ${fraudStatus}`);

        let paymentStatus = 'pending';
        let invoiceStatus = 'unpaid';

        if (transactionStatus === 'capture') {
            if (fraudStatus === 'accept') {
                paymentStatus = 'success';
                invoiceStatus = 'paid';
            }
        } else if (transactionStatus === 'settlement') {
            paymentStatus = 'success';
            invoiceStatus = 'paid';
        } else if (['cancel', 'deny', 'expire'].includes(transactionStatus)) {
            paymentStatus = 'failed';
            invoiceStatus = 'unpaid';
        }

        // Update payment status
        if (paymentStatus === 'success') {
            await db.query(
                `UPDATE payments 
           SET status = $1, paid_at = CURRENT_TIMESTAMP
           WHERE midtrans_order_id = $2`,
                [paymentStatus, orderId]
            );
        } else {
            await db.query(
                `UPDATE payments 
           SET status = $1, paid_at = NULL
           WHERE midtrans_order_id = $2`,
                [paymentStatus, orderId]
            );
        }

        // Update invoice status
        if (paymentStatus === 'success') {
            // Get invoice_id from payment record
            const paymentRecord = await db.query(
                'SELECT invoice_id FROM payments WHERE midtrans_order_id = $1',
                [orderId]
            );

            if (paymentRecord.rows.length > 0) {
                const invoiceId = paymentRecord.rows[0].invoice_id;

                // Update invoice
                await db.query(
                    `UPDATE invoices 
             SET status = $1, paid_at = CURRENT_TIMESTAMP, payment_method = $2
             WHERE id = $3`,
                    [invoiceStatus, statusResponse.payment_type, invoiceId]
                );

                // Update tenant payment status
                const invoiceResult = await db.query(
                    'SELECT tenant_id FROM invoices WHERE id = $1',
                    [invoiceId]
                );

                if (invoiceResult.rows.length > 0) {
                    await db.query(
                        `UPDATE tenants 
               SET payment_status = 'paid', last_payment_date = CURRENT_TIMESTAMP
               WHERE id = $1`,
                        [invoiceResult.rows[0].tenant_id]
                    );
                }

                // Create transaction record
                await db.query(
                    `INSERT INTO transactions (type, category, amount, description, date, invoice_id, created_by)
             VALUES ('income', 'Sewa Kamar', $1, 'Pembayaran invoice', CURRENT_DATE, $2, 1)`,
                    [parseFloat(statusResponse.gross_amount), invoiceId]
                );

                console.log(`✅ Invoice #${invoiceId} marked as paid`);
            }
        }

        res.status(200).send('OK');
    } catch (error) {
        console.error('Webhook error details:', error);
        console.error('Error stack:', error.stack);

        // Return detailed error for debugging (including code version check if possible)
        const isSslError = error.message.includes('ssl') || error.message.includes('insecure');
        res.status(500).json({
            success: false,
            message: 'Webhook error',
            error: error.message,
            diagnosis: isSslError ? 'SSL Connection Issue - Check Vercel Logs for [v1.0.5] tag' : 'Other Error',
            deploy_version: 'v1.0.5-FIX-SSL'
        });
    }
};

// Check payment status
exports.checkStatus = async (req, res) => {
    try {
        const { order_id } = req.params;

        const result = await db.query(
            `SELECT p.*, i.invoice_number, i.total
       FROM payments p
       JOIN invoices i ON p.invoice_id = i.id
       WHERE i.invoice_number = $1
       ORDER BY p.created_at DESC
       LIMIT 1`,
            [order_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Payment tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Check status error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

function getEnabledPayments(method) {
    const paymentMethods = {
        'bank_transfer': ['bank_transfer'],
        'ewallet': ['gopay', 'shopeepay'],
        'qris': ['qris'],
    };
    return paymentMethods[method] || ['bank_transfer', 'gopay', 'shopeepay', 'qris'];
}

module.exports = exports;
