# API Documentation - Kost Sejahtera Backend

Complete REST API documentation for Kost Sejahtera management system.

## Base URL
```
http://localhost:3000/api
```

---

## 🔐 Authentication

All authenticated endpoints require JWT token in header:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## 📋 Endpoints

### Authentication

#### POST /auth/register
Register new user

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone": "08123456789",
  "role": "tenant"
}
```

#### POST /auth/login
Login user

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { "id": 1, "name": "...", "role": "admin" },
    "token": "eyJhbGc..."
  }
}
```

#### GET /auth/me
Get current user (requires auth)

---

### Dashboard

#### GET /dashboard/admin
Get admin dashboard statistics (admin only)

**Response:**
```json
{
  "success": true,
  "data": {
    "rooms": {
      "total": 10,
      "available": 3,
      "occupied": 7,
      "occupancyRate": 70.0
    },
    "tenants": { "active": 7 },
    "invoices": {
      "pending": 5,
      "pendingAmount": 12500000
    },
    "financial": {
      "monthlyIncome": 15000000,
      "monthlyExpense": 2000000,
      "netIncome": 13000000
    },
    "dueSoonInvoices": [...]
  }
}
```

#### GET /dashboard/tenant
Get tenant dashboard (tenant only)

**Response:**
```json
{
  "success": true,
  "data": {
    "tenant": {...},
    "latestInvoice": {...},
    "paymentHistory": [...]
  }
}
```

#### GET /dashboard/financial-trend
Get 6-month financial trend (admin only)

---

### Rooms

#### GET /rooms
Get all rooms

**Query params:**
- `type` - Filter by type (VIP, Standard, Reguler)
- `available` - Filter by availability (true/false)
- `search` - Search by room number

**Example:**
```
GET /rooms?type=VIP&available=true
```

#### GET /rooms/:id
Get room by ID

#### POST /rooms
Create new room (admin only)

**Body:**
```json
{
  "room_number": "A-101",
  "type": "VIP",
  "floor": 1,
  "wing": "Kiri",
  "price": 2500000,
  "facilities": ["AC", "WiFi", "KM Dalam"]
}
```

#### PUT /rooms/:id
Update room (admin only)

#### DELETE /rooms/:id
Delete room (admin only)

---

### Tenants

#### GET /tenants
Get all tenants (admin only)

**Query params:**
- `status` - Filter by status (active/inactive)
- `payment_status` - Filter by payment status
- `search` - Search by name, email, or NIK

#### GET /tenants/me
Get current tenant data (tenant only)

#### GET /tenants/:id
Get tenant by ID

#### POST /tenants
Create new tenant (admin only)

**Body:**
```json
{
  "user_id": 1,
  "room_id": 1,
  "nik": "3201234567890123",
  "move_in_date": "2024-01-01"
}
```

#### PUT /tenants/:id
Update tenant (admin only)

#### DELETE /tenants/:id
Delete tenant (admin only)

---

### Invoices

#### GET /invoices
Get all invoices

**Query params:**
- `status` - Filter by status (paid/unpaid/overdue)
- `tenant_id` - Filter by tenant
- `period` - Filter by period

#### GET /invoices/me
Get current user's invoices (tenant only)

#### GET /invoices/:id
Get invoice by ID

#### POST /invoices
Create new invoice (admin only)

**Body:**
```json
{
  "tenant_id": 1,
  "room_id": 1,
  "period": "Januari 2024",
  "issue_date": "2024-01-01",
  "due_date": "2024-02-05",
  "items": [
    { "description": "Sewa Kamar", "amount": 2000000 },
    { "description": "Listrik", "amount": 300000 }
  ],
  "discount": 0
}
```

#### PUT /invoices/:id
Update invoice (admin only)

#### DELETE /invoices/:id
Delete invoice (admin only)

---

### Transactions

#### GET /transactions
Get all transactions (admin only)

**Query params:**
- `type` - Filter by type (income/expense)
- `category` - Filter by category
- `start_date` - Filter from date
- `end_date` - Filter to date

#### GET /transactions/summary
Get transaction summary (admin only)

**Query params:**
- `start_date` - Start date
- `end_date` - End date

**Response:**
```json
{
  "success": true,
  "data": {
    "income": { "count": 10, "total": 15000000 },
    "expense": { "count": 5, "total": 2000000 },
    "net": 13000000
  }
}
```

#### POST /transactions
Create transaction (admin only)

**Body:**
```json
{
  "type": "expense",
  "category": "Maintenance",
  "amount": 500000,
  "description": "Perbaikan AC",
  "date": "2024-01-15"
}
```

---

### Payments

#### POST /payments/create-transaction
Create payment transaction

**Body:**
```json
{
  "invoice_id": 1,
  "payment_method": "bank_transfer"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "token": "midtrans_token",
    "redirect_url": "https://..."
  }
}
```

#### POST /payments/webhook
Midtrans webhook handler (no auth required)

#### GET /payments/status/:order_id
Check payment status

---

## 📊 Response Format

### Success Response
```json
{
  "success": true,
  "message": "Optional message",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message"
}
```

---

## 🔒 Authorization Levels

- **Public**: No auth required
- **Authenticated**: Requires valid JWT token
- **Admin Only**: Requires admin role
- **Tenant Only**: Requires tenant role

---

## 📝 Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Server Error

---

## 🧪 Testing

See `TESTING.md` for detailed testing guide and `test.http` for ready-to-use requests.

---

**Total Endpoints: 35+**
