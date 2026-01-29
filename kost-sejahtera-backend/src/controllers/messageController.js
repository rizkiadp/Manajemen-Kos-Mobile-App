const db = require('../database/db');

// Send message
exports.sendMessage = async (req, res) => {
    try {
        console.log('DEBUG: sendMessage body:', req.body);
        let { report_id, message, receiver_id } = req.body;
        const senderId = req.user.id;
        console.log('DEBUG: senderId:', senderId);

        // Ensure report_id is a number if it comes as string
        report_id = parseInt(report_id);
        let actualReceiverId = receiver_id;

        // Handle Direct Chat (Negative report_id or 0)
        // Tenant sends 0 for general chat
        if (report_id <= 0) {
            console.log('Processing Direct Chat, report_id <= 0');
            const tenantId = Math.abs(report_id);
            console.log('Tenant ID extracted:', tenantId);

            let tenantUserId;
            let actualReceiverId = receiver_id;

            if (tenantId === 0) {
                // From Tenant Chat
                if (req.user.role !== 'tenant') {
                    return res.status(400).json({
                        success: false,
                        message: 'Invalid report ID'
                    });
                }
                tenantUserId = senderId;
            } else {
                // From Admin (negative ID)
                // Get tenant's user_id
                const tenantData = await db.query(
                    `SELECT user_id FROM tenants WHERE id = $1`,
                    [tenantId]
                );

                if (tenantData.rows.length === 0) {
                    console.log('Tenant not found in DB');
                    return res.status(404).json({
                        success: false,
                        message: 'Tenant not found'
                    });
                }
                tenantUserId = tenantData.rows[0].user_id;
            }

            // If admin sending, receiver is tenant
            if (req.user.role === 'admin') {
                actualReceiverId = tenantUserId;
            } else {
                // If tenant sending, receiver is admin
                // Check authorization if needed (sender must be tenantUserId)
                if (senderId !== tenantUserId) {
                    return res.status(403).json({
                        success: false,
                        message: 'Unauthorized'
                    });
                }

                // Receiver is admin (find first admin)
                if (!actualReceiverId) {
                    const adminResult = await db.query(
                        "SELECT id FROM users WHERE role = 'admin' LIMIT 1"
                    );
                    if (adminResult.rows.length > 0) {
                        actualReceiverId = adminResult.rows[0].id;
                    }
                }
            }

            console.log('Sending direct message to:', actualReceiverId);

            // For direct chat, report_id is NULL
            // We use a clean query for this
            const result = await db.query(
                `INSERT INTO messages (sender_id, receiver_id, report_id, message)
                 VALUES ($1, $2, NULL, $3)
                 RETURNING *`,
                [senderId, actualReceiverId, message]
            );

            return res.status(201).json({
                success: true,
                data: result.rows[0]
            });
        }

        // Regular Report Chat
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

        // Handle Direct Chat (Negative reportId or 0)
        // Tenant sends 0 for general chat
        if (parseInt(reportId) <= 0) {
            const val = parseInt(reportId);
            const tenantId = Math.abs(val);

            let tenantUserId;

            if (tenantId === 0) {
                // Tenant requesting own chat (0)
                if (req.user.role === 'tenant') {
                    tenantUserId = userId;
                } else {
                    // Admin cannot request "0". Must specify tenant.
                    return res.status(400).json({
                        success: false,
                        message: 'Admin must specify tenant ID'
                    });
                }
            } else {
                // Negative ID provided (Specific tenant)
                // Get tenant's user_id
                const tenantData = await db.query(
                    `SELECT user_id FROM tenants WHERE id = $1`,
                    [tenantId]
                );

                if (tenantData.rows.length === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Tenant not found'
                    });
                }
                tenantUserId = tenantData.rows[0].user_id; // This is the user_id of the tenant
            }

            // Verify access (must be admin or the tenant themselves)
            if (req.user.role !== 'admin' && userId !== tenantUserId) {
                return res.status(403).json({
                    success: false,
                    message: 'Unauthorized'
                });
            }

            // Determine the relationship for query
            // We want messages between (Admin(s) AND Tenant) where report_id IS NULL

            const result = await db.query(
                `SELECT m.*, 
                        sender.name as sender_name,
                        sender.role as sender_role,
                        receiver.name as receiver_name
                 FROM messages m
                 JOIN users sender ON m.sender_id = sender.id
                 JOIN users receiver ON m.receiver_id = receiver.id
                 WHERE m.report_id IS NULL 
                 AND (
                    (m.sender_id = $1 OR m.receiver_id = $1)
                 )
                 ORDER BY m.created_at ASC`,
                [tenantUserId]
            );

            // Mark messages as read if user is receiver
            await db.query(
                `UPDATE messages 
                 SET is_read = true 
                 WHERE report_id IS NULL 
                 AND receiver_id = $1 AND is_read = false`,
                [userId]
            );

            return res.json({
                success: true,
                data: result.rows
            });
        }

        // Regular Report Chat
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
