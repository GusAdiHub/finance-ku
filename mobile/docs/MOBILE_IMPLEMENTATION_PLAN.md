# RENCANA IMPLEMENTASI FLUTTER MOBILE (IMPLEMENTATION PLAN)
**Project:** SakuKu Mobile (Finance Tracker)  
**Target:** MVP Personal Finance Android (Offline-First)  
**Dokumen ini menjabarkan:** Tahapan implementasi, urutan pengerjaan fitur, analisis dependensi, dan checklist pengujian menyeluruh.

---

## 1. Analisis & Evaluasi Dependensi (`pubspec.yaml`)

### 1.1 Dependensi yang Sudah Terpasang
Berdasarkan pemeriksaan file `mobile/pubspec.yaml`, dependensi utama berikut sudah tersedia:

| Package | Versi di `pubspec.yaml` | Peran & Justifikasi |
| :--- | :--- | :--- |
| `flutter_riverpod` | `^3.4.3` | State management reaktif, dependency injection, dan stream provider. |
| `go_router` | `^18.1.3` | Deklaratif routing, deep linking, dan auth guard redirection. |
| `dio` | `^5.11.1` | HTTP client tangguh dengan interceptors untuk JWT auth dan error handling. |
| `flutter_secure_storage` | `^11.2.0` | Penyimpanan token JWT terenkripsi via Android Keystore. |
| `drift` | `^2.35.3` | ORM SQLite lokal dengan type-safety dan query reaktif. |
| `sqlite3_flutter_libs` | `^0.6.0+eol` | Driver native C SQLite binary untuk Android. |
| `path_provider` | `^2.1.6` | Menemukan path direktori aplikasi privat di sistem Android. |
| `drift_dev` *(dev)* | `^2.35.2` | Code generator untuk tabel, DAO, dan kueri Drift. |
| `build_runner` *(dev)* | `^2.17.1` | Generator runner untuk Dart/Flutter. |

### 1.2 Dependensi Tambahan yang Mutlak Diperlukan

Untuk memenuhi kebutuhan fitur tanpa menambah beban yang tidak perlu (*minimal footprint*), hanya 3 package tambahan yang diperlukan:

1. **`intl: ^0.19.0`**
   - **Alasan:** Diperlukan untuk format nominal mata uang Rupiah (`NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')`) dan format penanggalan bahasa Indonesia (`DateFormat`).
2. **`connectivity_plus: ^6.1.0`**
   - **Alasan:** Diperlukan oleh `SyncEngine` untuk mendeteksi secara instan kapan perangkat beralih dari mode offline ke online guna memicu sinkronisasi otomatis (*auto-retry on reconnect*).
3. **`uuid: ^4.5.1`**
   - **Alasan:** Diperlukan untuk men-generate UUID v4 lokal pada saat transaksi dibuat di SQLite dalam kondisi offline sebelum dikirim ke backend.

---

## 2. Tahapan Implementasi (Implementation Phases)

Pengembangan dibagi ke dalam 7 fase yang terstruktur secara berurutan:

```
+----------------------------------------------------------------------------+
| Fase 1: Core Foundation & Design System Setup                              |
| (Theme, SQLite Drift, Dio Interceptor, Secure Storage, Helpers)            |
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 2: Autentikasi & Akun Pengguna                                        |
| (Login, Register, Simpan Token, Auth Guard GoRouter, Profile)              |
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 3: Modul Kategori Transaksi                                           |
| (Kategori Sistem Drift Cache, Custom Categories CRUD, Kategori Dropdown)    |
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 4: Offline-First Transaction Engine                                    |
| (Pencatatan Lokal Instan, Drift DAO Transaksi, Riwayat & Filter Lokal)     |
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 5: Two-Way Synchronization Engine                                     |
| (Push Queue, Pull Reconcile, Connectivity Listener, Idempotency)           |
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 6: Dashboard & Laporan Keuangan                                       |
| (Local Aggregation Kueri, Ringkasan Saldo, Breakdown Kategori, Grafik Tren)|
+----------------------------------------------------------------------------+
                                      |
                                      v
+----------------------------------------------------------------------------+
| Fase 7: Pengujian, Error Handling & Hardening                              |
| (Simulasi Airplane Mode, Boundary Testing, Audit Memory, Build APK)        |
+----------------------------------------------------------------------------+
```

---

## 3. Rincian Pengerjaan Fitur per Fase

### Fase 1: Core Foundation & Design System Setup
* Mengonfigurasi `mobile/lib/core/` (Constants, Theme Neobrutalism clean, TextStyles).
* Mengonfigurasi database Drift (`AppDatabase`, `LocalTransactions`, `LocalCategories`, `SyncMetadata`).
* Mengonfigurasi Dio HTTP Client dengan `AuthInterceptor` dan `ErrorInterceptor`.
* Membuat helper format uang (`formatRupiah`) dan tanggal (`formatDate`).
* Menjalankan `dart run build_runner build` untuk meng-generate file `app_database.g.dart`.

### Fase 2: Autentikasi & Akun Pengguna
* Membuat `AuthRemoteDataSource` dan `AuthLocalDataSource`.
* Membuat `AuthRepositoryImpl` dan `AuthController` (Riverpod).
* Merancang UI `LoginScreen` dan `RegisterScreen`:
  - Input: Nama/Username, Email (opsional), Kata Sandi.
  - Checkbox "Ingat username di perangkat ini".
  - Validasi form (panjang password min 8 karakter).
* Menghubungkan GoRouter dengan status login (Redirect otomatis).
* Menangani alur login online pertama kali dan penyimpanan token ke `FlutterSecureStorage`.

### Fase 3: Modul Kategori Transaksi
* Membuat `CategoriesDao` di Drift.
* Sinkronisasi awal kategori sistem bawaan dari `GET /api/v1/categories` ke SQLite lokal saat login pertama.
* Mengimplementasikan `CategoriesScreen` untuk menampilkan daftar kategori (dipisah tab Pemasukan & Pengeluaran).
* Fitur tambah kategori kustom baru dan hapus kategori kustom.
* Memberikan penanda visual gembok / badge untuk kategori sistem agar pengguna tahu tidak bisa dihapus.

### Fase 4: Offline-First Transaction Engine
* Membuat `TransactionsDao` di Drift dengan kueri reaktif `watchAllTransactions()`.
* Membuat UI Bottom Sheet / Modal `TransactionFormModal`:
  - Toggle Pemasukan / Pengeluaran.
  - Input Nominal dengan keyboard numerik.
  - Dropdown Kategori dinamis (sesuai jenis transaksi).
  - DatePicker tanggal transaksi.
  - Input deskripsi / catatan.
* Logika simpan instan: Membuat UUID v4 lokal, insert ke SQLite dengan `sync_status = 'pending_create'`.
* Membuat `TransactionsScreen` (Riwayat Transaksi):
  - Daftar transaksi reaktif dari SQLite.
  - Indikator visual status sinkronisasi pada kartu transaksi (ikon awan/centang: Synced, awan putus: Pending Sync, tanda seru merah: Failed).
  - Fitur pencarian teks dan filter kategori/tanggal.

### Fase 5: Two-Way Synchronization Engine
* Membangun `SyncService` dan `SyncEngine`:
  - Eksekusi antrean Push (`pending_create`, `pending_update`, `pending_delete`).
  - Pembaruan `remote_id` dan perubahan status menjadi `synced`.
  - Eksekusi Pull (`GET /transactions` & `GET /categories`) untuk reconcile data dari server.
* Mengintegrasikan `connectivity_plus` untuk memicu auto-sync saat koneksi kembali.
* Menangani penolakan HTTP 401: Menjeda antrean sync tanpa menghapus SQLite lokal, lalu meminta autentikasi ulang.

### Fase 6: Dashboard & Laporan Keuangan
* Membangun kueri agregasi di `TransactionsDao`:
  - `calculateTotalIncome()`
  - `calculateTotalExpense()`
  - `calculateNetBalance()`
  - `getCategoryBreakdown()`
* Merancang `DashboardScreen`:
  - 3 kartu ringkasan: Total Pemasukan, Total Pengeluaran, Saldo Bersih.
  - Daftar 5 transaksi terakhir.
  - Diagram visual pengeluaran berdasarkan kategori.
* Merancang `ReportsScreen`:
  - Filter periode (Bulan ini, Minggu ini, Kustom).
  - Menghitung persentase tabungan (*Savings Rate*).
  - Grafik batang ringkasan tren bulanan.

### Fase 7: Pengujian, Polish & Hardening
* Pengujian simulasi jaringan mati (Airplane mode).
* Pengujian batas nominal (angka besar miliaran Rupiah).
* Pengujian idempotensi (re-try pengiriman tidak membuat duplikasi transaksi).
* Build release APK Android dan verifikasi performa memori.

---

## 4. Checklist Pengujian (Testing Checklist)

### 4.1 Unit & Logic Testing
- [ ] **Auth Token Storage:** Verifikasi token berhasil disimpan dan dibaca dari `FlutterSecureStorage`.
- [ ] **Currency Formatter:** `formatRupiah(50000)` menghasilkan string `"Rp 50.000"`.
- [ ] **Transaction Validation:** Nominal `0` atau minus ditolak dengan pesan validasi yang jelas.
- [ ] **Drift DAO CRUD:** Memastikan insert, update, dan soft-delete (tombstone) berhasil di SQLite in-memory.
- [ ] **Dashboard Aggregation:** Formula saldo `Income - Expense` akurat sesuai data di SQLite lokal.

### 4.2 Offline & Network Resilience Testing (Simulasi Airplane Mode)
- [ ] **Pencatatan Offline:** Aktifkan Airplane Mode -> Tambah 3 transaksi -> Pastikan transaksi muncul seketika di Riwayat dengan badge *Pending*.
- [ ] **Edit Offline:** Ubah nominal salah satu transaksi offline -> Pastikan nominal lokal ter-update dan status menjadi `pending_update`.
- [ ] **Hapus Offline:** Hapus salah satu transaksi offline -> Pastikan transaksi hilang dari daftar UI lokal, namun baris tombstone (`pending_delete`) tetap ada di SQLite.
- [ ] **Auto-Sync saat Reconnect:** Matikan Airplane Mode -> Pastikan `SyncEngine` mendeteksi jaringan -> Periksa seluruh transaksi terkirim ke backend PostgreSQL -> Status transaksi lokal berubah menjadi *Synced* -> Baris tombstone terhapus permanen dari SQLite.
- [ ] **Verifikasi Database PostgreSQL:** Buka Beekeeper Studio dan pastikan data di tabel `transactions` cocok dengan yang diinput dari HP.

### 4.3 Skenario Edge Case & Keamanan
- [ ] **Skenario Token Kedaluwarsa Saat Offline:** Jalankan aplikasi offline hingga token expired -> Aktifkan koneksi -> Pastikan aplikasi menangani HTTP 401 dengan elegan (tampil layar login ulang) dan **TIDAK menghapus data transaksi lokal yang belum tersinkronisasi**. Setelah login ulang berhasil, pastikan transaksi langsung ter-sync.
- [ ] **Skenario Kategori Berkonflik:** Pilih kategori yang tidak cocok dengan tipe transaksi -> Verifikasi backend menolak dengan HTTP 400 dan aplikasi mobile menampilkan feedback kesalahan.
- [ ] **Idempotensi Jaringan:** Matikan koneksi tepat di tengah-tengah request POST -> Pastikan tidak terjadi duplikasi data ganda di server saat koneksi kembali.
- [ ] **Kill App & Restart:** Tutup paksa aplikasi (*force stop*) saat offline -> Buka kembali -> Pastikan semua transaksi lokal yang belum ter-sync tetap utuh di layar.
