# RANCANGAN SINKRONISASI OFFLINE-FIRST (OFFLINE SYNC DESIGN)
**Project:** SakuKu Mobile  
**Database Lokal:** Drift (SQLite 3 via `sqlite3_flutter_libs`)  
**Database Pusat:** PostgreSQL 16+ via FastAPI  
**Tujuan:** Menjamin keandalan pencatatan offline tanpa kehilangan data (*zero data loss*) dan sinkronisasi tanpa duplikasi (*idempotent sync*).

---

## 1. Arsitektur Database Lokal (Drift / SQLite)

Aplikasi mobile menggunakan **Drift** sebagai Object-Relational Mapping (ORM) tipe aman untuk SQLite. Struktur tabel lokal dirancang untuk menampung data transaksi sekaligus metadata sinkronisasinya.

### 1.1 Tabel `local_transactions`

```dart
class LocalTransactions extends Table {
  // Primary key lokal aplikasi: UUID v4 yang dibuat di HP saat pencatatan
  TextColumn get id => text()();

  // ID dari PostgreSQL backend (berisi NULL jika transaksi belum pernah tersinkronisasi)
  TextColumn get remoteId => text().nullable()();

  // Jenis transaksi: 'income' atau 'expense'
  TextColumn get type => text()();

  // Nominal uang disimpan sebagai String atau Int64 untuk menjamin presisi (menghindari floating-point error)
  TextColumn get amount => text()();

  // Relasi ke kategori
  TextColumn get categoryId => text()();

  // Waktu aktual transaksi (UTC)
  DateTimeColumn get transactionDate => dateTime()();

  // Deskripsi dan catatan opsional
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();

  // Metode input: 'manual', 'ocr', 'voice'
  TextColumn get inputMethod => text().withDefault(const Constant('manual'))();

  // Kepemilikan akun lokal
  TextColumn get userId => text()();

  // --- KOLOM METADATA SINKRONISASI ---
  // Status: 'pending_create' | 'pending_update' | 'pending_delete' | 'synced' | 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('pending_create'))();

  // Pesan error jika sinkronisasi gagal (misal: validasi bisnis gagal)
  TextColumn get syncError => text().nullable()();

  // Jumlah percobaan sinkronisasi
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // Timestamp audit
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 1.2 Tabel `local_categories`

```dart
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  TextColumn get userId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 1.3 Indeks Database Lokal untuk Performa Cepat
* `ix_local_transactions_sync`: `(syncStatus, clientUpdatedAt ASC)` — mempercepat pencarian antrean data yang belum tersinkronisasi.
* `ix_local_transactions_date`: `(userId, transactionDate DESC)` — mempercepat render riwayat transaksi.
* `ix_local_transactions_remote`: `(remoteId)` — mempercepat pencocokan saat menerima data dari server.

---

## 2. Status Siklus Hidup Data Lokal (*Data Sync Lifecycle*)

Setiap baris transaksi di SQLite lokal memiliki siklus hidup status sebagai berikut:

```
[ User Catat Baru ]
        |
        v
  pending_create  --------( Sukses Kirim POST )-------->   synced
        |                                                     |
        | (Gagal Jaringan / Offline)                          | (User Edit Offline)
        v                                                     v
   (Tetap di SQLite,                                    pending_update
   tunggu internet)                                           |
                                                              | (Sukses Kirim PATCH)
                                                              v
                                                           synced
                                                              |
                                                              | (User Hapus Offline)
                                                              v
                                                        pending_delete (Tombstone)
                                                              |
                                                              | (Sukses Kirim DELETE)
                                                              v
                                                       [ Hard Delete dari SQLite ]
```

1. **`pending_create`**: Transaksi baru dibuat di HP secara offline. Belum memiliki `remote_id`.
2. **`synced`**: Transaksi sudah tersimpan identik di backend PostgreSQL dan SQLite lokal.
3. **`pending_update`**: Transaksi yang sebelumnya sudah `synced` diedit oleh user saat offline.
4. **`pending_delete` (Tombstone)**: Transaksi dihapus oleh user saat offline. Record tidak langsung di-drop dari SQLite agar HP masih mengingat `remote_id` yang harus dihapus di backend saat online kembali.
5. **`failed`**: Terjadi error validasi dari backend (contoh: kategori yang dipilih telah dihapus). Error dicatat di kolom `sync_error`.

---

## 3. Mekanisme Sinkronisasi Dua Arah (*Two-Way Sync Flow*)

Sinkronisasi dijalankan oleh modul `SyncEngine` yang dieksekusi saat:
1. Pengguna membuka aplikasi pertama kali setelah online.
2. Listener jaringan (`connectivity_plus`) mendeteksi koneksi beralih dari Offline ke Online.
3. Pengguna melakukan aksi *Pull-to-Refresh* manual di layar transaksi atau dashboard.

Proses sinkronisasi terdiri dari 2 fase yang dieksekusi secara berurutan: **Fase Push** lalu **Fase Pull**.

```
+-----------------------------------------------------------------------------+
|                                SYNC ENGINE                                  |
+-----------------------------------------------------------------------------+
                                       |
                [ Cek Koneksi Internet & Token JWT Valid ]
                                       |
         +-----------------------------+-----------------------------+
         |                                                           |
         v                                                           v
   [ 1. FASE PUSH (Local -> Server) ]             [ 2. FASE PULL (Server -> Local) ]
   - Ambil data pending_create                    - Unduh data transaksi terbaru
     -> POST /api/v1/transactions                   -> GET /api/v1/transactions
     -> Simpan remote_id, set 'synced'            - Unduh kategori aktif
   - Ambil data pending_update                      -> GET /api/v1/categories
     -> PATCH /api/v1/transactions/{remote_id}    - Reconcile ke Drift SQLite
     -> Set 'synced'                              - Update last_synced_at
   - Ambil data pending_delete
     -> DELETE /api/v1/transactions/{remote_id}
     -> Hapus fisik dari SQLite
```

### 3.1 Fase Push (Kirim Perubahan Lokal ke Server)
1. Query semua transaksi dengan `sync_status IN ('pending_create', 'pending_update', 'pending_delete')` diurutkan berdasarkan `client_updated_at ASC`.
2. **Untuk `pending_create`:**
   - Kirim HTTP `POST /api/v1/transactions` dengan payload:
     `{ "type", "amount", "category_id", "transaction_date", "description", "notes", "input_method" }`.
   - Backend membalas dengan status 201 dan JSON `TransactionResponse` yang berisi `id` resmi server.
   - Update baris lokal: `remoteId = response.id`, `syncStatus = 'synced'`, `lastSyncedAt = DateTime.now()`.
3. **Untuk `pending_update`:**
   - Jika record belum punya `remote_id` (karena dibuat lalu langsung diedit saat masih offline), lewati dan tunggu `pending_create` selesai terlebih dahulu.
   - Jika sudah ada `remote_id`: Kirim HTTP `PATCH /api/v1/transactions/{remote_id}`.
   - Update baris lokal: `syncStatus = 'synced'`.
4. **Untuk `pending_delete`:**
   - Jika record belum punya `remote_id` (transaksi dibuat offline lalu dihapus saat masih offline), langsung hapus permanen dari SQLite tanpa perlu mengirim apapun ke server!
   - Jika sudah ada `remote_id`: Kirim HTTP `DELETE /api/v1/transactions/{remote_id}`.
   - Setelah server membalas HTTP 200, hapus baris fisik dari SQLite lokal.

### 3.2 Fase Pull (Tarik Pembaruan dari Server ke Lokal)
1. Unduh data kategori via `GET /api/v1/categories` -> simpan/perbarui di `local_categories`.
2. Unduh transaksi terbaru via `GET /api/v1/transactions?page=1&page_size=100`.
3. Untuk setiap item dari server:
   - Cari di SQLite lokal berdasarkan `remote_id == item.id`.
   - **Jika tidak ditemukan:** Berarti ini transaksi baru yang dibuat dari perangkat lain atau web. Masukkan ke SQLite lokal dengan status `synced`.
   - **Jika ditemukan:**
     - Jika status lokal adalah `synced`: Update data lokal sesuai data server (server *wins* jika tidak ada pending edit).
     - Jika status lokal adalah `pending_update` atau `pending_delete`: **Jangan ditimpa**, biarkan perubahan lokal diproses terlebih dahulu pada siklus Push berikutnya.

---

## 4. Resolusi Konflik (*Conflict Resolution*)

Konflik data dapat terjadi jika transaksi yang sama diubah di web dan di aplikasi mobile secara bersamaan:

### Aturan Resolusi:
1. **Lokal Sedang Ada Pending Edit (`pending_update` vs Server Modifikasi):**
   - **Aturan: Client Intent Wins (Perubahan Pengguna di Tangan Lebih Utama).**  
     Ketika pengguna secara eksplisit mengedit data di HP, aplikasi tetap akan mem-push perubahannya ke server via `PATCH`. Server akan memperbarui data sesuai edit terbaru pengguna.
2. **Hapus vs Edit (Deleted on Server, Edited on Local):**
   - Jika transaksi telah dihapus di server oleh sesi web, lalu HP mencoba mengirim `PATCH /api/v1/transactions/{remote_id}`, backend akan mengembalikan `HTTP 404 Not Found`.
   - **Penanganan Flutter:** Drift mendeteksi error 404 pada operasi `PATCH`. Sistem mengasumsikan transaksi telah dihapus dari server, lalu memberikan opsi ke user: hapus dari lokal atau jadikan transaksi baru (`pending_create` baru tanpa `remote_id`).
3. **Kategori yang Digunakan Telah Dihapus di Server:**
   - Backend memvalidasi `category_id` saat `POST` atau `PATCH`. Jika kategori tidak ada, backend membalas `HTTP 400 Bad Request: Category not found`.
   - **Penanganan Flutter:** Transaksi ditandai `sync_status = 'failed'`, pesan error disimpan di `sync_error`. UI menampilkan tanda seru merah pada transaksi tersebut dengan tombol: *"Kategori tidak tersedia, pilih kategori baru"*.

---

## 5. Pencegahan Duplikasi (*Idempotency Guarantee*)

Skenario umum masalah jaringan: HP mengirim `POST /transactions`, backend berhasil menyimpan data ke PostgreSQL, namun koneksi terputus sesaat sebelum backend mengirim response HTTP 201 kembali ke HP. Akibatnya HP mengira request gagal dan akan mencoba mengirim ulang saat koneksi kembali (*duplicate insert*).

### Strategi Idempotensi di Flutter:
1. **Pre-flight Check sebelum Retry:**
   Sebelum mencoba mengirim ulang `pending_create` yang mengalami timeout, `SyncEngine` dapat melakukan kueri cepat ke `GET /transactions` dengan filter rentang waktu dan nominal yang sama untuk mengecek apakah transaksi tersebut sebenarnya sudah tercatat di server.
2. **Mapping UUID Lokal dan Remote:**
   Setelah suatu record lokal berhasil mendapatkan `remote_id`, operasi selanjutnya selalu menggunakan `PATCH /transactions/{remoteId}`, sehingga pengiriman ulang tidak akan pernah menciptakan baris baru di PostgreSQL.

---

## 6. Strategi Retry & Ketahanan Koneksi (*Retry Strategy*)

1. **Exponential Backoff:**  
   Jika sinkronisasi gagal karena kendala jaringan (bukan error 4xx), sinkronisasi berikutnya tidak langsung ditembak seketika agar tidak menghabiskan baterai dan bandwidth pengguna:
   - Percobaan 1: Jeda 2 detik.
   - Percobaan 2: Jeda 5 detik.
   - Percobaan 3: Jeda 15 detik.
   - Percobaan 4+: Jeda 30 detik (maksimal).
2. **Network Listener Reconnect:**  
   Menggunakan `connectivity_plus`. Saat event `ConnectivityResult.wifi` atau `ConnectivityResult.mobile` terdeteksi setelah sebelumnya offline, counter retry di-reset dan antrean sinkronisasi langsung dipicu.
3. **Batas Retry Maksimal:**  
   Jika sebuah transaksi gagal tersinkronisasi sebanyak 5 kali berturut-turut karena error validasi server (HTTP 4xx), transaksi diubah statusnya menjadi `failed` agar tidak memblokir antrean transaksi lain di belakangnya.

---

## 7. Penanganan Token Kedaluwarsa Saat Offline (*Token Expiry Handling*)

Backend mengeluarkan JWT access token dengan masa berlaku 24 jam (1440 menit) tanpa mekanisme refresh token.

### Skenario & Penanganan:
1. **Kondisi:** Pengguna menggunakan aplikasi di daerah terpencil tanpa sinyal selama 3 hari. Token JWT telah kedaluwarsa setelah hari pertama.
2. **Aktivitas Offline Pengguna:**
   - Pengguna tetap dapat mencatat pemasukan dan pengeluaran setiap hari.
   - Semua transaksi tersimpan aman di SQLite lokal dengan status `pending_create`.
   - Dashboard dan riwayat tetap menghitung dan menampilkan saldo secara akurat.
3. **Saat Kembali Online:**
   - `SyncEngine` mencoba mengirim transaksi ke server.
   - Backend membalas dengan `HTTP 401 Unauthorized` (`"Invalid or expired token."`).
4. **Respon Dio Interceptor & Auth Controller:**
   - `ErrorInterceptor` menangkap status 401.
   - `SyncEngine` **segera dijeda (*paused*)**.
   - **DILARANG MENGHAPUS DATABASE SQLITE!** (Banyak aplikasi salah menghapus local DB saat logout/401; ini fatal karena data un-synced akan hilang selamanya).
   - Simpan status di Secure Storage: `session_expired = true`.
   - Tampilkan dialog atau alihkan pengguna ke layar Login dengan username yang sudah terisi otomatis.
   - Berikan teks peringatan ramah: *"Sesi Anda telah berakhir demi keamanan. Silakan masukkan kata sandi Anda untuk menyinkronkan data transaksi."*
5. **Setelah Login Sukses:**
   - Token JWT baru disimpan ke `FlutterSecureStorage`.
   - `SyncEngine` diaktifkan kembali (*resumed*).
   - Seluruh antrean transaksi offline langsung diproses dan statusnya berubah menjadi `synced`.

---

## 8. Keamanan Data Lokal (*Local Data Security*)

1. **Penyimpanan Database:**
   File database SQLite (`app_database.sqlite`) disimpan di direktori privat aplikasi Android:  
   `/data/user/0/com.sakuku.mobile/databases/`  
   Direktori ini diproteksi oleh Linux sandboxing Android sehingga aplikasi lain tidak dapat membaca isinya tanpa akses root.
2. **Penyimpanan Token & Rahasia:**
   Token JWT dan kredensial sensitif disimpan menggunakan `flutter_secure_storage`, yang secara internal menggunakan **Android Keystore** dan `EncryptedSharedPreferences` dengan algoritma AES-256 GCM.
3. **Penyensoran Log (Log Sanitization):**
   Logging interceptor diatur agar tidak pernah mencetak header `Authorization` maupun string token ke logcat Android.
