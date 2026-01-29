# Flutter App Setup Guide

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
cd kost_sejahtera
flutter pub get
```

### 2. Configure API URL

**Untuk Android Emulator:**
- Sudah dikonfigurasi menggunakan `10.0.2.2:3000`
- Tidak perlu ubah apa-apa

**Untuk Physical Device:**
1. Cari IP komputer Anda:
   ```bash
   ipconfig
   ```
   Cari **IPv4 Address** (contoh: 192.168.1.100)

2. Edit file: `lib/core/services/auth_service.dart`
   ```dart
   // Comment line ini:
   // final String _baseUrl = 'http://10.0.2.2:3000/api';
   
   // Uncomment dan ganti XXX dengan IP Anda:
   final String _baseUrl = 'http://192.168.1.XXX:3000/api';
   ```

### 3. Run Flutter App

```bash
flutter run
```

Pilih device (emulator atau physical device).

---

## 🔑 Test Login

**Admin:**
- Email: `admin@kostsejahtera.com`
- Password: `admin123`

**Tenant:**
- Email: `budi@example.com`
- Password: `tenant123`

---

## 🐛 Troubleshooting

### Error: "Tidak dapat terhubung ke server"

**Untuk Emulator:**
- Pastikan backend running di `http://localhost:3000`
- Check: `http://localhost:3000/health` di browser

**Untuk Physical Device:**
- Pastikan HP dan PC di network WiFi yang sama
- Pastikan firewall tidak block port 3000
- Test: `http://YOUR_IP:3000/health` di browser HP

### Error: "Connection refused"

```bash
# Windows: Allow port 3000 di firewall
netsh advfirewall firewall add rule name="Node 3000" dir=in action=allow protocol=TCP localport=3000
```

### Error: "Token tidak valid"

- Login ulang untuk get token baru
- Token expires dalam 7 hari

---

## 📱 Testing Flow

1. **Start Backend:**
   ```bash
   cd kost-sejahtera-backend
   npm run dev
   ```

2. **Run Flutter:**
   ```bash
   cd kost_sejahtera
   flutter run
   ```

3. **Test Login:**
   - Pilih role (Penyewa/Admin)
   - Masukkan credentials
   - Click "Masuk"
   - Akan navigate ke dashboard sesuai role

---

## ✅ Expected Behavior

**Success Login:**
- Loading indicator muncul
- Success message: "Selamat datang, [Name]!"
- Navigate ke dashboard (Admin atau Tenant)

**Failed Login:**
- Error message muncul (merah)
- Tetap di login screen

**Wrong Role:**
- Warning message (orange)
- "Anda login sebagai [role]. Silakan pilih role yang sesuai."

---

## 🔧 Development Tips

### Hot Reload
- Press `r` untuk reload
- Press `R` untuk restart
- Press `q` untuk quit

### Debug Logs
```bash
flutter logs
```

### Clear Cache
```bash
flutter clean
flutter pub get
flutter run
```

---

**Happy Coding! 📱**
