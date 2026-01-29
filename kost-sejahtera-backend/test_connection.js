const { Client } = require('pg');

const config = {
    user: 'default',
    password: 'EJ51dmXcgUlw',
    host: 'ep-small-star-a17qgwqw-pooler.ap-southeast-1.aws.neon.tech',
    database: 'kost-sejahtera-db',
    port: 5432,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 10000,
};

console.log('----------------------------------------');
console.log('🧪 Testing Hardcoded Connection...');
console.log('   Host:', config.host);
console.log('   User:', config.user);
console.log('   DB:', config.database);
console.log('   Pass Len:', config.password.length);
console.log('----------------------------------------');

const client = new Client(config);

async function test() {
    try {
        await client.connect();
        console.log('✅ SUCCESS! Connected to Neon.');
        const res = await client.query('SELECT NOW()');
        console.log('   Time:', res.rows[0].now);
        await client.end();
    } catch (err) {
        console.error('❌ FAILED:', err.message);
        if (err.message.includes('password')) {
            console.log('\n⚠️  DIAGNOSIS: Password ditolak oleh Neon.');
            console.log('   Pastikan password "EJ51dmXcgUlw" benar-benar match dengan di Dashboard.');
            console.log('   Coba "Reset Password" di dashboard Neon jika perlu.');
        } else if (err.message.includes('database')) {
            console.log('\n⚠️  DIAGNOSIS: Nama database salah.');
            console.log('   Pastikan database "kost-sejahtera-db" sudah dibuat di Neon.');
        }
    }
}

test();
