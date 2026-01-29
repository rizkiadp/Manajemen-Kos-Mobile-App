# Kost Sejahtera - Backend API

Backend REST API untuk aplikasi Kost Sejahtera menggunakan Node.js, Express, dan PostgreSQL.

## 🚀 Features

- ✅ JWT Authentication
- ✅ Role-based access control (Admin/Tenant)
- ✅ PostgreSQL database
- ✅ Midtrans payment gateway integration
- ✅ RESTful API
- ✅ Input validation
- ✅ Error handling
- ✅ CORS enabled

## 📋 Prerequisites

- Node.js 16+ 
- PostgreSQL 14+
- npm atau yarn

## 🔧 Installation

### 1. Install Dependencies

```bash
cd kost-sejahtera-backend
npm install
```

### 2. Setup PostgreSQL Database

```bash
# Login ke PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE kost_sejahtera;

# Exit psql
\q
```

### 3. Run Database Migration

```bash
# Import schema
psql -U postgres -d kost_sejahtera -f src/database/schema.sql
```

### 4. Configure Environment

```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env dengan kredensial Anda
```

**Edit `.env`:**
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kost_sejahtera
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your_super_secret_key_here

MIDTRANS_SERVER_KEY=your_midtrans_server_key
MIDTRANS_CLIENT_KEY=your_midtrans_client_key
```

### 5. Run Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

Server akan berjalan di `http://localhost:3000`

## 📚 API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone": "08123456789",
  "role": "tenant"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "name": "John Doe",
      "role": "tenant"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer {token}
```

### Rooms

#### Get All Rooms
```http
GET /api/rooms?type=VIP&available=true&search=A-101
```

#### Get Room by ID
```http
GET /api/rooms/:id
```

#### Create Room (Admin Only)
```http
POST /api/rooms
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "room_number": "A-101",
  "type": "VIP",
  "floor": 1,
  "wing": "Kiri",
  "price": 2500000,
  "facilities": ["AC", "WiFi", "KM Dalam"],
  "images": []
}
```

#### Update Room (Admin Only)
```http
PUT /api/rooms/:id
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "price": 2600000,
  "is_available": false
}
```

#### Delete Room (Admin Only)
```http
DELETE /api/rooms/:id
Authorization: Bearer {admin_token}
```

### Payments

#### Create Transaction
```http
POST /api/payments/create-transaction
Authorization: Bearer {token}
Content-Type: application/json

{
  "invoice_id": 1,
  "payment_method": "bank_transfer"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "token": "midtrans_token_here",
    "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/..."
  }
}
```

#### Check Payment Status
```http
GET /api/payments/status/:order_id
Authorization: Bearer {token}
```

#### Webhook (Midtrans)
```http
POST /api/payments/webhook
Content-Type: application/json

{
  "order_id": "INV-2024-001",
  "transaction_status": "settlement",
  ...
}
```

## 🗄️ Database Schema

### Tables

- **users** - User accounts (admin & tenant)
- **rooms** - Room information
- **tenants** - Tenant details
- **invoices** - Billing invoices
- **transactions** - Financial transactions
- **payments** - Payment records

See `src/database/schema.sql` for complete schema.

## 🔐 Authentication

API menggunakan JWT (JSON Web Token) untuk authentication.

**Header format:**
```
Authorization: Bearer {your_jwt_token}
```

Token expires dalam 7 hari (configurable di `.env`).

## 🛡️ Authorization

- **Public**: `/api/auth/register`, `/api/auth/login`, `/api/rooms` (GET)
- **Authenticated**: `/api/auth/me`, `/api/payments/*`
- **Admin Only**: `/api/rooms` (POST, PUT, DELETE)

## 💳 Midtrans Integration

### Setup Webhook URL

Di Midtrans Dashboard:
1. Go to Settings → Configuration
2. Set Payment Notification URL: `https://your-domain.com/api/payments/webhook`
3. Save

### Test Payment (Sandbox)

**Virtual Account:**
- Akan generate nomor VA otomatis
- Use Midtrans simulator untuk complete payment

**GoPay:**
- Phone: any
- OTP: `123456`

**Credit Card:**
- Card: `4811 1111 1111 1114`
- CVV: `123`
- Exp: any future date

## 📁 Project Structure

```
kost-sejahtera-backend/
├── src/
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── roomController.js
│   │   └── paymentController.js
│   ├── middleware/
│   │   └── auth.js
│   ├── routes/
│   │   └── index.js
│   ├── database/
│   │   ├── db.js
│   │   └── schema.sql
│   └── server.js
├── .env.example
├── package.json
└── README.md
```

## 🧪 Testing

### Using cURL

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","name":"Test User","phone":"08123456789"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Get rooms
curl http://localhost:3000/api/rooms
```

### Using Postman

Import collection dari dokumentasi atau buat manual sesuai endpoint di atas.

## 🚀 Deployment

### Heroku

```bash
# Login to Heroku
heroku login

# Create app
heroku create kost-sejahtera-api

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set JWT_SECRET=your_secret
heroku config:set MIDTRANS_SERVER_KEY=your_key

# Deploy
git push heroku main

# Run migration
heroku pg:psql < src/database/schema.sql
```

### Railway

1. Connect GitHub repository
2. Add PostgreSQL database
3. Set environment variables
4. Deploy automatically

### VPS (Ubuntu)

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Clone & setup
git clone your-repo
cd kost-sejahtera-backend
npm install
npm start

# Use PM2 for production
npm install -g pm2
pm2 start src/server.js --name kost-api
pm2 save
pm2 startup
```

## 🐛 Troubleshooting

### Database connection error
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check credentials in .env
```

### JWT token invalid
```bash
# Make sure JWT_SECRET is set in .env
# Token might be expired (default 7 days)
```

### Midtrans webhook not working
```bash
# Make sure webhook URL is publicly accessible (use ngrok for local testing)
ngrok http 3000
# Then set webhook URL in Midtrans dashboard
```

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 3000 |
| DB_HOST | PostgreSQL host | localhost |
| DB_PORT | PostgreSQL port | 5432 |
| DB_NAME | Database name | kost_sejahtera |
| DB_USER | Database user | postgres |
| DB_PASSWORD | Database password | - |
| JWT_SECRET | JWT secret key | - |
| JWT_EXPIRES_IN | Token expiration | 7d |
| MIDTRANS_SERVER_KEY | Midtrans server key | - |
| MIDTRANS_CLIENT_KEY | Midtrans client key | - |
| MIDTRANS_IS_PRODUCTION | Production mode | false |

## 📄 License

Private Project - All Rights Reserved

## 🤝 Support

Untuk bantuan, buka issue di repository atau hubungi developer.
