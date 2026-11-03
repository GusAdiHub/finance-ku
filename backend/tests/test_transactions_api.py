"""Integration tests for personal transaction endpoints and IDOR protection."""
from datetime import datetime, timezone
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


def _get_first_category_id(client: TestClient, token: str, cat_type: str = "expense") -> str:
    """Helper to get a valid category ID."""
    res = client.get(
        f"/api/v1/categories?type={cat_type}",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_create_personal_transaction(client: TestClient):
    """Test creating a valid personal expense transaction."""
    token = _get_auth_token(client, "tx1@example.com")
    cat_id = _get_first_category_id(client, token, "expense")

    payload = {
        "type": "expense",
        "amount": 75000.00,
        "category_id": cat_id,
        "description": "Makan Siang Nasi Padang",
        "notes": "Pakai rendang dan es teh manis",
    }
    response = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["type"] == "expense"
    assert Decimal(str(data["amount"])) == Decimal("75000.00")
    assert data["description"] == "Makan Siang Nasi Padang"
    assert data["owner_user_id"] is not None
    assert data["group_id"] is None
    assert data["input_method"] == "manual"
    assert data["category"]["id"] == cat_id


def test_create_transaction_incompatible_category(client: TestClient):
    """Test that creating an expense transaction with an income category is rejected."""
    token = _get_auth_token(client, "tx2@example.com")
    # Get income category
    income_cat_id = _get_first_category_id(client, token, "income")

    # Try creating expense with income category
    payload = {
        "type": "expense",
        "amount": 50000.00,
        "category_id": income_cat_id,
        "description": "Invalid Category Type",
    }
    response = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert response.status_code == 400
    assert "incompatible" in response.json()["detail"].lower() or "type" in response.json()["detail"].lower()


def test_idor_protection_between_users(client: TestClient):
    """Test IDOR protection: User B cannot access, modify, or delete User A's transaction."""
    token_a = _get_auth_token(client, "user_a@example.com", "User A")
    token_b = _get_auth_token(client, "user_b@example.com", "User B")

    cat_id_a = _get_first_category_id(client, token_a, "expense")

    # User A creates a transaction
    res_a = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token_a}"},
        json={
            "type": "expense",
            "amount": 100000.00,
            "category_id": cat_id_a,
            "description": "User A Private Expense",
        },
    )
    tx_id = res_a.json()["id"]

    # 1. User B attempts to read User A's transaction
    get_res = client.get(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert get_res.status_code == 404

    # 2. User B attempts to modify User A's transaction
    patch_res = client.patch(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_b}"},
        json={"amount": 999999.00},
    )
    assert patch_res.status_code == 404

    # 3. User B attempts to delete User A's transaction
    del_res = client.delete(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert del_res.status_code == 404

    # Confirm User A can still access their transaction intact
    verify_res = client.get(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert verify_res.status_code == 200
    assert Decimal(str(verify_res.json()["amount"])) == Decimal("100000.00")


def test_list_transactions_pagination_and_filters(client: TestClient):
    """Test transaction pagination and query filters."""
    token = _get_auth_token(client, "tx_filter@example.com")
    expense_cat_id = _get_first_category_id(client, token, "expense")
    income_cat_id = _get_first_category_id(client, token, "income")

    # Create 3 transactions: 2 expenses, 1 income
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "income", "amount": 5000000.00, "category_id": income_cat_id, "description": "Gaji Bulanan"},
    )
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 25000.00, "category_id": expense_cat_id, "description": "Beli Kopi Sore"},
    )
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 50000.00, "category_id": expense_cat_id, "description": "Beli Sarapan"},
    )

    # 1. Total list
    all_res = client.get(
        "/api/v1/transactions?page=1&page_size=10",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert all_res.status_code == 200
    data = all_res.json()
    assert data["total"] == 3
    assert len(data["items"]) == 3
    assert data["page"] == 1
    assert data["page_size"] == 10

    # 2. Filter by type=income
    inc_res = client.get(
        "/api/v1/transactions?type=income",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert inc_res.status_code == 200
    assert inc_res.json()["total"] == 1
    assert inc_res.json()["items"][0]["type"] == "income"

    # 3. Filter by search keyword "kopi"
    search_res = client.get(
        "/api/v1/transactions?search=kopi",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert search_res.status_code == 200
    assert search_res.json()["total"] == 1
    assert "kopi" in search_res.json()["items"][0]["description"].lower()

    # 4. Filter by amount range
    amt_res = client.get(
        "/api/v1/transactions?min_amount=30000&max_amount=60000",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert amt_res.status_code == 200
    assert amt_res.json()["total"] == 1
    assert Decimal(str(amt_res.json()["items"][0]["amount"])) == Decimal("50000.00")


def test_update_and_delete_transaction(client: TestClient):
    """Test updating and deleting a personal transaction."""
    token = _get_auth_token(client, "tx_update@example.com")
    cat_id = _get_first_category_id(client, token, "expense")

    # Create
    create_res = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 10000.00, "category_id": cat_id, "description": "Initial"},
    )
    tx_id = create_res.json()["id"]

    # Update
    update_res = client.patch(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"amount": 15000.00, "description": "Updated"},
    )
    assert update_res.status_code == 200
    assert Decimal(str(update_res.json()["amount"])) == Decimal("15000.00")
    assert update_res.json()["description"] == "Updated"

    # Delete
    del_res = client.delete(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert del_res.status_code == 200
    assert del_res.json()["success"] is True

    # Confirm deletion
    get_res = client.get(
        f"/api/v1/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert get_res.status_code == 404


def test_amount_must_be_positive(client: TestClient):
    """Test validation rejecting amount <= 0."""
    token = _get_auth_token(client, "tx_amount@example.com")
    cat_id = _get_first_category_id(client, token, "expense")

    # Amount 0
    res_zero = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 0, "category_id": cat_id},
    )
    assert res_zero.status_code == 422

    # Amount negative
    res_neg = client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": -5000, "category_id": cat_id},
    )
    assert res_neg.status_code == 422
