# PRODUCT REQUIREMENTS DOCUMENT (PRD)
## Personal & Family Finance Tracker

### 1. Deskripsi Produk

Aplikasi PWA untuk membantu pengguna mengelola keuangan pribadi dan keluarga. Pengguna dapat mencatat pemasukan, pengeluaran, memindai struk menggunakan OCR, serta memasukkan transaksi melalui suara.

### 2. Tujuan

- Mempermudah pencatatan keuangan.
- Menampilkan ringkasan pemasukan dan pengeluaran.
- Mendukung pencatatan keuangan keluarga secara bersama.
- Mengurangi input manual menggunakan OCR dan voice input.
- Menjaga privasi data setiap pengguna.

### 3. Target Pengguna

- Individu.
- Keluarga.
- Anggota keluarga yang ingin mengelola keuangan bersama.

### 4. Keputusan Produk

- **Platform:** PWA.
- **Frontend:** Next.js + TypeScript.
- **Backend:** FastAPI.
- **Database:** MySQL 8.
- Personal Finance dan Family Finance.
- Shared Ledger untuk pencatatan keluarga.
- Satu pengguna dapat bergabung ke beberapa grup.
- Undangan grup menggunakan kode.
- OCR memprioritaskan solusi open-source.
- Voice input mendukung Bahasa Indonesia.
- Mata uang utama: Rupiah (IDR).

### 5. Fitur Utama

#### 5.1 Authentication
- Register.
- Login.
- Logout.
- Profile.
- Change Password.

#### 5.2 Personal Finance
- Dashboard pribadi.
- Tambah pemasukan.
- Tambah pengeluaran.
- Edit dan hapus transaksi.
- Kategori transaksi.
- Riwayat transaksi.
- Filter berdasarkan tanggal dan kategori.
- Laporan keuangan.

#### 5.3 Family Finance
- Membuat grup keluarga.
- Mengundang anggota menggunakan kode.
- Bergabung ke beberapa grup.
- Melihat anggota grup.
- Mengelola role anggota.
- Melihat transaksi bersama.
- Menambahkan pemasukan dan pengeluaran grup.
- Dashboard keuangan grup.
- Riwayat aktivitas pencatatan.

#### 5.4 Role Anggota

**Owner:**
- Mengelola seluruh grup.
- Mengelola anggota.
- Membuat dan mencabut kode undangan.
- Mengelola transaksi.

**Admin:**
- Mengelola anggota dan undangan.
- Mengelola transaksi grup.

**Member:**
- Melihat transaksi grup.
- Menambahkan transaksi.
- Mengedit dan menghapus transaksi miliknya sendiri.

#### 5.5 Manual Transaction

Setiap transaksi memiliki:
- Jenis transaksi.
- Nominal.
- Kategori.
- Tanggal.
- Deskripsi.
- Scope pencatatan.
- Identitas pembuat.
- Metode input.

#### 5.6 OCR Receipt
- Upload foto struk.
- Membaca nama toko.
- Membaca tanggal.
- Membaca total pembayaran.
- Membaca daftar barang jika tersedia.
- Menampilkan hasil OCR sebagai draft.
- Pengguna wajib mengonfirmasi sebelum menyimpan.

#### 5.7 Voice Input
- Input transaksi melalui suara.
- Mendukung Bahasa Indonesia formal dan percakapan.
- Mengubah suara menjadi teks.
- Mengidentifikasi jenis dan nominal transaksi.
- Menampilkan draft sebelum disimpan.

#### 5.8 Dashboard
- Total pemasukan.
- Total pengeluaran.
- Saldo bersih.
- Grafik transaksi.
- Riwayat transaksi.
- Filter periode.

> *Catatan:* Dashboard keluarga menampilkan data berdasarkan grup yang sedang dipilih.

### 6. Aturan Bisnis

- Transaksi personal hanya dapat diakses pemiliknya.
- Transaksi grup hanya dapat diakses anggota aktif.
- Transaksi grup tidak otomatis masuk ke laporan personal pembuatnya.
- `created_by_user_id` menunjukkan pembuat transaksi.
- `owner_user_id` menunjukkan pemilik transaksi personal.
- `group_id` menunjukkan ruang pencatatan grup.
- Setiap transaksi hanya boleh memiliki satu scope.
- Hasil OCR dan voice harus dikonfirmasi.
- Nominal transaksi harus lebih besar dari nol.

### 7. Non-Functional Requirements

- Password menggunakan hashing aman.
- API wajib memiliki autentikasi.
- Hak akses divalidasi backend.
- File struk disimpan secara privat.
- Aplikasi responsive.
- PWA dapat di-install pada browser yang mendukung.
- Database memiliki backup.
- Gunakan HTTPS pada production.

### 8. Di Luar MVP

- Split Expense.
- Pembagian utang anggota.
- Integrasi bank.
- Integrasi e-wallet.
- Pembayaran antaranggota.
- Prediksi keuangan AI.
- Multi-currency.

### 9. Kriteria Keberhasilan

- Pengguna dapat mencatat transaksi pribadi.
- Pengguna dapat membuat grup keluarga.
- Pengguna dapat bergabung melalui kode.
- Pengguna dapat bergabung ke beberapa grup.
- Anggota dapat mencatat transaksi bersama.
- Data personal dan grup tidak tercampur.
- OCR dan voice dapat menghasilkan draft transaksi.
- Pengguna dapat mengonfirmasi hasil input.