const db = require('../database/db');

// Get all rooms
exports.getAllRooms = async (req, res) => {
    try {
        const { type, available, search } = req.query;

        let query = 'SELECT * FROM rooms WHERE 1=1';
        const params = [];
        let paramCount = 1;

        if (type) {
            query += ` AND type = $${paramCount}`;
            params.push(type);
            paramCount++;
        }

        if (available !== undefined) {
            query += ` AND is_available = $${paramCount}`;
            params.push(available === 'true');
            paramCount++;
        }

        if (search) {
            query += ` AND room_number ILIKE $${paramCount}`;
            params.push(`%${search}%`);
            paramCount++;
        }

        query += ' ORDER BY room_number ASC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get rooms error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get room by ID
exports.getRoomById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            'SELECT * FROM rooms WHERE id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kamar tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get room error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Create room
exports.createRoom = async (req, res) => {
    try {
        const { room_number, type, floor, wing, price, facilities, images } = req.body;

        const result = await db.query(
            `INSERT INTO rooms (room_number, type, floor, wing, price, facilities, images) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) 
       RETURNING *`,
            [room_number, type, floor, wing, price, JSON.stringify(facilities || []), JSON.stringify(images || [])]
        );

        res.status(201).json({
            success: true,
            message: 'Kamar berhasil ditambahkan',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create room error:', error);

        if (error.code === '23505') {
            return res.status(400).json({
                success: false,
                message: 'Nomor kamar sudah ada'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Update room
exports.updateRoom = async (req, res) => {
    try {
        const { id } = req.params;
        const { room_number, type, floor, wing, price, facilities, images, is_available } = req.body;

        const result = await db.query(
            `UPDATE rooms 
       SET room_number = COALESCE($1, room_number),
           type = COALESCE($2, type),
           floor = COALESCE($3, floor),
           wing = COALESCE($4, wing),
           price = COALESCE($5, price),
           facilities = COALESCE($6, facilities),
           images = COALESCE($7, images),
           is_available = COALESCE($8, is_available)
       WHERE id = $9
       RETURNING *`,
            [
                room_number,
                type,
                floor,
                wing,
                price,
                facilities ? JSON.stringify(facilities) : null,
                images ? JSON.stringify(images) : null,
                is_available,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kamar tidak ditemukan'
            });
        }

        res.json({
            success: true,
            message: 'Kamar berhasil diupdate',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update room error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Delete room
exports.deleteRoom = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            'DELETE FROM rooms WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kamar tidak ditemukan'
            });
        }

        res.json({
            success: true,
            message: 'Kamar berhasil dihapus'
        });
    } catch (error) {
        console.error('Delete room error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};
