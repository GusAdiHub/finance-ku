# 💰 SakuKeluarga — Personal & Family Finance Tracker

Aplikasi pencatat keuangan pribadi dan keluarga berbasis **PWA (Progressive Web App)** dan **Shared Ledger** yang dirancang inklusif dengan **Mode Ramah Orang Tua (Elderly-Friendly)**.

---

## ⚡ Quick Start (Cara Cepat Menjalankan)

Berikut adalah panduan kilat untuk langsung menjalankan Backend (Uvicorn) dan Frontend (Next.js):

### 🔹 Terminal 1: Menjalankan Backend (FastAPI & Uvicorn)

```bash
# 1. Masuk ke folder backend
cd backend

# 2. Buat virtual environment (cukup 1x saat pertama kali)
python -m venv .venv

# 3. Aktifkan virtual environment
source .venv/bin/activate
# (Jika pakai CMD biasa: .\.venv\Scripts\activate.bat)
# (Jika pakai Git Bash / Linux / Mac: source .venv/bin/activate)

# 4. Install paket dependensi (cukup 1x saat pertama kali)
pip install -r requirements.txt

# 5. Salin file environment & sesuaikan password database MySQL
cp .env.example .env    # di PowerShell: Copy-Item .env.example .env

# 6. Jalankan migrasi database & isi data awal (cukup 1x)
alembic upgrade head
python -m app.seeds.default_categories
python -m app.seeds.dev_user

# 7. JALANKAN SERVER UVICORN:
uvicorn app.main:app --reload --port 8000
```

> 🔑 **Akun Pengembang (Dev Account) Siap Pakai:**
> - **Email:** `dev@sakukeluarga.id`
> - **Password:** `Password123!`
> *(Sudah otomatis terhubung ke grup keluarga "Keluarga Cemara" dan memiliki transaksi awal untuk dicoba)*

> 🌐 **Backend siap diakses di:**
> - **API Base URL:** `http://localhost:8000`
> - **Swagger UI API Docs:** `http://localhost:8000/docs`
> - **Health Check:** `http://localhost:8000/api/v1/health`

---

### 🔹 Terminal 2: Menjalankan Frontend (Next.js)

Buka jendela terminal baru:

```bash
# 1. Masuk ke folder frontend
cd frontend

# 2. Install dependensi Node.js (cukup 1x saat pertama kali)
npm install

# 3. JALANKAN SERVER FRONTEND:
npm run dev
```

> 🌐 **Frontend siap dibuka di browser:**
> - **Web App:** [http://localhost:3000](http://localhost:3000)

---

## 📋 Prasyarat Sistem (Prerequisites)

1. **Python 3.10+** (Python 3.10, 3.11, atau 3.12).
2. **Node.js 18+** atau **20+** dan **npm**.
3. **MySQL Server 8.0+** (XAMPP, Laragon, atau MySQL native).

### Persiapan Database MySQL:
Pastikan MySQL service sudah aktif, lalu buat database:
```sql
CREATE DATABASE finance_tracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## 📖 Panduan Detail Backend (FastAPI)

### 1. Masuk ke Direktori Backend
```bash
cd backend
```

### 2. Membuat Virtual Environment (`.venv`)
Virtual environment wajib dibuat agar paket Python project tidak tercampur dengan Python global:
```bash
python -m venv .venv
```

### 3. Mengaktifkan Virtual Environment
- **Windows PowerShell:**
  ```powershell
  .\.venv\Scripts\Activate.ps1
  ```
  *(Jika muncul error script execution policy di PowerShell, jalankan: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`, lalu ulangi pengaktifan).*

- **Windows Command Prompt (CMD):**
  ```cmd
  .\.venv\Scripts\activate.bat
  ```

- **Git Bash / Linux / macOS:**
  ```bash
  source .venv/bin/activate
  ```

*Tanda venv berhasil aktif: Muncul teks `(.venv)` di awal baris terminal Anda.*

### 4. Instalasi Dependensi
```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### 5. Konfigurasi `.env`
Salin template konfigurasi:
```powershell
Copy-Item .env.example .env
```
Isi konfigurasi database MySQL di file `.env`:
```env
APP_ENV=development
APP_NAME="Personal & Family Finance Tracker"
DEBUG=true

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=finance_tracker

DATABASE_URL=mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?charset=utf8mb4

SECRET_KEY=kunci_rahasia_super_aman_untuk_pengembangan_lokal
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

### 6. Menjalankan Migrasi & Seeding
```bash
alembic upgrade head
python -m app.seeds.default_categories
```

### 7. Menjalankan Server Backend (Uvicorn)
```bash
uvicorn app.main:app --reload --port 8000
```
- Flag `--reload` membuat server otomatis restart setiap kali ada perubahan file kode Python.
- Flag `--port 8000` menentukan port HTTP backend.

### 8. Menjalankan Pengujian (Testing)
```bash
pytest backend/tests -v
```
Pengujian mencakup unit test, endpoint API test, proteksi IDOR, dan 7 skenario wajib authorization testing.

---

## 🚀 Panduan Deployment Production (Docker)

Aplikasi SakuKeluarga sudah dilengkapi dengan konfigurasi production Docker terorkestrasi:
- **MySQL 8.0** dengan internal private bridge network (tidak ter-expose langsung ke publik).
- **FastAPI Backend** dengan Tesseract OCR & migrasi otomatis saat booting (`entrypoint.sh`).
- **Next.js Frontend** dengan multi-stage standalone build untuk performa tinggi & ukuran image kecil.
- **Nginx Reverse Proxy** dengan HTTPS, kompresi Gzip, dan security headers (HSTS, CSP, X-Frame-Options).

### Langkah Menjalankan dengan Docker Compose:
```bash
# 1. Buat file .env.production dari template
cp .env.production.example .env.production

# 2. Sesuaikan secret key dan password database pada .env.production
# 3. Jalankan script deployment otomatis
bash scripts/deploy.sh

# Atau jalankan via docker compose:
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

### Backup & Restore Database Otomatis:
```bash
# Backup database (hasil tersimpan di /backups/sakukeluarga berformat .sql.gz)
bash scripts/backup_db.sh

# Restore database dari file cadangan
bash scripts/restore_db.sh /backups/sakukeluarga/sakukeluarga_db_20261030_120000.sql.gz
```

---

## 💻 Panduan Detail Frontend (Next.js)

### 1. Masuk ke Direktori Frontend
```bash
cd frontend
```

### 2. Instalasi Dependensi
```bash
npm install
```

### 3. Konfigurasi `.env.local`
Pastikan file `frontend/.env.local` berisi:
```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

### 4. Menjalankan Server Development
```bash
npm run dev
```
Buka browser di `http://localhost:3000`.

---

## 📱 Fitur Utama Aplikasi

- **Autentikasi & Akun (`/login`, `/register`, `/profile`):** Register, login JWT, ganti password.
- **Scope Switcher:** Berpindah antara **Catatan Pribadi** dan **Kas Keluarga (Shared Ledger)**.
- **Form Pencatatan Transaksi:** Modal responsif dengan *quick amount chips* (+10rb, +50rb, +100rb, dll.), opsi input manual, struk (OCR), dan suara (Voice).
- **Riwayat & Filter (`/transactions`):** Pencarian, filter kategori, filter tipe, rentang tanggal, dan paginasi.
- **Grup Keluarga & Undangan (`/groups`):** Buat grup keluarga, gabung dengan kode 8-karakter, buat kode undangan berbatas waktu dan kuota, serta pantau anggota keluarga.
- **Laporan Finansial (`/reports`):** Grafik pengeluaran per kategori, rasio tabungan (*savings rate*), dan rincian mingguan/bulanan/tahunan.
- **Mode Ramah Orang Tua:** Toggle untuk memperbesar ukuran font, tombol minimal 48px, kontras tinggi, dan penyederhanaan istilah menjadi *"Uang Masuk"*, *"Uang Keluar"*, dan *"Sisa Uang"*.

---

## ❓ FAQ & Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| `Activate.ps1 cannot be loaded` | Kebijakan PowerShell Windows membatasi script | Jalankan `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` di PowerShell, lalu aktifkan kembali. |
| `Can't connect to MySQL server` | MySQL belum running | Buka XAMPP/Laragon dan klik **Start** pada MySQL (port 3306). |
| `Access denied for user 'root'@'localhost'` | Password database keliru | Samakan `DB_PASSWORD` di `.env` dengan password root MySQL Anda (kosongkan jika tanpa password). |
| `Table 'finance_tracker.users' doesn't exist` | Belum migrasi database | Jalankan perintah `alembic upgrade head` di folder `backend`. |
| Port `8000` atau `3000` sudah dipakai | Ada terminal/aplikasi lain yang masih jalan di port tersebut | Matikan proses lama atau gunakan port lain (contoh: `uvicorn app.main:app --reload --port 8001`). |
