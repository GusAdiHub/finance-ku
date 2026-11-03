# TESTING STRATEGY

## 1. Unit Testing

**Backend:**

* Validasi transaksi.
* Perhitungan saldo.
* Validasi kategori.
* Validasi role.
* Validasi kode undangan.
* Parsing OCR.
* Parsing voice.

## 2. Integration Testing

* Register dan login.
* CRUD transaksi personal.
* CRUD transaksi grup.
* Membuat grup.
* Bergabung ke grup.
* Keluar dari grup.
* Mengelola anggota.
* Upload receipt.
* Konfirmasi OCR.
* Dashboard personal dan grup.

## 3. Authorization Testing

**Skenario wajib:**

1. User A tidak dapat melihat transaksi personal User B.
2. User luar grup tidak dapat melihat transaksi grup.
3. Member tidak dapat mengedit transaksi anggota lain.
4. Member yang sudah keluar tidak dapat mengakses grup.
5. User tidak dapat memanipulasi `group_id` untuk mengakses grup lain.
6. User tidak dapat mengubah `created_by_user_id`.
7. Kode undangan *expired* harus ditolak.

## 4. Frontend Testing

* Form validation.
* Navigation.
* Responsive design.
* Loading state.
* Empty state.
* Error state.
* Success state.
* PWA installability.

## 5. Acceptance Criteria

Fitur hanya dapat dianggap selesai apabila:

* Implementasi berjalan.
* Validasi berjalan.
* Test terkait lulus.
* Tidak ada error kritis.
* Hak akses sudah diuji.