const db = require('../database/db');

// Get dashboard statistics (Admin)
exports.getDashboardStats = async (req, res) => {
    try {
        // Total rooms
        const totalRooms = await db.query('SELECT COUNT(*) as count FROM rooms');

        // Available rooms
        const availableRooms = await db.query('SELECT COUNT(*) as count FROM rooms WHERE is_available = true');

        // Occupied rooms
        const occupiedRooms = await db.query('SELECT COUNT(*) as count FROM rooms WHERE is_available = false');

        // Active tenants
        const activeTenants = await db.query("SELECT COUNT(*) as count FROM tenants WHERE status = 'active'");

        // Pending invoices
        const pendingInvoices = await db.query("SELECT COUNT(*) as count FROM invoices WHERE status = 'unpaid'");

        // Total pending amount
        const pendingAmount = await db.query("SELECT COALESCE(SUM(total), 0) as total FROM invoices WHERE status = 'unpaid'");

        // Monthly income (current month)
        const monthlyIncome = await db.query(`
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM transactions 
      WHERE type = 'income' 
      AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(YEAR FROM date) = EXTRACT(YEAR FROM CURRENT_DATE)
    `);

        // Monthly expense (current month)
        const monthlyExpense = await db.query(`
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM transactions 
      WHERE type = 'expense' 
      AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(YEAR FROM date) = EXTRACT(YEAR FROM CURRENT_DATE)
    `);

        // Occupancy rate
        const totalRoomsCount = parseInt(totalRooms.rows[0].count);
        const occupiedRoomsCount = parseInt(occupiedRooms.rows[0].count);
        const occupancyRate = totalRoomsCount > 0 ? (occupiedRoomsCount / totalRoomsCount * 100).toFixed(1) : 0;

        // Due soon invoices (within 7 days)
        const dueSoon = await db.query(`
      SELECT i.*, t.user_id, u.name as tenant_name, r.room_number
      FROM invoices i
      JOIN tenants t ON i.tenant_id = t.id
      JOIN users u ON t.user_id = u.id
      LEFT JOIN rooms r ON i.room_id = r.id
      WHERE i.status = 'unpaid'
      AND i.due_date <= CURRENT_DATE + INTERVAL '7 days'
      ORDER BY i.due_date ASC
      LIMIT 5
    `);

        res.json({
            success: true,
            data: {
                rooms: {
                    total: parseInt(totalRooms.rows[0].count),
                    available: parseInt(availableRooms.rows[0].count),
                    occupied: occupiedRoomsCount,
                    occupancyRate: parseFloat(occupancyRate)
                },
                tenants: {
                    active: parseInt(activeTenants.rows[0].count)
                },
                invoices: {
                    pending: parseInt(pendingInvoices.rows[0].count),
                    pendingAmount: parseFloat(pendingAmount.rows[0].total)
                },
                financial: {
                    monthlyIncome: parseFloat(monthlyIncome.rows[0].total),
                    monthlyExpense: parseFloat(monthlyExpense.rows[0].total),
                    netIncome: parseFloat(monthlyIncome.rows[0].total) - parseFloat(monthlyExpense.rows[0].total)
                },
                dueSoonInvoices: dueSoon.rows
            }
        });
    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get financial trend (last 6 months)
exports.getFinancialTrend = async (req, res) => {
    try {
        const result = await db.query(`
      SELECT 
        TO_CHAR(date, 'YYYY-MM') as month,
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE date >= CURRENT_DATE - INTERVAL '6 months'
      GROUP BY TO_CHAR(date, 'YYYY-MM')
      ORDER BY month ASC
    `);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get financial trend error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get tenant dashboard (for tenant user)
exports.getTenantDashboard = async (req, res) => {
    try {
        const userId = req.user.id;

        // Get tenant info
        const tenant = await db.query(`
      SELECT t.*, r.room_number, r.type, r.price, r.facilities
      FROM tenants t
      LEFT JOIN rooms r ON t.room_id = r.id
      WHERE t.user_id = $1
    `, [userId]);

        if (tenant.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Data penyewa tidak ditemukan'
            });
        }

        const tenantData = tenant.rows[0];

        // Get latest unpaid invoice
        const latestInvoice = await db.query(`
      SELECT * FROM invoices
      WHERE tenant_id = $1 AND status = 'unpaid'
      ORDER BY due_date ASC
      LIMIT 1
    `, [tenantData.id]);

        // Get payment history (only successful payments)
        const paymentHistory = await db.query(`
      SELECT i.*, p.paid_at as payment_date, p.method as payment_method, p.status, p.amount as payment_amount, p.midtrans_order_id, p.midtrans_transaction_id
      FROM invoices i
      JOIN payments p ON i.id = p.invoice_id
      WHERE i.tenant_id = $1
      AND p.status = 'success'
      ORDER BY p.paid_at DESC
      LIMIT 10
    `, [tenantData.id]);

        res.json({
            success: true,
            data: {
                tenant: tenantData,
                latestInvoice: latestInvoice.rows[0] || null,
                paymentHistory: paymentHistory.rows
            }
        });
    } catch (error) {
        console.error('Get tenant dashboard error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

module.exports = exports;
