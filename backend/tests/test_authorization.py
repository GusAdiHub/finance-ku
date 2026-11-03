"""Comprehensive Authorization and Security Tests per docs/TESTING.md and docs/SECURITY.md.

Mandatory Scenarios:
1. User A tidak dapat melihat transaksi personal User B.
2. User luar grup tidak dapat melihat transaksi grup.
3. Member tidak dapat mengedit transaksi anggota lain (hanya creator atau admin/owner grup).
4. Member yang sudah keluar tidak dapat mengakses grup.
5. User tidak dapat memanipulasi group_id untuk mengakses grup lain.
6. User tidak dapat mengubah created_by_user_id melalui request payload.
7. Kode undangan expired harus ditolak.
"""
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient


def _get_auth_token(client: TestClient, email: str, name: str = "Test User") -> str:
    """Helper to register and return an access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": name, "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def _get_category_id(client: TestClient, token: str, cat_type: str = "expense") -> str:
    """Helper to get category ID."""
    res = client.get(
        f"/api/v1/categories?type={cat_type}",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_scenario_1_user_a_cannot_view_user_b_personal_transactions(client: TestClient):
    """Scenario 1: User A tidak dapat melihat transaksi personal User B."""
    token_a = _get_auth_token(client, "auth_user_a@example.com", "User A")
    token_b = _get_auth_token(client, "auth_user_b@example.com", "User B")
    cat_id_b = _get_category_id(client, token_b, "expense")

    # User B creates a personal transaction
    res_b = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token_b}"},
        json={
            "type": "expense",
            "amount": 150000.00,
            "category_id": cat_id_b,
            "description": "User B Secret Expense",
        },
    )
    tx_id_b = res_b.json()["id"]

    # User A tries to view User B's transaction by ID
    get_res = client.get(
        f"/api/v1/transactions/{tx_id_b}",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert get_res.status_code == 403
    assert "tidak memiliki akses" in get_res.json()["detail"].lower()

    # User A lists their own transactions; User B's transaction must not appear
    list_res = client.get(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert list_res.status_code == 200
    ids = [t["id"] for t in list_res.json()["items"]]
    assert tx_id_b not in ids


def test_scenario_2_non_member_cannot_view_group_transactions(client: TestClient):
    """Scenario 2: User luar grup tidak dapat melihat transaksi grup."""
    token_owner = _get_auth_token(client, "group_owner_sc2@example.com", "Group Owner")
    token_outsider = _get_auth_token(client, "outsider_sc2@example.com", "Outsider")
    cat_id = _get_category_id(client, token_owner, "expense")

    # Owner creates a family group
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Keluarga Cemara Sc2"},
    )
    group_id = group_res.json()["id"]

    # Owner creates a shared transaction in the group
    client.post(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={
            "type": "expense",
            "amount": 250000.00,
            "category_id": cat_id,
            "description": "Belanja Bulanan Keluarga",
        },
    )

    # Outsider tries to view group transactions
    list_res = client.get(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_outsider}"},
    )
    assert list_res.status_code == 403
    assert "bukan anggota" in list_res.json()["detail"].lower()


def test_scenario_3_regular_member_cannot_modify_other_members_transaction(client: TestClient):
    """Scenario 3: Member biasa tidak dapat mengedit/menghapus transaksi milik anggota lain."""
    token_creator = _get_auth_token(client, "creator_sc3@example.com", "Creator Member")
    token_other = _get_auth_token(client, "other_sc3@example.com", "Other Member")
    token_owner = _get_auth_token(client, "owner_sc3@example.com", "Group Owner Sc3")
    cat_id = _get_category_id(client, token_creator, "expense")

    # Owner creates group & generates invite
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Keluarga Sc3"},
    )
    group_id = group_res.json()["id"]
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 2, "max_uses": 5},
    )
    code = inv_res.json()["invitation_code"]

    # Both members join group
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_creator}"}, json={"code": code})
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_other}"}, json={"code": code})

    # Creator posts a transaction
    tx_res = client.post(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_creator}"},
        json={
            "type": "expense",
            "amount": 90000.00,
            "category_id": cat_id,
            "description": "Pembelian Galon Air",
        },
    )
    tx_id = tx_res.json()["id"]

    # Other member attempts to delete Creator's transaction
    del_res = client.delete(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_other}"},
    )
    assert del_res.status_code == 403
    assert "hanya pembuat transaksi" in del_res.json()["detail"].lower() or "akses" in del_res.json()["detail"].lower()


def test_scenario_4_departed_member_cannot_access_group(client: TestClient):
    """Scenario 4: Member yang sudah keluar tidak dapat mengakses grup."""
    token_owner = _get_auth_token(client, "owner_sc4@example.com", "Owner Sc4")
    token_leaver = _get_auth_token(client, "leaver_sc4@example.com", "Leaver Sc4")

    # Create group & invite
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Keluarga Sc4"},
    )
    group_id = group_res.json()["id"]
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 1, "max_uses": 2},
    )
    code = inv_res.json()["invitation_code"]

    # Join then leave
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_leaver}"}, json={"code": code})
    leave_res = client.post(f"/api/v1/groups/{group_id}/leave", headers={"Authorization": f"Bearer {token_leaver}"})
    assert leave_res.status_code == 200

    # Try to access group dashboard after leaving
    dash_res = client.get(
        f"/api/v1/groups/{group_id}/dashboard",
        headers={"Authorization": f"Bearer {token_leaver}"},
    )
    assert dash_res.status_code == 403
    assert "bukan anggota aktif" in dash_res.json()["detail"].lower()


def test_scenario_5_cannot_manipulate_group_id_to_access_other_group(client: TestClient):
    """Scenario 5: User tidak dapat memanipulasi group_id untuk mengakses grup lain."""
    token_user_x = _get_auth_token(client, "user_x_sc5@example.com", "User X")
    token_user_y = _get_auth_token(client, "user_y_sc5@example.com", "User Y")
    cat_id_y = _get_category_id(client, token_user_y, "expense")

    # User X creates Group X
    group_x = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_user_x}"},
        json={"name": "Grup Rahasia X"},
    ).json()

    # User Y tries to create a transaction directly into Group X
    tx_res = client.post(
        f"/api/v1/groups/{group_x['id']}/transactions",
        headers={"Authorization": f"Bearer {token_user_y}"},
        json={
            "type": "expense",
            "amount": 50000.00,
            "category_id": cat_id_y,
            "description": "Illegal Injection",
        },
    )
    assert tx_res.status_code == 403
    assert "bukan anggota" in tx_res.json()["detail"].lower()


def test_scenario_6_cannot_spoof_created_by_user_id(client: TestClient):
    """Scenario 6: User tidak dapat mengubah created_by_user_id melalui request payload."""
    token_real = _get_auth_token(client, "real_user_sc6@example.com", "Real User")
    cat_id = _get_category_id(client, token_real, "expense")
    fake_victim_uuid = "99999999-9999-9999-9999-999999999999"

    # Send payload attempting to set created_by_user_id to another user
    res = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token_real}"},
        json={
            "type": "expense",
            "amount": 35000.00,
            "category_id": cat_id,
            "description": "Trying to spoof creator",
            "created_by_user_id": fake_victim_uuid,
            "owner_user_id": fake_victim_uuid,
        },
    )
    assert res.status_code == 201
    tx_data = res.json()
    # Backend must assign the authenticated user's ID, completely ignoring spoofed body fields
    my_profile = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token_real}"}).json()
    assert tx_data["created_by_user_id"] == my_profile["id"]
    assert tx_data["owner_user_id"] == my_profile["id"]
    assert tx_data["created_by_user_id"] != fake_victim_uuid


def test_scenario_7_expired_invitation_code_must_be_rejected(client: TestClient):
    """Scenario 7: Kode undangan expired harus ditolak."""
    token_owner = _get_auth_token(client, "owner_sc7@example.com", "Owner Sc7")
    token_joiner = _get_auth_token(client, "joiner_sc7@example.com", "Joiner Sc7")

    # Create group
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Keluarga Sc7"},
    )
    group_id = group_res.json()["id"]

    # Create an invitation that expired in the past (-1 day)
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": -1, "max_uses": 5},
    )
    expired_code = inv_res.json()["invitation_code"]

    # Joiner attempts to use the expired code
    join_res = client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_joiner}"},
        json={"code": expired_code},
    )
    assert join_res.status_code == 400
    assert "kadaluarsa" in join_res.json()["detail"].lower() or "expired" in join_res.json()["detail"].lower()
