# Kost Sejahtera - Flutter App

## 📱 Aplikasi Manajemen Kos Modern

Aplikasi mobile untuk mengelola kos dengan fitur lengkap untuk admin dan penyewa.

## ✨ Fitur Utama

### 👨‍💼 Admin
- ✅ Dashboard dengan statistik real-time
- 💰 Manajemen keuangan (income & expense)
- 🏠 CRUD kamar kos
- 👥 Manajemen penghuni
- 📄 Generate invoice otomatis
- 💳 Tracking pembayaran
- 📊 Grafik analytics
- 💬 WhatsApp integration

### 👤 Penyewa
- 🏠 Dashboard pribadi
- 📋 Lihat tagihan & rincian
- 💳 Bayar tagihan (Midtrans)
- 📜 Riwayat pembayaran
- 🛏️ Info kamar & fasilitas
- 🔧 Lapor kerusakan

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0.0+
- VS Code atau Android Studio
- Android device/emulator

### Installation

1. **Clone project**
   ```bash
   cd "d:\Web Management Kos\kost_sejahtera"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Lihat [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

4. **Run app**
   ```bash
   flutter run
   ```

## 📚 Documentation

- [README.md](README.md) - Full documentation
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Firebase configuration
- [MIDTRANS_GUIDE.md](MIDTRANS_GUIDE.md) - Payment gateway setup

## 🏗️ Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payment**: Midtrans
- **Charts**: FL Chart
- **UI**: Material Design 3

## 📦 Main Dependencies

```yaml
- firebase_core & firebase_auth
- cloud_firestore
- provider
- fl_chart
- google_fonts
- dio (for API calls)
```

## 🎨 Design System

- **Primary Color**: #FEC006 (Yellow/Gold)
- **Background**: #F8F8F5
- **Font**: Inter
- **Icons**: Material Symbols Outlined

## 📱 Screens

1. Login Screen
2. Admin Dashboard
3. Financial Management
4. Room Management
5. Tenant Management
6. Invoice Detail
7. Payment Screen
8. Tenant Dashboard
9. Landing Page (Public)
10. Registration

## 🔐 Default Credentials

**Admin**
- Email: `admin@kostsejahtera.com`
- Password: `admin123`

## 🐛 Troubleshooting

See [README.md](README.md#troubleshooting) for common issues.

## 📄 License

Private Project - All Rights Reserved

---

**Developed with ❤️ for Kost Sejahtera**
