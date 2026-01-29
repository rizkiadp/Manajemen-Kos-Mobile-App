const db = require('../database/db');

// Get all tenants
exports.getAllTenants = async (req, res) => {
    try {
        const { status, payment_status, search } = req.query;

        let query = `
      SELECT t.*, u.name, u.email, u.phone, r.room_number, r.type as room_type, r.price as room_price
      FROM tenants t
      JOIN users u ON t.user_id = u.id
      LEFT JOIN rooms r ON t.room_id = r.id
      WHERE 1 = 1
            `;
        const params = [];
        let paramCount = 1;

        if (status) {
            query += ` AND t.status = $${paramCount} `;
            params.push(status);
            paramCount++;
        }

        if (payment_status) {
            query += ` AND t.payment_status = $${paramCount} `;
            params.push(payment_status);
            paramCount++;
        }

        if (search) {
            query += ` AND(u.name ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR t.nik ILIKE $${paramCount})`;
            params.push(`% ${search}% `);
            paramCount++;
        }

        query += ' ORDER BY t.created_at DESC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get tenants error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get tenant by ID
exports.getTenantById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            `SELECT t.*, u.name, u.email, u.phone, r.room_number, r.type as room_type, r.price
       FROM tenants t
       JOIN users u ON t.user_id = u.id
       LEFT JOIN rooms r ON t.room_id = r.id
       WHERE t.id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Penyewa tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get tenant error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get tenant by user ID
exports.getTenantByUserId = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await db.query(
            `SELECT t.*, r.room_number, r.type as room_type, r.price, r.facilities
       FROM tenants t
       LEFT JOIN rooms r ON t.room_id = r.id
       WHERE t.user_id = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Data penyewa tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get tenant by user error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Create tenant
exports.createTenant = async (req, res) => {
    const client = await db.pool.connect();
    try {
        await client.query('BEGIN');

        const { user_id, name, email, phone, room_id, nik, move_in_date, password } = req.body;
        let finalUserId = user_id;

        // 1. Create User if not provided
        if (!finalUserId) {
            // Check email
            const userCheck = await client.query('SELECT id FROM users WHERE email = $1', [email]);
            if (userCheck.rows.length > 0) {
                await client.query('ROLLBACK');
                return res.status(400).json({ success: false, message: 'Email sudah terdaftar' });
            }

            // Hash password (use provided or default)
            const bcrypt = require('bcryptjs');
            const passToHash = password || '123456';
            const hashedPassword = await bcrypt.hash(passToHash, 10);

            const newUser = await client.query(
                `INSERT INTO users(email, password, name, phone, role)
        VALUES($1, $2, $3, $4, 'tenant') 
                 RETURNING id`,
                [email, hashedPassword, name, phone]
            );
            finalUserId = newUser.rows[0].id;
        }

        // 2. Check Room Availability
        const roomCheck = await client.query(
            'SELECT id, is_available FROM rooms WHERE id = $1',
            [room_id]
        );

        if (roomCheck.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ success: false, message: 'Kamar tidak ditemukan' });
        }

        if (!roomCheck.rows[0].is_available) {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: 'Kamar tidak tersedia' });
        }

        // 3. Create Tenant
        const result = await client.query(
            `INSERT INTO tenants(user_id, room_id, nik, move_in_date, status, payment_status)
        VALUES($1, $2, $3, $4, 'active', 'unpaid')
        RETURNING * `,
            [finalUserId, room_id, nik, move_in_date]
        );

        // 4. Update Room Availability
        await client.query(
            'UPDATE rooms SET is_available = false WHERE id = $1',
            [room_id]
        );

        await client.query('COMMIT');

        res.status(201).json({
            success: true,
            message: 'Penyewa berhasil ditambahkan',
            data: result.rows[0]
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Create tenant error:', error);

        if (error.code === '23505') { // Unique violation
            return res.status(400).json({
                success: false,
                message: error.detail.includes('nik') ? 'NIK sudah terdaftar' : 'Email sudah terdaftar'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    } finally {
        client.release();
    }
};

// Update tenant
exports.updateTenant = async (req, res) => {
    const client = await db.pool.connect();
    try {
        await client.query('BEGIN');

        const { id } = req.params;
        // Tenant fields + User fields
        const { room_id, nik, status, payment_status, name, email, phone, password } = req.body;

        // Get current tenant data
        const currentTenant = await client.query('SELECT * FROM tenants WHERE id = $1', [id]);

        if (currentTenant.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                success: false,
                message: 'Penyewa tidak ditemukan'
            });
        }

        const tenantData = currentTenant.rows[0];
        const oldRoomId = tenantData.room_id;
        const userId = tenantData.user_id;

        // 1. Update User Data (if provided)
        if (name || email || phone || password) {
            const updates = [];
            const values = [];
            let counter = 1;

            if (name) { updates.push(`name = $${counter} `); values.push(name); counter++; }
            if (email) { updates.push(`email = $${counter} `); values.push(email); counter++; }
            if (phone) { updates.push(`phone = $${counter} `); values.push(phone); counter++; }
            if (password) {
                const bcrypt = require('bcryptjs');
                const hashed = await bcrypt.hash(password, 10);
                updates.push(`password = $${counter} `);
                values.push(hashed);
                counter++;
            }

            if (updates.length > 0) {
                values.push(userId);
                await client.query(
                    `UPDATE users SET ${updates.join(', ')} WHERE id = $${counter} `,
                    values
                );
            }
        }

        // 2. Handle Room Change
        if (room_id && room_id !== oldRoomId) {
            // Check new room availability
            const newRoom = await client.query(
                'SELECT is_available FROM rooms WHERE id = $1',
                [room_id]
            );

            if (newRoom.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({ success: false, message: 'Kamar baru tidak ditemukan' });
            }

            if (!newRoom.rows[0].is_available) {
                await client.query('ROLLBACK');
                return res.status(400).json({ success: false, message: 'Kamar baru tidak tersedia' });
            }

            // Free old room
            if (oldRoomId) {
                await client.query('UPDATE rooms SET is_available = true WHERE id = $1', [oldRoomId]);
            }

            // Occupy new room
            await client.query('UPDATE rooms SET is_available = false WHERE id = $1', [room_id]);
        }

        // 3. Update Tenant Data
        const result = await client.query(
            `UPDATE tenants
             SET room_id = COALESCE($1, room_id),
            nik = COALESCE($2, nik),
            status = COALESCE($3, status),
            payment_status = COALESCE($4, payment_status)
             WHERE id = $5
        RETURNING * `,
            [room_id, nik, status, payment_status, id]
        );

        await client.query('COMMIT');

        // Fetch user data to return merged result
        const userRes = await client.query('SELECT name, email, phone FROM users WHERE id = $1', [userId]);
        const userData = userRes.rows[0];

        res.json({
            success: true,
            message: 'Data penyewa berhasil diupdate',
            data: { ...result.rows[0], ...userData }
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Update tenant error:', error);

        if (error.code === '23505') { // Unique violation email/nik
            return res.status(400).json({
                success: false,
                message: error.detail.includes('nik') ? 'NIK sudah terdaftar' : 'Email sudah terdaftar'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    } finally {
        client.release();
    }
};

// Delete tenant
exports.deleteTenant = async (req, res) => {
    try {
        const { id } = req.params;

        // Get tenant data
        const tenant = await db.query('SELECT room_id FROM tenants WHERE id = $1', [id]);

        if (tenant.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Penyewa tidak ditemukan'
            });
        }

        const roomId = tenant.rows[0].room_id;

        // Delete tenant
        await db.query('DELETE FROM tenants WHERE id = $1', [id]);

        // Free the room
        if (roomId) {
            await db.query('UPDATE rooms SET is_available = true WHERE id = $1', [roomId]);
        }

        res.json({
            success: true,
            message: 'Penyewa berhasil dihapus'
        });
    } catch (error) {
        console.error('Delete tenant error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};


// Move out tenant (Soft delete / Deactivate)
exports.moveOutTenant = async (req, res) => {
    const client = await db.pool.connect();
    try {
        await client.query('BEGIN');

        const { id } = req.params;

        // 1. Get tenant info
        const tenantRes = await client.query('SELECT * FROM tenants WHERE id = $1', [id]);
        if (tenantRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ success: false, message: 'Penyewa tidak ditemukan' });
        }
        const tenant = tenantRes.rows[0];
        const { user_id, room_id, status } = tenant;

        if (status === 'inactive') {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: 'Penyewa sudah tidak aktif (sudah keluar)' });
        }

        // 2. Free up the room
        if (room_id) {
            await client.query('UPDATE rooms SET is_available = true WHERE id = $1', [room_id]);
        }

        // 3. Update Tenant Status
        await client.query(
            `UPDATE tenants 
             SET status = 'inactive', 
                 room_id = NULL 
             WHERE id = $1`,
            [id]
        );

        // 4. Deactivate User Account (Obfuscate credentials)
        // We use a timestamp to make the deleted email unique so they can potentially re-register with the same email later if needed (though unlikely for this use case, it prevents unique constraint errors).
        const timestamp = Date.now();
        const deletedEmail = `deleted_${timestamp}_${user_id}@kostsejahtera.com`;
        const bcrypt = require('bcryptjs');
        const scrambledPassword = await bcrypt.hash(`deleted_${timestamp}`, 10);

        await client.query(
            `UPDATE users 
             SET email = $1, 
                 password = $2, 
                 role = 'tenant' 
             WHERE id = $3`,
            [deletedEmail, scrambledPassword, user_id]
        );

        await client.query('COMMIT');

        res.json({
            success: true,
            message: 'Penyewa berhasil dikeluarkan dan akses login dicabut.'
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Move out tenant error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    } finally {
        client.release();
    }
};

module.exports = exports;
