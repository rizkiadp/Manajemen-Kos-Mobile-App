# Quick Setup Guide

## 1. Install PostgreSQL

Download dari: https://www.postgresql.org/download/windows/

Saat install, ingat password yang Anda set untuk user `postgres`.

## 2. Create Database

Buka **pgAdmin** atau **psql**, lalu jalankan:

```sql
CREATE DATABASE kost_sejahtera;
```

Atau via command line:

```bash
# Login ke PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE kost_sejahtera;

# Exit
\q
```

## 3. Setup Environment

```bash
# Copy .env.example ke .env
cp .env.example .env
```

Edit file `.env` dan isi dengan kredensial Anda:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kost_sejahtera
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD  # <-- Ganti ini!

JWT_SECRET=your_super_secret_key_here_change_in_production

MIDTRANS_SERVER_KEY=SB-Mid-server-YOUR_KEY
MIDTRANS_CLIENT_KEY=SB-Mid-client-YOUR_KEY
```

## 4. Install Dependencies

```bash
npm install
```

## 5. Run Migration (Create Tables)

```bash
npm run migrate
```

Output yang benar:
```
🔄 Running database migration...
✅ Migration completed successfully!
📊 Tables created:
   - users
   - rooms
   - tenants
   - invoices
   - transactions
   - payments
```

## 6. Seed Database (Sample Data)

```bash
npm run seed
```

Output yang benar:
```
🌱 Seeding database...
✅ Connected to PostgreSQL database
✅ Admin user created
   Email: admin@kostsejahtera.com
   Password: admin123
✅ 5 sample rooms created
✅ Sample tenant created
   Email: budi@example.com
   Password: tenant123
   Room: A-101
   Invoice: INV-2024-001
✅ Database seeding completed!
```

## 7. Start Server

```bash
# Development mode (auto-reload)
npm run dev

# Production mode
npm start
```

Output:
```
🚀 Server running on port 3000
📝 Environment: development
🔗 API URL: http://localhost:3000/api
✅ Connected to PostgreSQL database
```

## 8. Test API

Buka browser atau Postman, test endpoint:

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

## 9. Test Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@kostsejahtera.com\",\"password\":\"admin123\"}"
```

## Troubleshooting

### Error: "client password must be a string"
- Pastikan DB_PASSWORD di `.env` sudah diisi (tidak kosong)
- Pastikan tidak ada quotes di sekitar password

### Error: "database does not exist"
- Jalankan: `CREATE DATABASE kost_sejahtera;` di PostgreSQL

### Error: "relation does not exist"
- Jalankan migration dulu: `npm run migrate`

### Error: "Connection refused"
- Pastikan PostgreSQL service running
- Windows: Check di Services
- Atau restart: `net stop postgresql-x64-14` lalu `net start postgresql-x64-14`

## Default Credentials

**Admin:**
- Email: `admin@kostsejahtera.com`
- Password: `admin123`

**Tenant:**
- Email: `budi@example.com`
- Password: `tenant123`

## Next Steps

1. ✅ Backend running
2. Update Flutter app API URL
3. Test login dari Flutter app
4. Deploy to production

---

**Happy Coding! 🚀**
