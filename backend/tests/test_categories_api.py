"""Integration tests for category endpoints."""
import pytest
from fastapi.testclient import TestClient


def _get_auth_token(client: TestClient, email: str = "cat.user@example.com") -> str:
    """Helper to register and return an auth token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": "Category User", "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def test_list_categories_includes_system(client: TestClient):
    """Test that default system categories are listed for authenticated user."""
    token = _get_auth_token(client, "cat1@example.com")
    response = client.get(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    categories = response.json()
    assert len(categories) > 0
    # Verify presence of seeded categories
    system_names = [c["name"] for c in categories if c["is_system"]]
    assert "Makanan & Minuman" in system_names
    assert "Gaji" in system_names


def test_list_categories_filter_by_type(client: TestClient):
    """Test filtering categories by income or expense."""
    token = _get_auth_token(client, "cat2@example.com")
    # Expense only
    res_expense = client.get(
        "/api/v1/categories?type=expense",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_expense.status_code == 200
    expense_cats = res_expense.json()
    assert all(c["type"] == "expense" for c in expense_cats)

    # Income only
    res_income = client.get(
        "/api/v1/categories?type=income",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_income.status_code == 200
    income_cats = res_income.json()
    assert all(c["type"] == "income" for c in income_cats)


def test_create_custom_category(client: TestClient):
    """Test creating a custom personal category."""
    token = _get_auth_token(client, "cat3@example.com")
    payload = {
        "name": "Koleksi Mainan",
        "type": "expense",
        "icon": "toy-brick",
        "color": "#FF5733",
    }
    response = client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Koleksi Mainan"
    assert data["type"] == "expense"
    assert data["is_system"] is False
    assert data["user_id"] is not None


def test_create_duplicate_category_rejected(client: TestClient):
    """Test creating duplicate category for the same user is rejected."""
    token = _get_auth_token(client, "cat4@example.com")
    payload = {
        "name": "Side Project",
        "type": "income",
        "icon": "laptop",
        "color": "#00AA00",
    }
    res1 = client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert res1.status_code == 201

    res2 = client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert res2.status_code == 400
    assert "already exists" in res2.json()["detail"].lower()


def test_update_custom_category(client: TestClient):
    """Test updating a user's custom category."""
    token = _get_auth_token(client, "cat5@example.com")
    create_res = client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Hobi Lama", "type": "expense"},
    )
    cat_id = create_res.json()["id"]

    update_res = client.patch(
        f"/api/v1/categories/{cat_id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Hobi Baru", "color": "#123456"},
    )
    assert update_res.status_code == 200
    data = update_res.json()
    assert data["name"] == "Hobi Baru"
    assert data["color"] == "#123456"


def test_update_system_category_forbidden(client: TestClient):
    """Test that modifying a system default category is forbidden (403)."""
    token = _get_auth_token(client, "cat6@example.com")
    # Get a system category
    list_res = client.get(
        "/api/v1/categories?type=expense",
        headers={"Authorization": f"Bearer {token}"},
    )
    sys_cat = next(c for c in list_res.json() if c["is_system"])

    res = client.patch(
        f"/api/v1/categories/{sys_cat['id']}",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Hacked Name"},
    )
    assert res.status_code == 403


def test_delete_custom_category(client: TestClient):
    """Test deleting a custom category."""
    token = _get_auth_token(client, "cat7@example.com")
    create_res = client.post(
        "/api/v1/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "To Delete", "type": "expense"},
    )
    cat_id = create_res.json()["id"]

    del_res = client.delete(
        f"/api/v1/categories/{cat_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert del_res.status_code == 200
    assert del_res.json()["success"] is True


def test_delete_system_category_forbidden(client: TestClient):
    """Test that deleting a system default category is forbidden (403)."""
    token = _get_auth_token(client, "cat8@example.com")
    list_res = client.get(
        "/api/v1/categories?type=income",
        headers={"Authorization": f"Bearer {token}"},
    )
    sys_cat = next(c for c in list_res.json() if c["is_system"])

    res = client.delete(
        f"/api/v1/categories/{sys_cat['id']}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res.status_code == 403
