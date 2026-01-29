const db = require('../database/db');

// Send message
exports.sendMessage = async (req, res) => {
    try {
        const { report_id, message, receiver_id } = req.body;
        const senderId = req.user.id;

        // Verify report exists and user has access
        const reportCheck = await db.query(
            `SELECT mr.*, t.user_id as tenant_user_id
             FROM maintenance_reports mr
             LEFT JOIN tenants t ON mr.tenant_id = t.id
             WHERE mr.id = $1`,
            [report_id]
        );

        if (reportCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        const report = reportCheck.rows[0];

        // Verify user is either the tenant or admin
        if (req.user.role !== 'admin' && report.tenant_user_id !== senderId) {
            return res.status(403).json({
                success: false,
                message: 'Unauthorized'
            });
        }

        // Determine receiver if not specified
        let actualReceiverId = receiver_id;
        if (!actualReceiverId) {
            if (req.user.role === 'admin') {
                // Admin sending to tenant
                actualReceiverId = report.tenant_user_id;
            } else {
                // Tenant sending to admin (get first admin)
                const adminResult = await db.query(
                    "SELECT id FROM users WHERE role = 'admin' LIMIT 1"
                );
                if (adminResult.rows.length > 0) {
                    actualReceiverId = adminResult.rows[0].id;
                }
            }
        }

        const result = await db.query(
            `INSERT INTO messages (sender_id, receiver_id, report_id, message)
             VALUES ($1, $2, $3, $4)
             RETURNING *`,
            [senderId, actualReceiverId, report_id, message]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Send message error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to send message'
        });
    }
};

// Get conversation for a report
exports.getConversation = async (req, res) => {
    try {
        const { reportId } = req.params;
        const userId = req.user.id;

        // Verify user has access to this report
        const reportCheck = await db.query(
            `SELECT mr.*, t.user_id as tenant_user_id
             FROM maintenance_reports mr
             LEFT JOIN tenants t ON mr.tenant_id = t.id
             WHERE mr.id = $1`,
            [reportId]
        );

        if (reportCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Report not found'
            });
        }

        const report = reportCheck.rows[0];

        if (req.user.role !== 'admin' && report.tenant_user_id !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Unauthorized'
            });
        }

        // Get all messages for this report
        const result = await db.query(
            `SELECT m.*, 
                    sender.name as sender_name,
                    sender.role as sender_role,
                    receiver.name as receiver_name
             FROM messages m
             JOIN users sender ON m.sender_id = sender.id
             JOIN users receiver ON m.receiver_id = receiver.id
             WHERE m.report_id = $1
             ORDER BY m.created_at ASC`,
            [reportId]
        );

        // Mark messages as read if user is receiver
        await db.query(
            `UPDATE messages 
             SET is_read = true 
             WHERE report_id = $1 AND receiver_id = $2 AND is_read = false`,
            [reportId, userId]
        );

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Get conversation error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch conversation'
        });
    }
};

// Get unread message count
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await db.query(
            'SELECT COUNT(*) as count FROM messages WHERE receiver_id = $1 AND is_read = false',
            [userId]
        );

        res.json({
            success: true,
            count: parseInt(result.rows[0].count)
        });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch unread count'
        });
    }
};

// Mark message as read
exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const result = await db.query(
            `UPDATE messages 
             SET is_read = true 
             WHERE id = $1 AND receiver_id = $2
             RETURNING *`,
            [id, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Message not found or unauthorized'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Mark as read error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark message as read'
        });
    }
};
