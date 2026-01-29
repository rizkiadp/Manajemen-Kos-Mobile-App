# Kost Sejahtera

Aplikasi manajemen kos modern dan terpercaya yang memudahkan pemilik kos dalam mengelola properti dan penyewa dalam mengakses layanan kos.

## Tech Stack

### Backend
-   **Runtime**: Node.js
-   **Framework**: Express.js
-   **Database**: PostgreSQL
-   **Authentication**: JWT (JSON Web Tokens)
-   **Dependencies**: `pg`, `bcryptjs`, `cors`, `helmet`, `express-validator`, `multer` (upload), `midtrans-client` (payment), `nodemailer`.

### Frontend (Mobile App)
-   **Framework**: Flutter
-   **State Management**: Provider
-   **Networking**: Dio
-   **UI Integration**: Google Fonts, Flutter SVG, Lottie
-   **Charts**: FL Chart
-   **Payment**: Midtrans Integration
-   **Features**: Image Picker, PDF Generation, Local Notifications.

## Fitur Utama

### Admin (Pemilik Kos)
-   **Dashboard Ringkasan**: Statistik pendapatan, jumlah penyewa, dan kamar terisi.
-   **Manajemen Kamar**: Tambah, edit, dan hapus data kamar (termasuk status ketersediaan).
-   **Manajemen Penyewa**: Kelola data penyewa dan riwayat sewa.
-   **Tagihan & Pembayaran**: Buat tagihan otomatis dan pantau status pembayaran.
-   **Laporan Keuangan**: Grafik pemasukan bulanan.
-   **Chat**: Komunikasi langsung dengan penyewa.

### Tenant (Penyewa)
-   **Dashboard**: Informasi status sewa dan tagihan aktif.
-   **Pembayaran Online**: Integrasi dengan Payment Gateway (Midtrans) untuk kemudahan bayar.
-   **Riwayat Transaksi**: Lihat histori pembayaran sebelumnya.
-   **Laporan Kerusakan**: Ajukan komplain atau laporan kerusakan fasilitas.
-   **Chat**: Hubungi admin/pemilik kos.

## Struktur Project

Project ini terdiri dari dua bagian utama:
1.  `kost-sejahtera-backend`: Server API (Node.js & Express).
2.  `kost_sejahtera`: Aplikasi Mobile (Flutter).

## Cara Menjalankan Project

Ikuti langkah-langkah berikut untuk menjalankan aplikasi secara lokal.

### Prasyarat
Pastikan komputer Anda sudah terinstall:
-   [Node.js](https://nodejs.org/) (v16+)
-   [PostgreSQL](https://www.postgresql.org/)
-   [Flutter SDK](https://flutter.dev/docs/get-started/install)

---

### 1. Setup Backend

1.  Buka terminal dan masuk ke folder backend:
    ```bash
    cd kost-sejahtera-backend
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Buat file `.env` di dalam folder `kost-sejahtera-backend` dan sesuaikan konfigurasinya (contoh):
    ```env
    PORT=3000
    DB_USER=postgres
    DB_PASSWORD=password_db_anda
    DB_HOST=localhost
    DB_NAME=kost_sejahtera_db
    DB_PORT=5432
    JWT_SECRET=rahasia_jwt_anda
    # Tambahkan key Midtrans/Nodemailer jika ada
    ```

4.  Jalankan migrasi database (pastikan database `kost_sejahtera_db` sudah dibuat di PostgreSQL):
    ```bash
    npm run migrate
    ```

5.  (Opsional) Isi data awal (seeding):
    ```bash
    npm run seed
    ```

6.  Jalankan server:
    ```bash
    npm run dev
    ```
    Server akan berjalan di `http://localhost:3000`.

---

### 2. Setup Frontend (Mobile App)

1.  Buka terminal baru dan masuk ke folder frontend:
    ```bash
    cd kost_sejahtera
    ```

2.  Install library Flutter:
    ```bash
    flutter pub get
    ```

3.  Jalankan aplikasi (pastikan Emulator sudah nyala atau device terhubung):
    ```bash
    flutter run
    ```

## Dokumentasi API

Base URL untuk API lokal: `http://localhost:3000/api`

Endpoint umum:
-   `POST /auth/login` - Login user
-   `GET /dashboard/admin` - Ringkasan data admin
-   `GET /tenant/bills` - Tagihan penyewa
