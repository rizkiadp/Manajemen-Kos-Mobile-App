const db = require('../database/db');

// Get all transactions
exports.getAllTransactions = async (req, res) => {
    try {
        const { type, category, start_date, end_date } = req.query;

        let query = 'SELECT * FROM transactions WHERE 1=1';
        const params = [];
        let paramCount = 1;

        if (type) {
            query += ` AND type = $${paramCount}`;
            params.push(type);
            paramCount++;
        }

        if (category) {
            query += ` AND category = $${paramCount}`;
            params.push(category);
            paramCount++;
        }

        if (start_date) {
            query += ` AND date >= $${paramCount}`;
            params.push(start_date);
            paramCount++;
        }

        if (end_date) {
            query += ` AND date <= $${paramCount}`;
            params.push(end_date);
            paramCount++;
        }

        query += ' ORDER BY date DESC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get transactions error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Create transaction
exports.createTransaction = async (req, res) => {
    try {
        const { type, category, amount, description, date, tenant_id, invoice_id } = req.body;
        const created_by = req.user.id;

        const result = await db.query(
            `INSERT INTO transactions (type, category, amount, description, date, tenant_id, invoice_id, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
            [type, category, amount, description, date, tenant_id, invoice_id, created_by]
        );

        res.status(201).json({
            success: true,
            message: 'Transaksi berhasil ditambahkan',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create transaction error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

// Get transaction summary
exports.getTransactionSummary = async (req, res) => {
    try {
        const { start_date, end_date } = req.query;

        let dateFilter = '';
        const params = [];

        if (start_date && end_date) {
            dateFilter = 'WHERE date BETWEEN $1 AND $2';
            params.push(start_date, end_date);
        }

        const result = await db.query(`
      SELECT 
        type,
        COUNT(*) as count,
        SUM(amount) as total
      FROM transactions
      ${dateFilter}
      GROUP BY type
    `, params);

        const summary = {
            income: { count: 0, total: 0 },
            expense: { count: 0, total: 0 }
        };

        result.rows.forEach(row => {
            summary[row.type] = {
                count: parseInt(row.count),
                total: parseFloat(row.total)
            };
        });

        summary.net = summary.income.total - summary.expense.total;

        res.json({
            success: true,
            data: summary
        });
    } catch (error) {
        console.error('Get transaction summary error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan server'
        });
    }
};

module.exports = exports;
