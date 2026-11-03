"""Integration tests for personal dashboard endpoints."""
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient


def _get_auth_token(client: TestClient, email: str) -> str:
    """Helper to register and return an access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": "Dashboard User", "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def _get_category_id(client: TestClient, token: str, cat_type: str) -> str:
    """Helper to get a category ID of the given type."""
    res = client.get(
        f"/api/v1/categories?type={cat_type}",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_personal_dashboard_metrics(client: TestClient):
    """Test dashboard calculations for total income, expense, balance, and breakdown."""
    token = _get_auth_token(client, "dash_user@example.com")
    inc_cat_id = _get_category_id(client, token, "income")
    exp_cat_id = _get_category_id(client, token, "expense")

    # 1. Add income: 5,000,000
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "income", "amount": 5000000.00, "category_id": inc_cat_id, "description": "Gaji Bulanan"},
    )

    # 2. Add expense 1: 300,000
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 300000.00, "category_id": exp_cat_id, "description": "Belanja Bulanan"},
    )

    # 3. Add expense 2: 200,000
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={"type": "expense", "amount": 200000.00, "category_id": exp_cat_id, "description": "Makan Restoran"},
    )

    # Fetch dashboard
    response = client.get(
        "/api/v1/dashboard/personal",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()

    assert Decimal(str(data["total_income"])) == Decimal("5000000.00")
    assert Decimal(str(data["total_expense"])) == Decimal("500000.00")
    assert Decimal(str(data["net_balance"])) == Decimal("4500000.00")

    # Category breakdowns
    assert len(data["expense_by_category"]) > 0
    assert Decimal(str(data["expense_by_category"][0]["total_amount"])) == Decimal("500000.00")
    assert data["expense_by_category"][0]["percentage"] == 100.0
    assert data["expense_by_category"][0]["transaction_count"] == 2

    # Recent transactions
    assert len(data["recent_transactions"]) == 3


def test_dashboard_unauthorized(client: TestClient):
    """Test accessing personal dashboard without token is rejected with 401."""
    response = client.get("/api/v1/dashboard/personal")
    assert response.status_code == 401
