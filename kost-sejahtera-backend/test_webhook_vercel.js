const https = require('https');

const data = JSON.stringify({
    transaction_status: 'settlement',
    order_id: 'TEST-ORDER-' + Date.now(),
    gross_amount: '10000.00',
    signature_key: 'dummy-signature-for-testing', // backdoor for testing logic
    payment_type: 'bank_transfer',
    fraud_status: 'accept'
});

const options = {
    hostname: 'manajemen-kos-mobile-8od138kja-rizkis-projects-37bd2b95.vercel.app',
    path: '/api/payments/webhook',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

console.log('🚀 Sending Test Webhook to Vercel...');
const req = https.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);

    let responseBody = '';
    res.on('data', (chunk) => {
        responseBody += chunk;
    });

    res.on('end', () => {
        console.log('BODY:', responseBody);
        if (res.statusCode === 200) {
            console.log('✅ Webhook Endpoint is REACHABLE and working!');
        } else {
            console.log('❌ Webhook Endpoint returned error.');
        }
    });
});

req.on('error', (error) => {
    console.error('❌ Connection Error:', error);
});

req.write(data);
req.end();
