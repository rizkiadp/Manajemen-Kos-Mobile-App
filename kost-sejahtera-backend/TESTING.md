# Testing Guide - Kost Sejahtera Backend

## 🧪 Cara Testing Backend

### 1. Jalankan Seed Database

```bash
npm run seed
```

Expected output:
```
✅ Admin user created
   Email: admin@kostsejahtera.com
   Password: admin123
✅ 5 sample rooms created
✅ Sample tenant created
```

### 2. Start Server

```bash
npm run dev
```

Server akan berjalan di: `http://localhost:3000`

---

## 📝 Test dengan Browser

### Health Check

Buka browser, akses:
```
http://localhost:3000/health
```

Response:
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-01-29T..."
}
```

### Get All Rooms (Public)

```
http://localhost:3000/api/rooms
```

---

## 🔧 Test dengan Postman/Thunder Client

### 1. Login Admin

**Request:**
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "admin@kostsejahtera.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "email": "admin@kostsejahtera.com",
      "name": "Admin",
      "role": "admin"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**COPY TOKEN INI!** Anda akan butuh untuk request selanjutnya.

---

### 2. Get Current User

**Request:**
```
GET http://localhost:3000/api/auth/me
Authorization: Bearer YOUR_TOKEN_HERE
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "admin@kostsejahtera.com",
    "name": "Admin",
    "role": "admin"
  }
}
```

---

### 3. Get All Rooms

**Request:**
```
GET http://localhost:3000/api/rooms
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "room_number": "A-101",
      "type": "VIP",
      "price": "2500000.00",
      "facilities": ["AC", "WiFi", "KM Dalam"],
      "is_available": false
    },
    ...
  ]
}
```

---

### 4. Create Room (Admin Only)

**Request:**
```
POST http://localhost:3000/api/rooms
Authorization: Bearer YOUR_ADMIN_TOKEN
Content-Type: application/json

{
  "room_number": "C-302",
  "type": "Standard",
  "floor": 3,
  "wing": "Tengah",
  "price": 1800000,
  "facilities": ["WiFi", "KM Dalam", "Kasur"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Kamar berhasil ditambahkan",
  "data": {
    "id": 6,
    "room_number": "C-302",
    "type": "Standard",
    "price": "1800000.00",
    ...
  }
}
```

---

### 5. Update Room (Admin Only)

**Request:**
```
PUT http://localhost:3000/api/rooms/1
Authorization: Bearer YOUR_ADMIN_TOKEN
Content-Type: application/json

{
  "price": 2600000,
  "is_available": true
}
```

---

### 6. Login Tenant

**Request:**
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "budi@example.com",
  "password": "tenant123"
}
```

---

### 7. Create Payment Transaction

**Request:**
```
POST http://localhost:3000/api/payments/create-transaction
Authorization: Bearer YOUR_TENANT_TOKEN
Content-Type: application/json

{
  "invoice_id": 1,
  "payment_method": "bank_transfer"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Transaksi berhasil dibuat",
  "data": {
    "payment_id": 1,
    "token": "midtrans_snap_token",
    "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/..."
  }
}
```

---

## 💻 Test dengan cURL (Command Line)

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@kostsejahtera.com\",\"password\":\"admin123\"}"
```

### Get Rooms
```bash
curl http://localhost:3000/api/rooms
```

### Get Rooms dengan Filter
```bash
curl "http://localhost:3000/api/rooms?type=VIP&available=true"
```

### Create Room (dengan token)
```bash
curl -X POST http://localhost:3000/api/rooms \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d "{\"room_number\":\"D-401\",\"type\":\"VIP\",\"floor\":4,\"wing\":\"Kanan\",\"price\":2700000,\"facilities\":[\"AC\",\"WiFi\",\"Balkon\"]}"
```

---

## 🔍 Test Scenarios

### Scenario 1: Admin Flow
1. ✅ Login sebagai admin
2. ✅ Get current user (verify role = admin)
3. ✅ Get all rooms
4. ✅ Create new room
5. ✅ Update room price
6. ✅ Delete room

### Scenario 2: Tenant Flow
1. ✅ Login sebagai tenant
2. ✅ Get current user (verify role = tenant)
3. ✅ View available rooms
4. ✅ Create payment transaction
5. ✅ Check payment status

### Scenario 3: Authorization Test
1. ✅ Try to create room without token (should fail)
2. ✅ Try to create room with tenant token (should fail - admin only)
3. ✅ Try to access protected endpoint without token (should fail)

---

## 🧪 Testing Checklist

### Authentication
- [ ] Register new user
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should fail)
- [ ] Get current user with valid token
- [ ] Get current user without token (should fail)

### Rooms
- [ ] Get all rooms (public)
- [ ] Get rooms with filters (type, available, search)
- [ ] Get single room by ID
- [ ] Create room as admin
- [ ] Create room as tenant (should fail)
- [ ] Update room as admin
- [ ] Delete room as admin

### Payments
- [ ] Create payment transaction
- [ ] Check payment status
- [ ] Webhook simulation (advanced)

---

## 🎯 Expected Results

### ✅ Success Cases
- Status code: `200` or `201`
- Response has `"success": true`
- Data is returned correctly

### ❌ Error Cases
- **401 Unauthorized**: Token tidak valid/tidak ada
- **403 Forbidden**: Role tidak sesuai (tenant trying admin action)
- **404 Not Found**: Resource tidak ditemukan
- **400 Bad Request**: Data tidak valid

---

## 🔧 Tools untuk Testing

### 1. **Postman** (Recommended)
- Download: https://www.postman.com/downloads/
- Import collection atau buat manual
- Save token sebagai environment variable

### 2. **Thunder Client** (VS Code Extension)
- Install dari VS Code Extensions
- Lightweight alternative to Postman
- Integrated dalam VS Code

### 3. **REST Client** (VS Code Extension)
- Create `.http` files
- Run requests directly from VS Code

### 4. **Browser**
- Good for GET requests
- Install JSON Formatter extension

### 5. **cURL**
- Command line tool
- Good for automation

---

## 📊 Sample Test File (REST Client)

Create file: `test.http`

```http
### Health Check
GET http://localhost:3000/health

### Login Admin
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "admin@kostsejahtera.com",
  "password": "admin123"
}

### Get Rooms
GET http://localhost:3000/api/rooms

### Create Room
POST http://localhost:3000/api/rooms
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json

{
  "room_number": "E-501",
  "type": "VIP",
  "floor": 5,
  "wing": "Kiri",
  "price": 2800000,
  "facilities": ["AC", "WiFi", "KM Dalam", "Balkon"]
}
```

---

## 🐛 Common Issues

### Server tidak start
```bash
# Check if port 3000 is already in use
netstat -ano | findstr :3000

# Kill process if needed
taskkill /PID <PID> /F
```

### Database connection error
- Check PostgreSQL is running
- Verify credentials in `.env`
- Test connection: `psql -U postgres -d kost_sejahtera`

### Token expired
- Login again to get new token
- Default expiry: 7 days

---

## ✅ Quick Test Commands

```bash
# 1. Seed database
npm run seed

# 2. Start server
npm run dev

# 3. Test health (new terminal)
curl http://localhost:3000/health

# 4. Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@kostsejahtera.com\",\"password\":\"admin123\"}"

# 5. Test get rooms
curl http://localhost:3000/api/rooms
```

---

**Happy Testing! 🧪**
