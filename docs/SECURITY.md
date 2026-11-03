# SECURITY POLICY

## 1. Authentication

* Password harus di-*hash*.
* *Endpoint* privat wajib membutuhkan autentikasi.
* Gunakan mekanisme *token* atau *secure session*.
* Terapkan *rate limiting* pada *login*.

## 2. Authorization

* Validasi kepemilikan transaksi personal.
* Validasi *membership* grup.
* Validasi *role* anggota.
* Jangan mempercayai *role* dari *frontend*.
* Cegah IDOR (*Insecure Direct Object Reference*).

## 3. Database Security

* Gunakan *parameterized query* atau ORM.
* Jangan *hardcode credential*.
* Gunakan *environment variables*.
* Batasi hak akses akun database.
* Jangan membuka MySQL ke internet secara langsung.

## 4. File Upload Security

* Validasi MIME *type* dan ekstensi.
* Batasi ukuran file.
* Gunakan nama file acak.
* Simpan file secara privat.
* Jangan menyimpan *upload* di *public folder*.
* Periksa akses sebelum mengirim file.

## 5. Invitation Security

* Kode undangan harus acak.
* Simpan *hash* kode.
* Gunakan *expiry* (masa berlaku).
* Gunakan batas penggunaan.
* Sediakan *revocation* (pencabutan akses).
* Terapkan *rate limiting*.

## 6. API Security

* Validasi seluruh *request*.
* Batasi CORS.
* Gunakan HTTPS.
* Jangan mengembalikan *stack trace*.
* Jangan mengekspos data sensitif.

## 7. Privacy

* Data personal tidak boleh diakses pengguna lain.
* Data grup hanya dapat diakses anggota aktif.
* *Audit log* tidak boleh menyimpan password atau *token*.
* Batasi penyimpanan data OCR yang tidak diperlukan.

## 8. Production Checklist

* [ ] HTTPS aktif.
* [ ] *Secret* tidak berada di Git.
* [ ] Password di-*hash*.
* [ ] Authorization *backend* aktif.
* [ ] *Upload* privat.
* [ ] *Rate limiting* aktif.
* [ ] Database tidak terbuka untuk publik.
* [ ] *Backup* database tersedia.