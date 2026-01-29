const bcrypt = require('bcryptjs');
const db = require('./db');

async function seed() {
    try {
        console.log('🌱 Seeding database...');

        // Create admin user
        const hashedPassword = await bcrypt.hash('admin123', 10);

        const adminResult = await db.query(
            `INSERT INTO users (email, password, name, phone, role) 
       VALUES ($1, $2, $3, $4, $5) 
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
            ['admin@kost.com', hashedPassword, 'Admin', '08123456789', 'admin']
        );

        if (adminResult.rows.length > 0) {
            console.log('✅ Admin user created');
            console.log('   Email: admin@kost.com');
            console.log('   Password: admin123');
        } else {
            console.log('ℹ️  Admin user already exists');
        }

        // Create sample rooms
        const rooms = [
            {
                room_number: 'A-101',
                type: 'VIP',
                floor: 1,
                wing: 'Kiri',
                price: 2500000,
                facilities: ['AC', 'WiFi', 'KM Dalam', 'Kasur', 'Lemari', 'Meja Belajar'],
                is_available: false
            },
            {
                room_number: 'A-102',
                type: 'Standard',
                floor: 1,
                wing: 'Kiri',
                price: 2000000,
                facilities: ['WiFi', 'KM Dalam', 'Kasur', 'Lemari'],
                is_available: true
            },
            {
                room_number: 'B-201',
                type: 'VIP',
                floor: 2,
                wing: 'Kanan',
                price: 2500000,
                facilities: ['AC', 'WiFi', 'KM Dalam', 'Kasur', 'Lemari', 'Balkon'],
                is_available: true
            },
            {
                room_number: 'B-202',
                type: 'Standard',
                floor: 2,
                wing: 'Kanan',
                price: 2000000,
                facilities: ['WiFi', 'KM Dalam', 'Kasur'],
                is_available: true
            },
            {
                room_number: 'C-301',
                type: 'Reguler',
                floor: 3,
                wing: 'Tengah',
                price: 1500000,
                facilities: ['WiFi', 'KM Luar', 'Kasur'],
                is_available: true
            }
        ];

        for (const room of rooms) {
            await db.query(
                `INSERT INTO rooms (room_number, type, floor, wing, price, facilities, is_available) 
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (room_number) DO NOTHING`,
                [
                    room.room_number,
                    room.type,
                    room.floor,
                    room.wing,
                    room.price,
                    JSON.stringify(room.facilities),
                    room.is_available
                ]
            );
        }

        console.log(`✅ ${rooms.length} sample rooms created`);

        // Create sample tenant
        const tenantPassword = await bcrypt.hash('tenant123', 10);

        const tenantUserResult = await db.query(
            `INSERT INTO users (email, password, name, phone, role) 
       VALUES ($1, $2, $3, $4, $5) 
       ON CONFLICT (email) DO NOTHING
       RETURNING id`,
            ['budi@example.com', tenantPassword, 'Budi Santoso', '08198765432', 'tenant']
        );

        if (tenantUserResult.rows.length > 0) {
            const userId = tenantUserResult.rows[0].id;

            // Get room A-101
            const roomResult = await db.query(
                'SELECT id FROM rooms WHERE room_number = $1',
                ['A-101']
            );

            if (roomResult.rows.length > 0) {
                const roomId = roomResult.rows[0].id;

                // Create tenant record
                await db.query(
                    `INSERT INTO tenants (user_id, room_id, nik, move_in_date, status, payment_status)
           VALUES ($1, $2, $3, $4, $5, $6)`,
                    [userId, roomId, '3201234567890123', '2024-01-01', 'active', 'unpaid']
                );

                // Create invoice
                const invoiceResult = await db.query(
                    `INSERT INTO invoices (
            invoice_number, tenant_id, room_id, period, issue_date, due_date,
            items, subtotal, discount, total, status
          ) VALUES ($1, 
            (SELECT id FROM tenants WHERE user_id = $2),
            $3, $4, $5, $6, $7, $8, $9, $10, $11
          ) RETURNING id`,
                    [
                        'INV-2024-001',
                        userId,
                        roomId,
                        'Januari 2024',
                        '2024-01-01',
                        '2024-02-05',
                        JSON.stringify([
                            { description: 'Sewa Kamar', amount: 2000000 },
                            { description: 'Listrik', amount: 300000 },
                            { description: 'Air', amount: 100000 },
                            { description: 'Internet', amount: 100000 }
                        ]),
                        2500000,
                        0,
                        2500000,
                        'unpaid'
                    ]
                );

                console.log('✅ Sample tenant created');
                console.log('   Email: budi@example.com');
                console.log('   Password: tenant123');
                console.log('   Room: A-101');
                console.log('   Invoice: INV-2024-001');
            }
        }

        console.log('✅ Database seeding completed!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Seeding error:', error);
        process.exit(1);
    }
}

seed();
