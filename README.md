# Kost Sejahtera

Aplikasi manajemen kos modern dan terpercaya yang memudahkan pemilik kos dalam mengelola properti dan penyewa dalam mengakses layanan kos.

## Tech Stack
... (sama)

## Cara Menjalankan Project (Lokal Administrator)
... (sama)

## Deploy Online (100% GRATIS & TANPA KARTU KREDIT)



### 1. Database: Neon.tech
1.  Buka [neon.tech](https://neon.tech/) dan daftar pakai Google.
2.  Buat Project baru.
3.  Copy **Connection String** yang muncul (format: `postgres://...`).

### 2. Backend: Vercel


**Persiapan:**
Saya sudah menambahkan file `vercel.json` di dalam folder backend agar support Vercel.

**Langkah Deploy:**
1.  Pastikan kode Anda sudah di-upload ke **GitHub**.
2.  Buka [vercel.com](https://vercel.com) dan Login pakai GitHub.
3.  Klik **Add New...** > **Project**.
4.  Import Repository GitHub Anda.
5.  **PENTING: Konfigurasi Project**:
    -   **Root Directory**: Klik Edit, pilih folder `kost-sejahtera-backend`.
    -   **Framework Preset**: Pilih **Other**.
    -   **Environment Variables**: Masukkan data database Neon dan lainnya sini:
        -   `DB_HOST`: (Host dari Neon)
        -   `DB_USER`: (User dari Neon)
        -   `DB_PASSWORD`: (Password dari Neon)
        -   `DB_NAME`: (Nama DB, biasanya `neondb`)
        -   `DB_PORT`: `5432`
        -   `JWT_SECRET`: (Isi bebas)
        -   `MIDTRANS_SERVER_KEY`: ...
        -   `MIDTRANS_CLIENT_KEY`: ...
6.  Klik **Deploy**.

### 3. Migrasi Database
Karena Vercel adalah "Serverless", kita tidak bisa run command `migrate` di sana. Kita run dari laptop saja (Remote Migration).

1.  Di laptop, update file `.env` lokal Anda dengan data **Neon**.
2.  Run: `npm run migrate` & `npm run seed`.
3.  Tabel di Neon akan terisi, dan Vercel akan otomatis bisa membacanya.

### 4. Update Frontend
1.  Ambil URL Vercel (misal: `https://kost-backend.vercel.app`).
2.  Update `api_client.dart` di Flutter:
    ```dart
    baseUrl: 'https://kost-backend.vercel.app/api',
    ```

---

## Konfigurasi Webhook Midtrans
URL: `https://[nama-app-vercel].vercel.app/api/payments/webhook`

## Dokumentasi API
Base URL (Vercel): `https://[nama-app-vercel].vercel.app/api`
