# Kost Sejahtera - Flutter Mobile App

Aplikasi manajemen kos modern dan terpercaya untuk admin dan penyewa.

## 🚀 Fitur Utama

### Admin
- Dashboard dengan statistik real-time
- Manajemen keuangan (pemasukan & pengeluaran)
- Manajemen kamar (CRUD)
- Manajemen penghuni
- Generate invoice otomatis
- Integrasi WhatsApp untuk reminder
- Grafik dan chart analytics

### Penyewa
- Dashboard pribadi
- Lihat tagihan dan rincian
- Bayar tagihan (Midtrans integration)
- Riwayat pembayaran
- Informasi kamar dan fasilitas
- Lapor kerusakan

## 📋 Prerequisites

Sebelum menjalankan aplikasi, pastikan Anda sudah menginstall:

1. **Flutter SDK** (versi 3.0.0 atau lebih baru)
   - Download dari: https://flutter.dev/docs/get-started/install
   - Tambahkan Flutter ke PATH

2. **VS Code** dengan extension:
   - Flutter
   - Dart

3. **Android Studio** (opsional, untuk emulator)
   - Atau gunakan device fisik dengan USB debugging enabled

4. **Git** (untuk clone repository)

## 🔧 Instalasi Flutter SDK

### Windows

1. Download Flutter SDK:
   ```powershell
   # Buat folder untuk Flutter
   mkdir C:\src
   cd C:\src
   
   # Download Flutter (gunakan browser atau PowerShell)
   # https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.1-stable.zip
   ```

2. Extract file zip ke `C:\src\flutter`

3. Tambahkan Flutter ke PATH:
   - Buka "Edit Environment Variables"
   - Tambahkan `C:\src\flutter\bin` ke PATH
   - Restart terminal

4. Verifikasi instalasi:
   ```powershell
   flutter doctor
   ```

5. Install dependencies yang kurang (jika ada):
   ```powershell
   flutter doctor --android-licenses
   ```

## 📦 Setup Project

1. Clone atau copy project ini:
   ```bash
   cd "d:\Web Management Kos\kost_sejahtera"
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup Firebase:
   - Buat project di [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS)
   - Letakkan file di folder yang sesuai
   - Ikuti panduan: https://firebase.google.com/docs/flutter/setup

4. Setup Midtrans:
   - Daftar di [Midtrans](https://midtrans.com/)
   - Dapatkan Server Key dan Client Key
   - Tambahkan ke environment variables

## 🏃‍♂️ Menjalankan Aplikasi

1. Cek device yang tersedia:
   ```bash
   flutter devices
   ```

2. Run aplikasi:
   ```bash
   # Development mode
   flutter run
   
   # Atau pilih device spesifik
   flutter run -d <device_id>
   ```

3. Hot reload:
   - Tekan `r` di terminal untuk reload
   - Tekan `R` untuk full restart

## 🏗️ Build APK

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

APK akan tersimpan di: `build/app/outputs/flutter-apk/`

## 📱 Testing di Device Fisik

1. Enable USB Debugging di Android:
   - Settings → About Phone → Tap "Build Number" 7x
   - Settings → Developer Options → Enable USB Debugging

2. Hubungkan device via USB

3. Verifikasi device terdeteksi:
   ```bash
   flutter devices
   ```

4. Run aplikasi:
   ```bash
   flutter run
   ```

## 🗂️ Struktur Project

```
lib/
├── main.dart                 # Entry point
├── core/
│   ├── constants/           # Colors, text styles, constants
│   ├── theme/               # App theme
│   └── services/            # API, auth, payment services
├── data/
│   ├── models/              # Data models
│   └── repositories/        # Data repositories
└── presentation/
    ├── screens/             # All screens
    │   ├── auth/           # Login, register
    │   ├── admin/          # Admin screens
    │   ├── tenant/         # Tenant screens
    │   └── shared/         # Shared screens
    └── widgets/             # Reusable widgets
```

## 🔑 Environment Variables

Buat file `.env` di root project:

```env
FIREBASE_API_KEY=your_api_key
MIDTRANS_SERVER_KEY=your_server_key
MIDTRANS_CLIENT_KEY=your_client_key
```

## 🐛 Troubleshooting

### Flutter command not found
```bash
# Tambahkan Flutter ke PATH
# Windows: C:\src\flutter\bin
# Restart terminal
```

### Gradle build failed
```bash
# Clean dan rebuild
flutter clean
flutter pub get
flutter run
```

### Firebase not configured
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Midtrans Documentation](https://docs.midtrans.com/)

## 👨‍💻 Development

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` untuk check code quality

### Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📄 License

Private project - All rights reserved

## 🤝 Support

Untuk bantuan, hubungi developer atau buka issue di repository.
