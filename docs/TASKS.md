# PROJECT TASKS

## Status

* Todo
* In Progress
* Blocked
* Done [x]

## Milestone 1 — Project Setup

* [x] Inisialisasi frontend Next.js.
* [x] Inisialisasi backend FastAPI.
* [x] Setup MySQL.
* [x] Setup SQLAlchemy.
* [x] Setup Alembic.

## Milestone 2 — Database

* [x] Model `users`.
* [x] Model `categories`.
* [x] Model `transactions`.
* [x] Model `finance_groups`.
* [x] Model `group_members`.
* [x] Model `group_invitations`.
* [x] Model `receipts`.
* [x] Model `transaction_items`.
* [x] Model `audit_logs`.
* [x] Migration awal disiapkan.
* [x] Eksekusi migration ke MySQL.
* [x] Database verification & seeding.

## Milestone 3 — Authentication

* [x] Register.
* [x] Login.
* [x] Logout.
* [x] Profile.
* [x] Password security.

## Milestone 4 — Personal Finance

* [x] CRUD transaksi.
* [x] Kategori.
* [x] Dashboard.
* [x] Riwayat.
* [x] Laporan.

## Milestone 5 — Family Finance

* [x] Create group.
* [x] Group members.
* [x] Role management.
* [x] Invitation code.
* [x] Join group.
* [x] Shared transactions.
* [x] Group dashboard.

## Milestone 6 — OCR & Voice

* [x] OCR upload & validation.
* [x] OCR extraction (Tesseract + Indonesian receipt heuristics).
* [x] OCR confirmation into transactions & line items.
* [x] Voice recognition (Web Speech API id-ID).
* [x] Voice parsing (Natural Indonesian speech to financial transactions).
* [x] Voice confirmation UI.

## Milestone 7 — Finalization & Deployment

* [x] Security testing (IDOR, spoofing prevention, token tampering).
* [x] Authorization testing (All 7 mandatory scenarios from docs/TESTING.md).
* [x] Integration testing across all endpoints.
* [x] Responsive layout & Mode Ramah Orang Tua (Elderly Mode).
* [x] Production Docker containers (FastAPI + Next.js standalone).
* [x] Production MySQL configuration & migration entrypoint.
* [x] Nginx Reverse Proxy with HTTPS & security headers.
* [x] Automated database backup & restore scripts.
