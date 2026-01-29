// Manual Webhook Simulator for Testing
// Run this after completing payment in Midtrans Sandbox

const axios = require('axios');

// CHANGE THIS: Put your actual order_id from the payment
const ORDER_ID = 'INV-2024-001-1769689886'; // From your log above

// Simulate successful payment notification
const webhookPayload = {
    transaction_time: new Date().toISOString(),
    transaction_status: 'settlement',
    transaction_id: 'test-' + Date.now(),
    status_message: 'midtrans payment notification',
    status_code: '200',
    signature_key: 'dummy-signature-for-testing',
    payment_type: 'bank_transfer',
    order_id: ORDER_ID,
    merchant_id: 'G812785002',
    gross_amount: '2500000.00',
    fraud_status: 'accept',
    currency: 'IDR'
};

async function simulateWebhook() {
    try {
        console.log('Sending webhook notification to localhost:3000...');
        console.log('Payload:', JSON.stringify(webhookPayload, null, 2));

        const response = await axios.post('http://localhost:3000/api/payments/webhook', webhookPayload);

        console.log('\n✅ Webhook sent successfully!');
        console.log('Response:', response.data);
        console.log('\nNow refresh your app to see the updated payment status.');
    } catch (error) {
        console.error('❌ Error:', error.response?.data || error.message);
    }
}

simulateWebhook();
