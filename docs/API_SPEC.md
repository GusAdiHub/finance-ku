# API SPECIFICATION

**Base URL:** 
`/api/v1`

## Authentication

* `POST /auth/register`
* `POST /auth/login`
* `POST /auth/logout`
* `GET /auth/me`
* `PATCH /auth/me`
* `POST /auth/change-password`

## Transactions

* `GET /transactions`
* `POST /transactions`
* `GET /transactions/{id}`
* `PATCH /transactions/{id}`
* `DELETE /transactions/{id}`

## Categories

* `GET /categories`
* `POST /categories`
* `PATCH /categories/{id}`
* `DELETE /categories/{id}`

## Dashboard

* `GET /dashboard/personal`
* `GET /groups/{group_id}/dashboard`

## Groups

* `POST /groups`
* `GET /groups`
* `GET /groups/{group_id}`
* `PATCH /groups/{group_id}`

* `GET /groups/{group_id}/members`
* `PATCH /groups/{group_id}/members/{member_id}`
* `DELETE /groups/{group_id}/members/{member_id}`

* `POST /groups/{group_id}/leave`

## Invitations

* `POST /groups/{group_id}/invitations`
* `GET /groups/{group_id}/invitations`
* `POST /groups/join`
* `DELETE /groups/{group_id}/invitations/{invitation_id}`

## Receipts

* `POST /receipts`
* `GET /receipts/{id}`
* `POST /receipts/{id}/confirm`
* `DELETE /receipts/{id}`

## Voice

* `POST /voice/parse`

## Reports

* `GET /reports/personal`
* `GET /groups/{group_id}/reports`

## Rules

* Semua *endpoint* privat membutuhkan autentikasi.
* Backend memvalidasi *role* dan *membership*.
* Jangan menerima identitas pembuat transaksi dari *frontend*.
* Gunakan *pagination* untuk daftar transaksi.
* Gunakan *response* dan *error format* yang konsisten.