const db = require('../database/db');

// Create new maintenance report
exports.createReport = async (req, res) => {
    try {
        const { title, description, category, priority, image_url } = req.body;
        const userId = req.user.id;

        // Get tenant_id and room_id from user
        const tenantResult = await db.query(
            'SELECT id, room_id FROM tenants WHERE user_id = $1',
            [userId]
        );

        if (tenantResult.rows.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Only tenants can create maintenance reports'
            });
        }

        const tenant = tenantResult.rows[0];

        const result = await db.query(
            `INSERT INTO maintenance_reports 
            (tenant_id, room_id, title, description, category, priority, image_url)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *`,
            [tenant.id, tenant.room_id, title, description, category, priority || 'medium', image_url]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create report'
        });
    }
};

// Get all reports (admin) or user's reports (tenant)
exports.getReports = async (req, res) => {
    try {
        const userId = req.user.id;
        const userRole = req.user.role;
        const { status, category, priority } = req.query;

        let query = `
            SELECT mr.*, 
                   tu.name as tenant_name,
                   r.room_number,
                   u.name as resolved_by_name
            FROM maintenance_reports mr
            LEFT JOIN tenants t ON mr.tenant_id = t.id
            LEFT JOIN users tu ON t.user_id = tu.id
            LEFT JOIN rooms r ON mr.room_id = r.id
            LEFT JOIN users u ON mr.resolved_by = u.id
        `;

        const conditions = [];
        const params = [];
        let paramCount = 1;

        // If tenant, only show their reports
        if (userRole === 'tenant') {
            const tenantResult = await db.query(
                'SELECT id FROM tenants WHERE user_id = $1',
                [userId]
            );
            if (tenantResult.rows.length > 0) {
                conditions.push(`mr.tenant_id = $${paramCount}`);
                params.push(tenantResult.rows[0].id);
                paramCount++;
            }
        }

        // Apply filters
        if (status) {
            conditions.push(`mr.status = $${paramCount}`);
            params.push(status);
            paramCount++;
        }
        if (category) {
            conditions.push(`mr.category = $${paramCount}`);
            params.push(category);
            paramCount++;
        }
        if (priority) {
            conditions.push(`mr.priority = $${paramCount}`);
            params.push(priority);
            paramCount++;
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY mr.created_at DESC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get reports error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch reports'
        });
    }
};

// Get single report details
exports.getReportById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const userRole = req.user.role;

        const result = await db.query(
            `SELECT mr.*, 
                    tu.name as tenant_name,
                    t.user_id as tenant_user_id,
                    r.room_number,
                    u.name as resolved_by_name
             FROM maintenance_reports mr
             LEFT JOIN tenants t ON mr.tenant_id = t.id
             LEFT JOIN users tu ON t.user_id = tu.id
             LEFT JOIN rooms r ON mr.room_id = r.id
             LEFT JOIN users u ON mr.resolved_by = u.id
             WHERE mr.id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        const report = result.rows[0];

        // Check if tenant is authorized
        if (userRole === 'tenant' && report.tenant_user_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Unauthorized'
            });
        }

        res.json({
            success: true,
            data: report
        });
    } catch (error) {
        console.error('Get report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch report'
        });
    }
};

// Update report status (admin only)
exports.updateReportStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const userId = req.user.id;

        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admin can update report status'
            });
        }

        let query;
        let params;

        // If marking as resolved, set resolved_at and resolved_by
        if (status === 'resolved' || status === 'closed') {
            query = `UPDATE maintenance_reports 
                     SET status = $1, resolved_at = CURRENT_TIMESTAMP, resolved_by = $2
                     WHERE id = $3
                     RETURNING *`;
            params = [status, userId, id];
        } else {
            query = `UPDATE maintenance_reports 
                     SET status = $1
                     WHERE id = $2
                     RETURNING *`;
            params = [status, id];
        }

        const result = await db.query(query, params);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Update report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update report'
        });
    }
};

// Delete report (admin only)
exports.deleteReport = async (req, res) => {
    try {
        const { id } = req.params;

        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only admin can delete reports'
            });
        }

        const result = await db.query(
            'DELETE FROM maintenance_reports WHERE id = $1 RETURNING id',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        res.json({
            success: true,
            message: 'Report deleted successfully'
        });
    } catch (error) {
        console.error('Delete report error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete report'
        });
    }
};

// Get pending reports count (for admin notification badge)
exports.getPendingCount = async (req, res) => {
    try {
        const result = await db.query(
            "SELECT COUNT(*) as count FROM maintenance_reports WHERE status = 'pending'"
        );

        res.json({
            success: true,
            count: parseInt(result.rows[0].count)
        });
    } catch (error) {
        console.error('Get pending count error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending count'
        });
    }
};
