# CODING STANDARDS

## General

* Gunakan kode yang mudah dibaca.

* Gunakan penamaan yang konsisten.

* Hindari duplikasi.

* Hindari fungsi yang terlalu panjang.

* Jangan menambahkan *dependency* tanpa alasan.

## Frontend

* Gunakan TypeScript.

* Gunakan komponen *reusable*.

* Pisahkan *business logic* dari UI.

* Gunakan *feature-based folder structure*.

* Tangani *loading*, *error*, dan *empty state*.

* Validasi *input* sebelum dikirim ke *backend*.

## Backend

* Gunakan FastAPI.

* Gunakan Pydantic.

* Gunakan SQLAlchemy.

* Pisahkan *router*, *service*, *repository*, *schema*, dan *model*.

* Gunakan *dependency injection*.

* Gunakan *type hints*.

* Jangan *expose* ORM *model* secara langsung.

## Database

* Semua perubahan *schema* melalui Alembic.

* Gunakan *foreign key*.

* Gunakan `DECIMAL` untuk nominal uang.

* Gunakan *index* pada kolom yang sering dicari.

* Hindari *cascade delete* untuk data finansial.

## Git

* Jangan *commit* file `.env`.

* Jangan *commit* *database dump*.

* Jangan *commit* file *upload*.

* Gunakan *commit message* yang jelas.