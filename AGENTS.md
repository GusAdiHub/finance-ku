# AI CODING AGENT INSTRUCTIONS

## 1. Project Overview

Project ini adalah Personal & Family Finance Tracker berbasis PWA.

**Stack:**

* Next.js
* TypeScript
* FastAPI
* MySQL 8
* SQLAlchemy
* Alembic

## 2. Mandatory Documentation

Sebelum melakukan perubahan kode, baca dokumen yang relevan:

* `docs/PRD.md`
* `docs/WBS.md`
* `docs/ARCHITECTURE.md`
* `docs/TECH_STACK.md`
* `docs/DATABASE.md`
* `docs/API_SPEC.md`
* `docs/SECURITY.md`
* `docs/TESTING.md`

## 3. Product Decisions

Keputusan berikut sudah final:

* Family Finance menggunakan Shared Ledger.
* Satu pengguna dapat bergabung ke beberapa grup.
* Undangan grup menggunakan kode.
* Tidak ada Split Expense pada MVP.
* Database menggunakan MySQL.
* Backend menggunakan FastAPI.
* OCR memprioritaskan solusi open-source.
* Voice input menggunakan Bahasa Indonesia.

> **Catatan:** Jangan mengubah keputusan ini tanpa persetujuan.

## 4. Coding Rules

* Gunakan struktur modular.
* Hindari duplikasi kode.
* Pisahkan frontend dan backend.
* Gunakan SQLAlchemy ORM.
* Gunakan Alembic migration.
* Gunakan Pydantic.
* Jangan menaruh *business logic* di *router*.
* Gunakan *type hints*.
* Buat *test* untuk fitur penting.

## 5. Database Rules

* Jangan membuat tabel secara sembarangan.
* Ikuti `DATABASE.md`.
* Gunakan UUID.
* Gunakan `DECIMAL` untuk nominal uang.
* Gunakan *foreign key*.
* Gunakan *index* yang sesuai.
* Jangan mengubah *scope* transaksi tanpa memperbarui dokumentasi.
* Jangan menjalankan migration destruktif tanpa persetujuan.

## 6. Security Rules

* Jangan *hardcode password*.
* Jangan menyimpan *secret* di *source code*.
* Jangan mengekspos file *receipt*.
* Validasi setiap *request*.
* Validasi authorization di backend.
* Jangan mempercayai *role* dari frontend.
* Jangan mengirim data personal ke user lain.

## 7. Workflow

**Sebelum coding:**
1. Baca dokumentasi.
2. Periksa struktur repository.
3. Identifikasi file yang akan diubah.
4. Jelaskan rencana implementasi.

**Saat coding:**
1. Kerjakan satu fitur dalam satu waktu.
2. Hindari perubahan yang tidak diperlukan.
3. Jangan menghapus kode tanpa alasan.
4. Pertahankan kompatibilitas fitur yang sudah berjalan.

**Setelah coding:**
1. Jalankan *test*.
2. Periksa error.
3. Periksa perubahan database.
4. Perbarui `TASKS.md`.
5. Laporkan hasil implementasi.

## 8. Restrictions

**Jangan:**
* Membuat fitur di luar PRD tanpa persetujuan.
* Mengganti teknologi utama.
* Menghapus database.
* Mengubah migration lama yang sudah digunakan tanpa strategi.
* Mengarang hasil *testing*.
* Menyimpan credential ke Git.

## 9. Communication

Gunakan penjelasan yang sederhana dan langsung.

**Setiap pekerjaan harus melaporkan:**
* Apa yang dibuat.
* File yang diubah.
* *Test* yang dijalankan.
* Hasil *test*.
* Kendala.
* Langkah selanjutnya.