# ARSITEKTUR APLIKASI FLUTTER MOBILE
**Project:** SakuKu Mobile (Finance Tracker)  
**Platform:** Flutter Android (Min SDK: 21, Target SDK: 34+)  
**Arsitektur:** Feature-First Clean Architecture + Offline-First  
**State Management:** Riverpod 3.x (`flutter_riverpod`)  
**Routing:** GoRouter  
**Local Database:** Drift (SQLite)  
**HTTP Client:** Dio  
**Secure Storage:** Flutter Secure Storage

---

## 1. Prinsip Arsitektur Utama

Aplikasi dirancang menggunakan prinsip **Feature-First Clean Architecture** dengan pemisahan tanggung jawab yang ketat. Pendekatan ini menjamin kode mudah diuji (*testable*), mudah diperluas (*extensible*), serta menjaga *business logic* independen dari framework UI maupun network layer.

```
+------------------------------------------------------------------------+
|                           PRESENTATION LAYER                           |
|       [Screens]  <--->  [Riverpod Notifiers]  <--->  [UI State]        |
+------------------------------------------------------------------------+
                                   |
                                   v
+------------------------------------------------------------------------+
|                              DOMAIN LAYER                              |
|           [Entities]  <--->  [Repository Interfaces / Use Cases]       |
+------------------------------------------------------------------------+
                                   |
                                   v
+------------------------------------------------------------------------+
|                               DATA LAYER                               |
|                     [Repository Implementations]                       |
|                                   |                                    |
|          +------------------------+------------------------+           |
|          v                                                 v           |
|  [Local Data Source]                             [Remote Data Source]  |
|  - Drift Database (SQLite)                       - Dio HTTP Client     |
|  - Offline Sync Queue                            - FastAPI Endpoints   |
|  - Secure Storage (JWT)                                                |
+------------------------------------------------------------------------+
```

### Prinsip Operasional Offline-First:
1. **Single Source of Truth untuk UI adalah Database Lokal (Drift):**  
   Widget tidak pernah langsung menunggu response dari jaringan (Dio) untuk menampilkan daftar transaksi. Widget mendengarkan stream data dari database SQLite lokal. Setiap kali data tersimpan ke SQLite, UI otomatis ter-update via `StreamProvider`.
2. **Pencatatan Instan (Zero Latency Input):**  
   Ketika user menekan tombol "Simpan Transaksi", transaksi langsung disimpan ke SQLite lokal dengan status `pending_create`. Form langsung tertutup dan user melihat transaksi di riwayat dalam hitungan milidetik.
3. **Background Synchronization:**  
   Proses pengiriman ke server FastAPI berjalan di latar belakang melalui `SyncEngine`. Jika ada koneksi, status berubah menjadi `synced`. Jika tidak ada internet, data tetap aman tersimpan di HP.

---

## 2. Struktur Direktori Proyek (`mobile/lib/`)

Struktur proyek diatur berdasarkan fitur (*feature-first*) dengan folder `core/` untuk modul bersama:

```
mobile/lib/
├── main.dart                          # Entrypoint aplikasi, ProviderScope, inisialisasi Drift & SecureStorage
├── app.dart                           # MaterialApp.router, konfigurasi tema, dan GoRouter binding
│
├── core/                              # Shared foundation layer
│   ├── constants/
│   │   ├── api_endpoints.dart         # URL path konstanta API
│   │   ├── app_colors.dart            # Palet warna tema
│   │   └── app_constants.dart         # Nilai konstanta aplikasi (pagination, timeout)
│   ├── database/                      # Drift SQLite setup
│   │   ├── app_database.dart          # Kelas utama Drift Database (@DriftDatabase)
│   │   ├── connection/
│   │   │   └── connection.dart        # Native SQLite connection setup (path_provider)
│   │   ├── daos/
│   │   │   ├── transactions_dao.dart  # Query & manipulasi transaksi lokal + agregasi dashboard
│   │   │   └── categories_dao.dart    # Query & manipulasi kategori lokal
│   │   └── tables/
│   │       ├── local_transactions.dart# Definisi skema tabel SQLite transaksi
│   │       ├── local_categories.dart  # Definisi skema tabel SQLite kategori
│   │       └── sync_metadata.dart     # Pelacak status sinkronisasi
│   ├── errors/
│   │   ├── exceptions.dart            # Kustom exception internal (ServerException, DatabaseException)
│   │   └── failures.dart              # Format kegagalan untuk Domain layer (Failure classes)
│   ├── network/                       # Jaringan & HTTP Client
│   │   ├── dio_client.dart            # Inisialisasi Dio instance & base options
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart  # Inject Bearer token dari FlutterSecureStorage
│   │   │   ├── error_interceptor.dart # Handle 401 Unauthorized, timeout, dan network error
│   │   │   └── logging_interceptor.dart# Debug logger
│   │   └── network_info.dart          # Deteksi status koneksi internet
│   ├── storage/
│   │   └── secure_storage_service.dart# Wrapper FlutterSecureStorage (token, user ID)
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData terang (Neobrutalism clean)
│   │   └── text_styles.dart           # Tipografi standar
│   └── utils/
│       ├── currency_formatter.dart    # Format IDR Rupiah (id-ID)
│       └── date_formatter.dart        # Format tanggal Indonesia
│
└── features/                          # Domain & Feature Modules
    ├── auth/                          # Autentikasi & Akun
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── auth_remote_datasource.dart
    │   │   │   └── auth_local_datasource.dart
    │   │   ├── models/
    │   │   │   ├── auth_token_model.dart
    │   │   │   └── user_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_entity.dart
    │   │   └── repositories/
    │   │       └── auth_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_controller.dart
    │       └── screens/
    │           ├── login_screen.dart
    │           ├── register_screen.dart
    │           └── profile_screen.dart
    │
    ├── categories/                    # Manajemen Kategori
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── category_remote_datasource.dart
    │   │   │   └── category_local_datasource.dart
    │   │   ├── models/
    │   │   │   └── category_model.dart
    │   │   └── repositories/
    │   │       └── category_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── category_entity.dart
    │   │   └── repositories/
    │   │       └── category_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── categories_controller.dart
    │       └── screens/
    │           └── categories_screen.dart
    │
    ├── transactions/                  # Pencatatan Transaksi
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── transaction_remote_datasource.dart
    │   │   │   └── transaction_local_datasource.dart
    │   │   ├── models/
    │   │   │   └── transaction_model.dart
    │   │   └── repositories/
    │   │       └── transaction_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── transaction_entity.dart
    │   │   └── repositories/
    │   │       └── transaction_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   ├── transaction_form_controller.dart
    │       │   └── transaction_list_controller.dart
    │       ├── screens/
    │       │   ├── transactions_screen.dart
    │       │   └── transaction_detail_screen.dart
    │       └── widgets/
    │           ├── transaction_form_modal.dart
    │           └── transaction_item_card.dart
    │
    ├── dashboard/                     # Ringkasan Keuangan
    │   ├── data/
    │   │   └── repositories/
    │   │       └── dashboard_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── dashboard_summary_entity.dart
    │   │   └── repositories/
    │   │       └── dashboard_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── dashboard_controller.dart
    │       ├── screens/
    │       │   └── dashboard_screen.dart
    │       └── widgets/
    │           ├── summary_balance_card.dart
    │           └── category_breakdown_card.dart
    │
    ├── reports/                       # Laporan & Analitik
    │   ├── data/
    │   │   └── repositories/
    │   │       └── report_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── report_entity.dart
    │   │   └── repositories/
    │   │       └── report_repository.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── report_controller.dart
    │       └── screens/
    │           └── reports_screen.dart
    │
    └── sync/                          # Mesin Sinkronisasi Dua Arah
        ├── data/
        │   └── sync_repository_impl.dart
        ├── domain/
        │   └── sync_service.dart
        └── presentation/
            └── sync_status_controller.dart
```

---

## 3. Tanggung Jawab Masing-Masing Layer

### 3.1 Presentation Layer
* **Widget / Screen:** Komponen UI murni (StatelessWidget/ConsumerWidget) yang hanya bertugas me-render state dan menangani interaksi pengguna (tap, swipe, input).
* **Controller / Notifier (Riverpod):** Mengelola state halaman menggunakan `AsyncNotifier` atau `Notifier`. Memanggil metode repository, mengubah data menjadi state yang dapat dibaca UI (Loading, Success, Error).
* **UI State:** Model data representasi tampilan yang bersifat *immutable*.

### 3.2 Domain Layer
* **Entities:** Objek bisnis inti murni (tanpa dependensi pada library eksternal seperti Drift atau Dio).
* **Repository Interfaces:** Kontrak abstrak yang mendefinisikan operasi apa saja yang tersedia untuk fitur tersebut tanpa peduli bagaimana data diambil.

### 3.3 Data Layer
* **Models (DTOs):** Objek representasi JSON/API atau SQLite yang memiliki metode serialisasi (`fromJson`, `toJson`, `toEntity`, `fromEntity`).
* **Data Sources:**
  - `RemoteDataSource`: Berkomunikasi langsung dengan API backend FastAPI via Dio.
  - `LocalDataSource`: Berkomunikasi dengan database lokal SQLite via Drift DAOs.
* **Repository Implementation:** Mengorkestrasi logika data: membaca dari database lokal, memicu background sync ke remote datasource, dan mengembalikan Entity ke Domain layer.

---

## 4. Manajemen State (Riverpod)

Aplikasi menggunakan **Flutter Riverpod (v3.x)** untuk dependency injection dan reactive state management:

### 4.1 Pola Provider yang Digunakan
1. **Repository & Service Providers:** Menggunakan provider dasar untuk menyediakan instance singleton repository, database, dan Dio client.
   ```dart
   final databaseProvider = Provider<AppDatabase>((ref) {
     return AppDatabase();
   });
   
   final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
     return TransactionRepositoryImpl(
       localDataSource: ref.watch(transactionLocalDataSourceProvider),
       remoteDataSource: ref.watch(transactionRemoteDataSourceProvider),
     );
   });
   ```
2. **StreamProvider untuk Data Reaktif Lokal:** Mendengarkan query Drift secara langsung sehingga setiap perubahan pada SQLite langsung memperbarui UI:
   ```dart
   final recentTransactionsStreamProvider = StreamProvider<List<TransactionEntity>>((ref) {
     final repository = ref.watch(transactionRepositoryProvider);
     return repository.watchRecentTransactions(limit: 5);
   });
   ```
3. **AsyncNotifierProvider untuk Mutasi Data:** Mengelola operasi asinkron (login, simpan transaksi) dengan state `AsyncValue`:
   ```dart
   final transactionFormControllerProvider = 
       AsyncNotifierProvider<TransactionFormController, void>(TransactionFormController.new);
   ```

---

## 5. Navigasi & Routing (GoRouter)

Navigasi dikelola oleh **GoRouter** dengan integrasi status autentikasi reaktif:

### 5.1 Route Hierarchy
* `/splash`: Layar pengecekan token awal.
* `/login`: Halaman masuk.
* `/register`: Halaman pendaftaran.
* `/app`: `StatefulShellRoute` dengan Bottom Navigation Bar:
  - Tab 0: `/app/dashboard` (Beranda)
  - Tab 1: `/app/transactions` (Riwayat Transaksi)
  - Tab 2: `/app/reports` (Laporan Keuangan)
  - Tab 3: `/app/categories` (Kelola Kategori)
* `/app/transactions/detail/:id`: Detail transaksi.

### 5.2 Redirect Guard (Auth Guard)
GoRouter memantau status `authNotifierProvider`:
- Jika pengguna belum memiliki token dan mencoba mengakses `/app/*`, otomatis dialihkan ke `/login`.
- Jika pengguna sudah terautentikasi dan berada di `/login` atau `/register`, otomatis dialihkan ke `/app/dashboard`.

---

## 6. Network Layer (Dio)

Konfigurasi Dio diisolasi di `core/network/dio_client.dart` dengan fitur ketahanan jaringan:

### 6.1 Base Options
* **BaseURL:** `http://10.0.2.2:8000/api/v1` (untuk Android Emulator ke localhost Mac) atau IP LAN riil (contoh: `http://192.168.1.x:8000/api/v1` untuk real device).
* **Connect Timeout:** 10 detik.
* **Receive Timeout:** 15 detik.
* **Headers:** `{"Accept": "application/json", "Content-Type": "application/json"}`.

### 6.2 Interceptor Pipeline
1. **`AuthInterceptor`:**
   - Membaca token JWT dari `FlutterSecureStorage`.
   - Menambahkan header `Authorization: Bearer <token>` pada setiap request privat.
2. **`ErrorInterceptor`:**
   - **401 Unauthorized:** Menandai sesi berakhir, men-trigger pause pada antrean sinkronisasi, dan memberi tahu `authController` untuk mengarahkan user ke login tanpa menghapus database SQLite lokal.
   - **Network Exceptions (`SocketException`, Timeout):** Mengonversi kegagalan jaringan menjadi `NetworkFailure` tanpa memicu crash aplikasi, sehingga layer repository tahu bahwa aplikasi sedang offline.
3. **`LoggingInterceptor`:** Mencatat request, response status, dan waktu eksekusi hanya saat aplikasi dijalankan dalam mode `kDebugMode`.
