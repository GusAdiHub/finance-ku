# DEPLOYMENT GUIDE

## 1. Development Environment

**Frontend:**

* Node.js

* Next.js

* npm

**Backend:**

* Python

* FastAPI

* Virtual environment

**Database:**

* MySQL 8

* Laragon atau instalasi MySQL lokal

## 2. Environment Variables

Contoh backend `.env`:

```env
APP_ENV=development
DATABASE_URL=mysql+pymysql://finance_app:CHANGE_ME@127.0.0.1:3306/finance_tracker
SECRET_KEY=CHANGE_ME
UPLOAD_DIR=private_uploads
```

> **Peringatan Penting:** Jangan pernah *commit* file `.env` ke Git.

## 3. Database Setup

1. Jalankan MySQL.

2. Buat database `finance_tracker`.

3. Buat akun database khusus aplikasi.

4. Konfigurasikan `DATABASE_URL`.

5. Jalankan Alembic migration.

6. Verifikasi tabel dan relasi.

## 4. Backend Setup

1. Aktifkan *virtual environment*.

2. Install *dependency*.

3. Jalankan migration.

4. Jalankan FastAPI.

5. Periksa dokumentasi OpenAPI.

## 5. Frontend Setup

1. Install *dependency*.

2. Konfigurasikan API URL.

3. Jalankan Next.js.

4. Periksa koneksi API.

## 6. Production

* Gunakan HTTPS.

* Gunakan *secret production*.

* Jangan *expose* database.

* Gunakan *private storage*.

* Aktifkan *backup*.

* Batasi CORS.

* Uji proses *restore* database.

## 7. Migration Safety

* *Backup* sebelum migration di *production*.

* *Review* migration sebelum dijalankan.

* Jangan menjalankan migration destruktif tanpa persetujuan.