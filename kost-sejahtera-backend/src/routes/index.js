const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController');
const roomController = require('../controllers/roomController');
const tenantController = require('../controllers/tenantController');
const invoiceController = require('../controllers/invoiceController');
const transactionController = require('../controllers/transactionController');
const dashboardController = require('../controllers/dashboardController');
const paymentController = require('../controllers/paymentController');
const maintenanceController = require('../controllers/maintenanceController');
const messageController = require('../controllers/messageController');
const { authMiddleware, adminOnly } = require('../middleware/auth');

// Auth routes
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.get('/auth/me', authMiddleware, authController.getMe);

// Dashboard routes
router.get('/dashboard/admin', authMiddleware, adminOnly, dashboardController.getDashboardStats);
router.get('/dashboard/tenant', authMiddleware, dashboardController.getTenantDashboard);
router.get('/dashboard/financial-trend', authMiddleware, adminOnly, dashboardController.getFinancialTrend);

// Room routes
router.get('/rooms', roomController.getAllRooms);
router.get('/rooms/:id', roomController.getRoomById);
router.post('/rooms', authMiddleware, adminOnly, roomController.createRoom);
router.put('/rooms/:id', authMiddleware, adminOnly, roomController.updateRoom);
router.delete('/rooms/:id', authMiddleware, adminOnly, roomController.deleteRoom);

// Tenant routes
router.get('/tenants', authMiddleware, adminOnly, tenantController.getAllTenants);
router.get('/tenants/me', authMiddleware, tenantController.getTenantByUserId);
router.get('/tenants/:id', authMiddleware, tenantController.getTenantById);
router.post('/tenants', authMiddleware, adminOnly, tenantController.createTenant);
router.put('/tenants/:id', authMiddleware, adminOnly, tenantController.updateTenant);
router.delete('/tenants/:id', authMiddleware, adminOnly, tenantController.deleteTenant);
router.put('/tenants/:id/move-out', authMiddleware, adminOnly, tenantController.moveOutTenant);

// Invoice routes
router.get('/invoices', authMiddleware, invoiceController.getAllInvoices);
router.get('/invoices/me', authMiddleware, invoiceController.getInvoicesByUserId);
router.get('/invoices/:id', authMiddleware, invoiceController.getInvoiceById);
router.post('/invoices', authMiddleware, adminOnly, invoiceController.createInvoice);
router.put('/invoices/:id', authMiddleware, adminOnly, invoiceController.updateInvoice);
router.delete('/invoices/:id', authMiddleware, adminOnly, invoiceController.deleteInvoice);

// Transaction routes
router.get('/transactions', authMiddleware, adminOnly, transactionController.getAllTransactions);
router.get('/transactions/summary', authMiddleware, adminOnly, transactionController.getTransactionSummary);
router.post('/transactions', authMiddleware, adminOnly, transactionController.createTransaction);

router.post('/payments/create-transaction', authMiddleware, paymentController.createTransaction);
router.post('/payments/webhook', paymentController.handleWebhook);
router.get('/payments/status/:order_id', authMiddleware, paymentController.checkStatus);

// Maintenance Report routes
router.post('/maintenance-reports', authMiddleware, maintenanceController.createReport);
router.get('/maintenance-reports', authMiddleware, maintenanceController.getReports);
router.get('/maintenance-reports/pending-count', authMiddleware, adminOnly, maintenanceController.getPendingCount);
router.get('/maintenance-reports/:id', authMiddleware, maintenanceController.getReportById);
router.put('/maintenance-reports/:id', authMiddleware, adminOnly, maintenanceController.updateReportStatus);
router.delete('/maintenance-reports/:id', authMiddleware, adminOnly, maintenanceController.deleteReport);

// Message routes
router.post('/messages', authMiddleware, messageController.sendMessage);
router.get('/messages/conversation/:reportId', authMiddleware, messageController.getConversation);
router.get('/messages/unread-count', authMiddleware, messageController.getUnreadCount);
router.put('/messages/:id/read', authMiddleware, messageController.markAsRead);

module.exports = router;
