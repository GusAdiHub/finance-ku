"""Integration tests for personal reports endpoints."""
from datetime import datetime, timezone
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient


def _get_auth_token(client: TestClient, email: str) -> str:
    """Helper to register and return an access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": "Report User", "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def _get_category_id(client: TestClient, token: str, cat_type: str) -> str:
    """Helper to get a category ID of the given type."""
    res = client.get(
        f"/api/v1/categories?type={cat_type}",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_personal_report_metrics(client: TestClient):
    """Test personal report generation including savings rate and monthly trends."""
    token = _get_auth_token(client, "report_user@example.com")
    inc_cat_id = _get_category_id(client, token, "income")
    exp_cat_id = _get_category_id(client, token, "expense")

    now = datetime.now(timezone.utc)
    current_month_str = now.strftime("%Y-%m")

    # Add income: 10,000,000
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "type": "income",
            "amount": 10000000.00,
            "category_id": inc_cat_id,
            "description": "Gaji Utama",
            "transaction_date": now.isoformat(),
        },
    )

    # Add expense: 2,500,000
    client.post(
        "/api/v1/transactions",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "type": "expense",
            "amount": 2500000.00,
            "category_id": exp_cat_id,
            "description": "Biaya Sewa Tempat",
            "transaction_date": now.isoformat(),
        },
    )

    # Request report
    response = client.get(
        "/api/v1/reports/personal?period=monthly",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()

    assert data["period"] == "monthly"
    assert Decimal(str(data["total_income"])) == Decimal("10000000.00")
    assert Decimal(str(data["total_expense"])) == Decimal("2500000.00")
    assert Decimal(str(data["net_savings"])) == Decimal("7500000.00")
    # Savings rate: (7,500,000 / 10,000,000) * 100 = 75.0%
    assert data["savings_rate"] == 75.0

    # Monthly trends
    assert len(data["monthly_trends"]) >= 1
    current_month_trend = next(
        (m for m in data["monthly_trends"] if m["month"] == current_month_str),
        None,
    )
    assert current_month_trend is not None
    assert Decimal(str(current_month_trend["income"])) == Decimal("10000000.00")
    assert Decimal(str(current_month_trend["expense"])) == Decimal("2500000.00")
    assert Decimal(str(current_month_trend["net"])) == Decimal("7500000.00")


def test_personal_report_unauthorized(client: TestClient):
    """Test generating report without token returns 401."""
    response = client.get("/api/v1/reports/personal")
    assert response.status_code == 401
