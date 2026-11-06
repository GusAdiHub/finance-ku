# AUDIT & ANALISIS MIGRASI KE FLUTTER MOBILE
**Project:** SakuKu / Personal Finance Tracker  
**Peran:** Senior Flutter Engineer & Software Architect  
**Tanggal:** November 2026  
**Status:** DRAFT ARSITEKTUR & AUDIT

---

## 1. Ringkasan Eksekutif & Kondisi Proyek Saat Ini

Project ini adalah aplikasi pencatatan keuangan pribadi (*Personal Finance*) yang sebelumnya dikembangkan dengan arsitektur web PWA menggunakan **Next.js 14 (App Router)** sebagai frontend dan **FastAPI + PostgreSQL** sebagai backend.

Tahap selanjutnya adalah memigrasikan frontend ke platform **Android Native menggunakan Flutter** dengan pendekatan **Offline-First**. Dengan pendekatan ini, pengguna dapat mencatat dan melihat transaksi keuangan lokal tanpa ketergantungan koneksi internet secara terus-menerus, dan data akan disinkronkan secara otomatis ke backend PostgreSQL ketika jaringan tersedia.

### 1.1 Status Komponen Sistem

| Komponen | Teknologi | Status Saat Ini | Kesiapan Migrasi |
| :--- | :--- | :--- | :--- |
| **Backend API** | FastAPI 0.162.0 (Python 3.12) | Aktif, stabil, 100% test lulus | Siap digunakan sebagai remote server |
| **Database Pusat** | PostgreSQL 16+ (Driver: psycopg 3) | Aktif secara lokal (10 tabel ter-migrasi) | Siap sebagai *source of truth* terpusat |
| **Frontend Lama** | Next.js 14 + Tailwind CSS + Lucide | Berjalan (App Router) | Referensi UI/UX dan alur fungsional |
| **Mobile App Baru** | Flutter 3.x (Dart 3.x) | Inisialisasi dasar (`pubspec.yaml` siap) | Siap dibangun sesuai panduan arsitektur |

---

## 2. Audit Komprehensif Backend (FastAPI & PostgreSQL)

Backend dirancang dengan pemisahan tanggung jawab (*separation of concerns*) yang bersih:
`Router (API) -> Dependencies (Auth) -> Service Layer (Business Logic) -> Repository Layer (SQLAlchemy ORM) -> Database (PostgreSQL)`.

### 2.1 Model & Entitas Database Pusat

Database PostgreSQL menggunakan 9 tabel fungsional dan 1 tabel sistem Alembic:
1. `users`: Akun pengguna (`id` CHAR(36) UUID, `name`, `email` unique, `password_hash`, `is_active`).
2. `categories`: Kategori keuangan (`id` CHAR(36), `name`, `type` ['income', 'expense'], `icon`, `color`, `is_system`, `user_id`, `group_id`).
3. `transactions`: Transaksi keuangan (`id` CHAR(36), `type`, `amount` DECIMAL(15,2), `category_id`, `transaction_date`, `description`, `notes`, `owner_user_id`, `created_by_user_id`, `input_method`, `receipt_id`).
4. `finance_groups`: Grup keuangan keluarga / Shared Ledger (*Ditunda dari MVP*).
5. `group_members`: Keanggotaan grup dan peran (*Ditunda dari MVP*).
6. `group_invitations`: Kode undangan grup (*Ditunda dari MVP*).
7. `receipts`: Metadata file struk fisik dan status OCR (*Ditunda dari MVP*).
8. `transaction_items`: Rincian item struk (*Ditunda dari MVP*).
9. `audit_logs`: Jejak audit aktivitas keamanan dan keuangan.
10. `alembic_version`: Pelacak versi migrasi database.

### 2.2 Endpoint API yang Akan Digunakan di Mobile MVP

Berikut adalah pemetaan endpoint backend yang aktif dan akan dikonsumsi oleh Flutter:

#### A. Authentication (`/api/v1/auth`)
* `POST /api/v1/auth/register`
  * **Header:** `Content-Type: application/json`
  * **Body:** `{"name": str, "email": Optional[str], "password": str}`
  * **Response (201):** `TokenResponse` (`{"access_token": str, "token_type": "bearer", "expires_in": int, "user": UserResponse}`)
  * **Catatan:** Jika `email` kosong/null, backend otomatis membuat dummy email `<sanitized_name>@sakuku.local`.
* `POST /api/v1/auth/login`
  * **Header:** `Content-Type: application/json`
  * **Body:** `{"username": str, "password": str}` (bisa menerima email atau username)
  * **Response (200):** `TokenResponse`
* `POST /api/v1/auth/logout`
  * **Header:** `Authorization: Bearer <token>`
  * **Response (200):** `{"message": "Successfully logged out.", "success": true}`
* `GET /api/v1/auth/me`
  * **Header:** `Authorization: Bearer <token>`
  * **Response (200):** `UserResponse` (`{"id": str, "name": str, "email": str, "is_active": bool, "created_at": datetime, "updated_at": datetime}`)
* `PATCH /api/v1/auth/me`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:** `{"name": Optional[str], "email": Optional[str]}`
  * **Response (200):** `UserResponse`
* `POST /api/v1/auth/change-password`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:** `{"current_password": str, "new_password": str}`
  * **Response (200):** `MessageResponse`

#### B. Categories (`/api/v1/categories`)
* `GET /api/v1/categories?type={income|expense}`
  * **Header:** `Authorization: Bearer <token>`
  * **Query Params:** `type` (opsional: `"income"` atau `"expense"`)
  * **Response (200):** `List[CategoryResponse]` (berisi kategori sistem `is_system=true` dan kategori custom user `user_id=current_user.id`)
* `POST /api/v1/categories`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:** `{"name": str, "type": "income"|"expense", "icon": Optional[str], "color": Optional[str]}`
  * **Response (201):** `CategoryResponse`
* `PATCH /api/v1/categories/{category_id}`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:** `{"name": Optional[str], "icon": Optional[str], "color": Optional[str]}`
  * **Response (200):** `CategoryResponse` (Hanya kategori custom milik user yang bisa diedit)
* `DELETE /api/v1/categories/{category_id}`
  * **Header:** `Authorization: Bearer <token>`
  * **Response (200):** `MessageResponse` (Gagal jika kategori sistem atau sedang digunakan transaksi)

#### C. Transactions (`/api/v1/transactions`)
* `GET /api/v1/transactions`
  * **Header:** `Authorization: Bearer <token>`
  * **Query Params:**
    * `start_date` (ISO8601 UTC string)
    * `end_date` (ISO8601 UTC string)
    * `type` (`"income"` | `"expense"`)
    * `category_id` (UUID string)
    * `search` (string)
    * `min_amount`, `max_amount` (Decimal)
    * `page` (int, default 1)
    * `page_size` (int, default 20, max 100)
  * **Response (200):** `PaginatedTransactionResponse` (`{"items": [...], "total": int, "page": int, "page_size": int, "total_pages": int}`)
* `POST /api/v1/transactions`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:**
    ```json
    {
      "type": "income" | "expense",
      "amount": "50000.00",
      "category_id": "uuid-string",
      "transaction_date": "2026-11-05T10:00:00Z",
      "description": "Makan Siang",
      "notes": "Opsional catatan",
      "input_method": "manual"
    }
    ```
  * **Response (201):** `TransactionResponse`
* `GET /api/v1/transactions/{transaction_id}`
  * **Header:** `Authorization: Bearer <token>`
  * **Response (200):** `TransactionResponse`
* `PATCH /api/v1/transactions/{transaction_id}`
  * **Header:** `Authorization: Bearer <token>`
  * **Body:** Parsial dari field `type`, `amount`, `category_id`, `transaction_date`, `description`, `notes`
  * **Response (200):** `TransactionResponse`
* `DELETE /api/v1/transactions/{transaction_id}`
  * **Header:** `Authorization: Bearer <token>`
  * **Response (200):** `MessageResponse`

#### D. Dashboard & Reports (`/api/v1/dashboard` & `/api/v1/reports`)
* `GET /api/v1/dashboard/personal`
  * **Query Params:** `start_date`, `end_date`
  * **Response (200):** `PersonalDashboardResponse` (`total_income`, `total_expense`, `net_balance`, `recent_transactions`, `expense_by_category`, `income_by_category`)
* `GET /api/v1/reports/personal`
  * **Query Params:** `period` (`monthly`, `weekly`, `daily`, `yearly`), `start_date`, `end_date`
  * **Response (200):** `PersonalReportResponse` (`total_income`, `total_expense`, `net_savings`, `savings_rate`, `expense_by_category`, `income_by_category`, `monthly_trends`)

---

## 3. Audit Frontend Lama (Next.js)

Frontend lama dianalisis sebagai acuan perilaku fungsional (*functional reference*):

1. **Alur Autentikasi:**
   - Menyimpan JWT token di `localStorage.getItem("token")`.
   - Mengizinkan registrasi cepat hanya dengan Nama + Password (email opsional).
   - Login mendukung input fleksibel (bisa email atau username).
   - Fitur "Ingat username di perangkat ini" menyimpan teks username ke storage.
2. **Format Data & Mata Uang:**
   - Format uang: Menggunakan locale Indonesia (`id-ID`) dengan format Rupiah tanpa desimal sen (contoh: `Rp 50.000`).
   - Format tanggal: `d MMM yyyy` (contoh: `5 Nov 2026`) dan format jam `HH:mm`.
3. **Pencatatan Transaksi:**
   - Input manual menyediakan toggle cepat: **Pengeluaran** vs **Pemasukan**.
   - Validasi ketat: Nominal harus angka positif > 0.
   - Pilihan kategori langsung disaring berdasarkan jenis transaksi (kategori pengeluaran hanya muncul saat mode pengeluaran aktif).
4. **Dashboard:**
   - Menampilkan 3 kartu ringkasan: Total Pemasukan (hijau), Total Pengeluaran (merah), dan Saldo Bersih / Net Balance.
   - Daftar 5 transaksi terakhir (*recent transactions*).
   - Diagram / breakdown pengeluaran berdasarkan kategori.
5. **Laporan Keuangan:**
   - Filter rentang waktu: Bulan ini (*Monthly*), Hari ini (*Daily*), atau Kustom (*Custom Date Range*).
   - Metrik utama: Tingkat Tabungan (*Savings Rate %* = `(income - expense) / income * 100`).
   - Tren bulanan (*Monthly Trends*).

---

## 4. Ketidaksesuaian & Masalah Arsitektural (Discrepancy Analysis)

Sebagai Software Architect, ditemukan beberapa ketidaksesuaian mendasar antara backend aktual dengan kebutuhan arsitektur Flutter Offline-First:

### Isu 1: Backend Tidak Menerima `id` dari Client pada `TransactionCreate`
* **Kondisi Aktual:** Pydantic schema `TransactionCreate` tidak mendefinisikan field `id`. Pada `TransactionService.create_personal_transaction`, ORM membuat entitas `Transaction` di mana `id` di-generate di server via SQLAlchemy mixin `uuid.uuid4()`.
* **Dampak Offline-First:** Saat aplikasi Flutter mencatat transaksi dalam kondisi offline, SQLite lokal harus segera memiliki primary key unik (`id`) agar transaksi dapat ditampilkan, diedit, atau dihapus seketika di UI lokal.
* **Solusi Arsitektur Flutter:**
  Tabel lokal SQLite (Drift) akan memiliki:
  - `id`: UUID v4 lokal yang dibuat saat transaksi disimpan pertama kali di HP.
  - `remote_id`: UUID yang diberikan oleh PostgreSQL setelah sinkronisasi berhasil.
  - `sync_status`: Status sinkronisasi (`pending_create`, `synced`, `pending_update`, `pending_delete`, `failed`).
  Saat sinkronisasi pertama (`pending_create`), Flutter mengirim payload transaksi ke backend. Backend mengembalikan response dengan `id` server, lalu Flutter memperbarui kolom `remote_id` dan mengubah status menjadi `synced`.

### Isu 2: Ketiadaan Endpoint Sinkronisasi Inkremental (`updated_since`)
* **Kondisi Aktual:** Endpoint `GET /transactions` hanya memfilter berdasarkan `transaction_date` (tanggal transaksi di struk/nota), bukan tanggal record diubah di server (`updated_at`). Tidak ada parameter `updated_since` atau endpoint `/sync/pull`.
* **Dampak Offline-First:** Aplikasi mobile tidak bisa bertanya ke backend: *"Beri saya data yang berubah sejak timestamp T"*.
* **Solusi Arsitektur Flutter:**
  Untuk MVP, proses Pull-Sync akan mengunduh transaksi terbaru (misalnya 100 transaksi terakhir atau transaksi pada rentang bulan aktif) dan mencocokkannya (*reconcile*) ke database SQLite lokal berdasarkan `remote_id`.

### Isu 3: Backend Menggunakan Hard Delete
* **Kondisi Aktual:** `DELETE /transactions/{transaction_id}` menghapus baris dari database secara permanen (`db.delete()`). Backend tidak menerapkan *Soft Delete* (tidak ada kolom `deleted_at`).
* **Dampak Offline-First:** Jika user menghapus transaksi saat offline, aplikasi lokal tidak boleh langsung melakukan `DELETE` dari SQLite karena jika baris lokal terhapus, aplikasi tidak akan pernah tahu transaksi mana yang harus dihapus di backend saat online kembali.
* **Solusi Arsitektur Flutter:**
  Mekanisme **Tombstone**: Saat user menghapus transaksi di HP saat offline, record SQLite lokal diberi flag `sync_status = 'pending_delete'`. UI akan menyaring agar transaksi ini tidak terlihat oleh user. Ketika koneksi online pulih, Sync Manager mengeksekusi `DELETE /transactions/{remote_id}` ke backend. Setelah backend mengembalikan HTTP 200, baris baru benar-benar di-hard-delete dari SQLite lokal.

### Isu 4: Ketiadaan Refresh Token Endpoint
* **Kondisi Aktual:** Backend hanya menerbitkan 1 JWT `access_token` dengan masa berlaku 1440 menit (24 jam). Tidak ada endpoint `/auth/refresh` dan tidak ada rotasi token.
* **Dampak Offline-First:** Jika pengguna menggunakan aplikasi secara offline selama lebih dari 24 jam, token JWT akan kedaluwarsa. Saat perangkat kembali online, request sinkronisasi akan ditolak dengan `HTTP 401 Unauthorized`.
* **Solusi Arsitektur Flutter:**
  Data lokal di SQLite **tidak boleh dihapus** saat terjadi HTTP 401! Dio `ErrorInterceptor` akan mendeteksi HTTP 401, menjeda antrean sinkronisasi (*pause sync engine*), dan menampilkan modal/layar login ulang dengan username yang tersimpan. Setelah pengguna memasukkan kata sandi dan menerima token baru, antrean sinkronisasi dilanjutkan tanpa ada kehilangan data transaksi lokal.

### Isu 5: Penghitungan Dashboard & Laporan di Sisi Offline
* **Kondisi Aktual:** Endpoint `/dashboard/personal` dan `/reports/personal` dihitung secara agregat oleh PostgreSQL di backend.
* **Dampak Offline-First:** Saat offline, jika user memanggil API dashboard, request akan gagal (no internet).
* **Solusi Arsitektur Flutter:**
  Flutter akan menerapkan **Local Aggregation Engine** di Drift DAO:
  Formula perhitungan pendapatan, pengeluaran, saldo bersih, persentase kategori, dan tingkat tabungan diimplementasikan langsung menggunakan SQL aggregation query di SQLite lokal (`SUM(CASE WHEN type='income' THEN amount...)`). Hasilnya: Dashboard dan laporan dapat terbuka instan (0 ms latency) baik online maupun offline! Saat online, data dapat di-refresh dari backend.

---

## 5. Ringkasan Fitur yang Siap Dimigrasikan

| Modul Fitur | Status Migrasi | Ketergantungan Backend | Mode Offline |
| :--- | :--- | :--- | :--- |
| **Auth: Register & Login** | Siap (MVP) | `POST /auth/register`, `POST /auth/login` | Wajib Online saat pertama kali |
| **Auth: Profile & Password** | Siap (MVP) | `GET /auth/me`, `PATCH /auth/me`, `POST /change-password` | Online (dengan cache lokal profil) |
| **Kategori Transaksi** | Siap (MVP) | `GET /categories`, `POST /categories`, `PATCH /categories/{id}` | Full Offline (cache lokal di SQLite) |
| **Transaksi: Tambah/Edit/Hapus**| Siap (MVP) | `GET, POST, PATCH, DELETE /transactions` | Full Offline-First via Sync Queue |
| **Riwayat Transaksi & Filter** | Siap (MVP) | `GET /transactions` | Full Offline dari SQLite lokal |
| **Dashboard Personal** | Siap (MVP) | `GET /dashboard/personal` | Dihitung lokal di SQLite + refresh online |
| **Laporan Keuangan** | Siap (MVP) | `GET /reports/personal` | Dihitung lokal di SQLite + refresh online |
| **Family Finance (Grup/Kas)** | **Ditunda** | `/groups/*` | Ditunda dari MVP (kode backend aman) |
| **Scan Struk (OCR)** | **Ditunda** | `/receipts/*` | Ditunda ke Phase 2 |
| **Voice Input** | **Ditunda** | `/voice/parse` | Ditunda ke Phase 2 |
