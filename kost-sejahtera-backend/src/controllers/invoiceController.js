const db = require('../database/db');

// Get all invoices
exports.getAllInvoices = async (req, res) => {
    try {
        const { status, tenant_id, period } = req.query;

        let query = `
      SELECT i.*, t.user_id, u.name as tenant_name, r.room_number
      FROM invoices i
      JOIN tenants t ON i.tenant_id = t.id
      JOIN users u ON t.user_id = u.id
      LEFT JOIN rooms r ON i.room_id = r.id
      WHERE 1=1
    `;
        const params = [];
        let paramCount = 1;

        if (status) {
            query += ` AND i.status = $${paramCount}`;
            params.push(status);
            paramCount++;
        }

        if (tenant_id) {
            query += ` AND i.tenant_id = $${paramCount}`;
            params.push(tenant_id);
            paramCount++;
        }

        if (period) {
            query += ` AND i.period = $${paramCount}`;
            params.push(period);
            paramCount++;
        }

        query += ' ORDER BY i.created_at DESC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get invoices error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get invoice by ID
exports.getInvoiceById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            `SELECT i.*, t.user_id, u.name as tenant_name, u.email, u.phone, r.room_number
       FROM invoices i
       JOIN tenants t ON i.tenant_id = t.id
       JOIN users u ON t.user_id = u.id
       LEFT JOIN rooms r ON i.room_id = r.id
       WHERE i.id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invoice tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get invoice error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get invoices by tenant user ID
exports.getInvoicesByUserId = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await db.query(
            `SELECT i.*, r.room_number
       FROM invoices i
       JOIN tenants t ON i.tenant_id = t.id
       LEFT JOIN rooms r ON i.room_id = r.id
       WHERE t.user_id = $1
       ORDER BY i.created_at DESC`,
            [userId]
        );

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get invoices by user error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Create invoice
exports.createInvoice = async (req, res) => {
    try {
        const { tenant_id, room_id, period, issue_date, due_date, items, discount = 0 } = req.body;

        // 1. Fetch Room ID if missing
        let finalRoomId = room_id;
        if (!finalRoomId) {
            const tenant = await db.query('SELECT room_id FROM tenants WHERE id = $1', [tenant_id]);
            if (tenant.rows.length > 0) {
                finalRoomId = tenant.rows[0].room_id;
            }
        }

        // 2. Set defaults
        const finalIssueDate = issue_date || new Date().toISOString().split('T')[0];
        const finalPeriod = period || new Date().toISOString().slice(0, 7); // YYYY-MM
        const finalDueDate = due_date || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

        // Calculate totals
        const subtotal = items.reduce((sum, item) => sum + parseFloat(item.amount), 0);
        const total = subtotal - discount;

        // Generate invoice number
        const invoiceNumber = `INV-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;

        const result = await db.query(
            `INSERT INTO invoices (
        invoice_number, tenant_id, room_id, period, issue_date, due_date,
        items, subtotal, discount, total, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'unpaid')
      RETURNING *`,
            [invoiceNumber, tenant_id, finalRoomId, finalPeriod, finalIssueDate, finalDueDate, JSON.stringify(items), subtotal, discount, total]
        );

        // Update tenant payment status
        await db.query(
            `UPDATE tenants SET payment_status = 'unpaid' WHERE id = $1`,
            [tenant_id]
        );

        res.status(201).json({
            success: true,
            message: 'Invoice berhasil dibuat',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create invoice error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Update invoice
exports.updateInvoice = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, items, discount } = req.body;

        let updateFields = [];
        let params = [];
        let paramCount = 1;

        if (status) {
            updateFields.push(`status = $${paramCount}`);
            params.push(status);
            paramCount++;
        }

        if (items) {
            const subtotal = items.reduce((sum, item) => sum + parseFloat(item.amount), 0);
            const total = subtotal - (discount || 0);

            updateFields.push(`items = $${paramCount}`);
            params.push(JSON.stringify(items));
            paramCount++;

            updateFields.push(`subtotal = $${paramCount}`);
            params.push(subtotal);
            paramCount++;

            updateFields.push(`total = $${paramCount}`);
            params.push(total);
            paramCount++;
        }

        if (discount !== undefined) {
            updateFields.push(`discount = $${paramCount}`);
            params.push(discount);
            paramCount++;
        }

        if (updateFields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Tidak ada data yang diupdate'
            });
        }

        params.push(id);

        const result = await db.query(
            `UPDATE invoices SET ${updateFields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
            params
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invoice tidak ditemukan'
            });
        }

        res.json({
            success: true,
            message: 'Invoice berhasil diupdate',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update invoice error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Delete invoice
exports.deleteInvoice = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query(
            'DELETE FROM invoices WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Invoice tidak ditemukan'
            });
        }

        res.json({
            success: true,
            message: 'Invoice berhasil dihapus'
        });
    } catch (error) {
        console.error('Delete invoice error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

module.exports = exports;
