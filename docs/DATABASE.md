# DATABASE DESIGN

## Personal & Family Finance Tracker

* **Database:** MySQL 8
* **Backend:** FastAPI
* **ORM:** SQLAlchemy 2.x
* **Migration:** Alembic
* **Database Driver:** PyMySQL
* **Currency:** IDR (Rupiah)

## 1. Database Overview

Aplikasi menggunakan MySQL sebagai database utama.
Sistem memiliki dua ruang pencatatan keuangan:

1. **Personal Finance:** Transaksi pribadi yang hanya dapat diakses oleh pemiliknya.
2. **Family Finance:** Transaksi bersama dalam satu grup keluarga menggunakan konsep *Shared Ledger*.

> **Catatan:** *Family Finance* bukan sistem pembagian utang atau *Split Expense*. Semua anggota yang memiliki akses dapat melihat catatan keuangan bersama sesuai hak aksesnya.

Satu pengguna dapat:
* Memiliki ruang keuangan pribadi.
* Membuat grup keluarga.
* Bergabung dengan beberapa grup keluarga.
* Mengakses transaksi sesuai keanggotaan dan *role*.

## 2. Database Configuration

* **Nama database:** `finance_tracker`

**Konfigurasi:**
* **Engine:** InnoDB
* **Character Set:** `utf8mb4`
* **Collation:** `utf8mb4_unicode_ci`
* **Timezone penyimpanan:** UTC
* Tampilan tanggal dan waktu mengikuti timezone pengguna.
* **Mata uang utama:** IDR.

## 3. Database Conventions

### 3.1 Primary Key
Gunakan UUID sebagai *primary key* untuk seluruh tabel.
Untuk implementasi awal MySQL, UUID dapat disimpan menggunakan `CHAR(36)`.

### 3.2 Timestamp
Tabel yang membutuhkan histori menggunakan:
* `created_at`
* `updated_at`

Gunakan waktu UTC secara konsisten.

### 3.3 Monetary Values
Seluruh nominal keuangan menggunakan:
`DECIMAL(15,2)`

Jangan menggunakan `FLOAT` atau `DOUBLE` untuk nominal uang.

### 3.4 Foreign Key
Setiap relasi antar tabel harus menggunakan *foreign key* yang sesuai.
Hindari penghapusan berantai (*cascade delete*) terhadap data transaksi dan histori keuangan.

### 3.5 Naming Convention
* Nama tabel menggunakan `snake_case` dan bentuk *plural* (jamak).
* Nama kolom menggunakan `snake_case`.
* *Primary key* menggunakan `id`.
* *Foreign key* menggunakan format `[table]_id`.

## 4. Database Tables

### 4.1 `users`
Menyimpan data akun pengguna.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `name` | VARCHAR(100) | NOT NULL |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL |
| `password_hash` | VARCHAR(255) | NOT NULL |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan:**
* Password wajib disimpan dalam bentuk *hash*.
* Email harus unik.
* Akun yang dinonaktifkan tidak boleh melakukan autentikasi.

### 4.2 `finance_groups`
Menyimpan grup keuangan keluarga (Shared Ledger).

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `name` | VARCHAR(100) | NOT NULL |
| `description` | TEXT | NULLABLE |
| `created_by_user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NOT NULL |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan:**
* Satu grup merepresentasikan satu buku catatan bersama (*Shared Ledger*).
* Penghapusan grup tidak boleh menghapus data historis transaksi keuangan (*no cascade delete*).

### 4.3 `group_members`
Menyimpan keanggotaan pengguna dalam grup keuangan beserta perannya.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE RESTRICT), NOT NULL |
| `user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NOT NULL |
| `role` | VARCHAR(20) | NOT NULL, DEFAULT 'member', CHECK ('owner', 'admin', 'member') |
| `joined_at` | DATETIME | NOT NULL |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Constraints:**
* `UNIQUE (group_id, user_id)`: Pengguna hanya boleh terdaftar satu kali dalam satu grup yang sama.
* `Index (group_id, is_active)` dan `Index (user_id, is_active)` untuk optimasi pencarian keanggotaan aktif.

### 4.4 `group_invitations`
Menyimpan kode undangan untuk bergabung ke grup keuangan keluarga.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE RESTRICT), NOT NULL |
| `created_by_user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NOT NULL |
| `code_hash` | VARCHAR(255) | UNIQUE, NOT NULL |
| `expires_at` | DATETIME | NOT NULL |
| `max_uses` | INT | NOT NULL, DEFAULT 1, CHECK (max_uses >= 1) |
| `uses_count` | INT | NOT NULL, DEFAULT 0, CHECK (uses_count >= 0) |
| `is_revoked` | BOOLEAN | DEFAULT FALSE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Keamanan:**
* Kode undangan disimpan dalam bentuk *hash* (SHA-256 / bcrypt), jangan pernah simpan kode *plaintext*.
* Undangan memiliki batas waktu kedaluwarsa (`expires_at`) dan batas kuota penggunaan (`max_uses`).
* Pemilik/admin dapat mencabut kode undangan kapan saja (`is_revoked = TRUE`).

### 4.5 `categories`
Menyimpan kategori pemasukan dan pengeluaran.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `name` | VARCHAR(100) | NOT NULL |
| `type` | VARCHAR(20) | NOT NULL, CHECK ('income', 'expense') |
| `icon` | VARCHAR(50) | NULLABLE |
| `color` | VARCHAR(20) | NULLABLE |
| `is_system` | BOOLEAN | DEFAULT FALSE |
| `user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NULLABLE |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE RESTRICT), NULLABLE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Constraints:**
* Kategori bawaan sistem memiliki `is_system = TRUE`, `user_id = NULL`, dan `group_id = NULL`.
* Kategori kustom bersifat personal (`user_id` terisi, `group_id` NULL) atau grup (`group_id` terisi, `user_id` NULL).
* Constraint: `(user_id IS NULL OR group_id IS NULL)` — kategori tidak boleh merangkap personal dan grup.

### 4.6 `receipts`
Menyimpan metadata berkas struk fisik yang diunggah dan hasil ekstraksi OCR.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NOT NULL |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE RESTRICT), NULLABLE |
| `file_path` | VARCHAR(500) | NOT NULL |
| `file_name` | VARCHAR(255) | NOT NULL |
| `file_size` | INT | NOT NULL |
| `mime_type` | VARCHAR(100) | NOT NULL |
| `merchant_name` | VARCHAR(255) | NULLABLE |
| `receipt_date` | DATETIME | NULLABLE |
| `total_amount` | DECIMAL(15,2) | NULLABLE |
| `raw_ocr_data` | JSON | NULLABLE |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'draft', CHECK ('draft', 'confirmed', 'rejected', 'failed') |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Keamanan:**
* Berkas struk disimpan dalam direktori privat (*private storage*), bukan folder publik.
* Ekstraksi OCR berstatus `draft` hingga pengguna mengonfirmasi sebelum dikonversi menjadi transaksi.

### 4.7 `transactions`
Menyimpan transaksi keuangan utama (Personal Ledger dan Shared Group Ledger).

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `type` | VARCHAR(20) | NOT NULL, CHECK ('income', 'expense') |
| `amount` | DECIMAL(15,2) | NOT NULL, CHECK (amount > 0) |
| `category_id` | CHAR(36) | FK -> categories.id (ON DELETE RESTRICT), NOT NULL |
| `transaction_date` | DATETIME | NOT NULL |
| `description` | VARCHAR(255) | NULLABLE |
| `notes` | TEXT | NULLABLE |
| `owner_user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NULLABLE |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE RESTRICT), NULLABLE |
| `created_by_user_id` | CHAR(36) | FK -> users.id (ON DELETE RESTRICT), NOT NULL |
| `input_method` | VARCHAR(20) | NOT NULL, DEFAULT 'manual', CHECK ('manual', 'ocr', 'voice') |
| `receipt_id` | CHAR(36) | FK -> receipts.id (ON DELETE SET NULL), NULLABLE |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Business Rules:**
* **Personal Transaction:** `owner_user_id` terisi, `group_id` NULL.
* **Group Transaction:** `owner_user_id` NULL, `group_id` terisi.
* `created_by_user_id` selalu mencatat pengguna yang melakukan input transaksi.
* CHECK Constraint: `((owner_user_id IS NOT NULL AND group_id IS NULL) OR (owner_user_id IS NULL AND group_id IS NOT NULL))`.
* Nominal wajib `DECIMAL(15,2)` dan lebih besar dari 0.

### 4.8 `transaction_items`
Menyimpan rincian item/barang individual dari struk (OCR) atau transaksi belanja.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `transaction_id` | CHAR(36) | FK -> transactions.id (ON DELETE CASCADE), NULLABLE |
| `receipt_id` | CHAR(36) | FK -> receipts.id (ON DELETE CASCADE), NULLABLE |
| `item_name` | VARCHAR(255) | NOT NULL |
| `quantity` | DECIMAL(10,2) | NOT NULL, DEFAULT 1.00, CHECK (quantity > 0) |
| `price_per_unit` | DECIMAL(15,2) | NOT NULL, CHECK (price_per_unit >= 0) |
| `total_price` | DECIMAL(15,2) | NOT NULL, CHECK (total_price >= 0) |
| `created_at` | DATETIME | NOT NULL |
| `updated_at` | DATETIME | NOT NULL |

**Catatan & Constraints:**
* Minimal salah satu dari `transaction_id` atau `receipt_id` harus terisi.
* Memungkinkan pencatatan daftar barang saat masih berstatus draft struk maupun setelah tersimpan sebagai transaksi.

### 4.9 `audit_logs`
Menyimpan jejak aktivitas penting untuk akuntabilitas dan keamanan sistem.

| Column | Type | Constraint |
| :--- | :--- | :--- |
| `id` | CHAR(36) | PK |
| `user_id` | CHAR(36) | FK -> users.id (ON DELETE SET NULL), NULLABLE |
| `group_id` | CHAR(36) | FK -> finance_groups.id (ON DELETE SET NULL), NULLABLE |
| `action` | VARCHAR(100) | NOT NULL |
| `entity_type` | VARCHAR(50) | NOT NULL |
| `entity_id` | CHAR(36) | NULLABLE |
| `details` | JSON | NULLABLE |
| `ip_address` | VARCHAR(45) | NULLABLE |
| `user_agent` | VARCHAR(255) | NULLABLE |
| `created_at` | DATETIME | NOT NULL |

**Catatan & Keamanan:**
* Dilarang keras menyimpan password, hash password, token JWT, atau kredensial lain di dalam `details`.
* Mencatat aktivitas krusial seperti pembuatan transaksi, pengubahan transaksi, penghapusan transaksi, penambahan anggota, dan perubahan role.

## 5. Indexing & Optimization Strategy

1. **Pencarian Personal:**
   * `ix_transactions_personal_date (owner_user_id, transaction_date)`: Mempercepat filter riwayat transaksi pribadi dan dashboard personal.
2. **Pencarian Grup:**
   * `ix_transactions_group_date (group_id, transaction_date)`: Mempercepat perhitungan dashboard Shared Ledger keluarga.
3. **Keanggotaan & Undangan:**
   * `ix_group_members_group_active (group_id, is_active)`
   * `ix_group_members_user_active (user_id, is_active)`
   * `ix_invitations_group_status (group_id, is_revoked, expires_at)`
4. **Audit Trail:**
   * `ix_audit_logs_group_created (group_id, created_at)`
   * `ix_audit_logs_user_created (user_id, created_at)`
   * `ix_audit_logs_entity (entity_type, entity_id)`