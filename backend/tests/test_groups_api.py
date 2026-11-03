"""Integration tests for Family Finance (groups, members, invitations, shared ledger, and reports)."""
from datetime import datetime, timezone
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient


def _get_auth_token(client: TestClient, email: str, name: str = "User") -> str:
    """Helper to register a user and return access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": name, "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def _get_first_category_id(client: TestClient, token: str, cat_type: str = "expense") -> str:
    """Helper to get a category ID."""
    res = client.get(
        f"/api/v1/categories?type={cat_type}",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_create_and_get_group(client: TestClient):
    """Test creating a family group and verifying creator is owner."""
    token = _get_auth_token(client, "owner1@example.com", "Group Owner")

    create_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Keluarga Cemara", "description": "Shared family ledger"},
    )
    assert create_res.status_code == 201
    group_data = create_res.json()
    assert group_data["name"] == "Keluarga Cemara"
    assert group_data["user_role"] == "owner"
    assert group_data["members_count"] == 1
    group_id = group_data["id"]

    # Verify listing groups
    list_res = client.get(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1
    assert list_res.json()[0]["id"] == group_id

    # Verify detail
    detail_res = client.get(
        f"/api/v1/groups/{group_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert detail_res.status_code == 200
    assert detail_res.json()["name"] == "Keluarga Cemara"


def test_non_member_cannot_access_group(client: TestClient):
    """Test that a non-member gets 404 when attempting to access a group."""
    token_owner = _get_auth_token(client, "owner2@example.com", "Owner")
    token_outsider = _get_auth_token(client, "outsider@example.com", "Outsider")

    res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Private Group"},
    )
    group_id = res.json()["id"]

    # Outsider tries to access
    out_res = client.get(
        f"/api/v1/groups/{group_id}",
        headers={"Authorization": f"Bearer {token_outsider}"},
    )
    assert out_res.status_code == 404


def test_invitation_and_join_flow(client: TestClient):
    """Test generating an invitation code and another user joining with it."""
    token_owner = _get_auth_token(client, "owner3@example.com", "Family Head")
    token_member = _get_auth_token(client, "member3@example.com", "Family Member")

    # 1. Create group
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Keluarga Bahagia"},
    )
    group_id = group_res.json()["id"]

    # 2. Owner creates invitation
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 7, "max_uses": 2},
    )
    assert inv_res.status_code == 201
    inv_data = inv_res.json()
    raw_code = inv_data["code"]
    assert raw_code is not None

    # 3. New user joins using code
    join_res = client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"code": raw_code},
    )
    assert join_res.status_code == 200
    joined_data = join_res.json()
    assert joined_data["id"] == group_id
    assert joined_data["user_role"] == "member"
    assert joined_data["members_count"] == 2

    # 4. Joining again with same user should fail
    rejoin_res = client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"code": raw_code},
    )
    assert rejoin_res.status_code == 400
    assert "already an active member" in rejoin_res.json()["detail"].lower()


def test_revoked_invitation_rejected(client: TestClient):
    """Test that a revoked invitation code cannot be used to join."""
    token_owner = _get_auth_token(client, "owner4@example.com", "Owner")
    token_user = _get_auth_token(client, "user4@example.com", "User")

    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Revoke Test Group"},
    )
    group_id = group_res.json()["id"]

    # Create invitation
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 1, "max_uses": 1},
    )
    inv_id = inv_res.json()["id"]
    code = inv_res.json()["code"]

    # Revoke invitation
    del_res = client.delete(
        f"/api/v1/groups/{group_id}/invitations/{inv_id}",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert del_res.status_code == 200

    # Attempt to join with revoked code
    join_res = client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_user}"},
        json={"code": code},
    )
    assert join_res.status_code == 400
    assert "invalid" in join_res.json()["detail"].lower()


def test_member_role_management_and_removal(client: TestClient):
    """Test promoting member to admin, and removing a member."""
    token_owner = _get_auth_token(client, "owner5@example.com", "Owner")
    token_member = _get_auth_token(client, "member5@example.com", "Member")

    # Create group
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Role Test Group"},
    )
    group_id = group_res.json()["id"]

    # Member joins
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 7, "max_uses": 1},
    )
    code = inv_res.json()["code"]
    client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"code": code},
    )

    # List members
    members_res = client.get(
        f"/api/v1/groups/{group_id}/members",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert members_res.status_code == 200
    members = members_res.json()
    assert len(members) == 2
    regular_member = next(m for m in members if m["role"] == "member")

    # Owner promotes member to admin
    role_res = client.patch(
        f"/api/v1/groups/{group_id}/members/{regular_member['id']}",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"role": "admin"},
    )
    assert role_res.status_code == 200
    assert role_res.json()["role"] == "admin"

    # Regular member/admin cannot promote anyone
    fail_role = client.patch(
        f"/api/v1/groups/{group_id}/members/{regular_member['id']}",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"role": "member"},
    )
    assert fail_role.status_code == 403

    # Remove member
    del_res = client.delete(
        f"/api/v1/groups/{group_id}/members/{regular_member['id']}",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert del_res.status_code == 200

    # Member should now be denied access to the group
    denied_res = client.get(
        f"/api/v1/groups/{group_id}",
        headers={"Authorization": f"Bearer {token_member}"},
    )
    assert denied_res.status_code == 404


def test_leave_group_rules(client: TestClient):
    """Test leave group functionality and ownership restrictions."""
    token_owner = _get_auth_token(client, "owner6@example.com", "Owner")
    token_member = _get_auth_token(client, "member6@example.com", "Member")

    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Leave Test Group"},
    )
    group_id = group_res.json()["id"]

    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 7, "max_uses": 1},
    )
    client.post(
        "/api/v1/groups/join",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"code": inv_res.json()["code"]},
    )

    # Owner cannot leave while another member exists
    owner_leave = client.post(
        f"/api/v1/groups/{group_id}/leave",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert owner_leave.status_code == 400

    # Member leaves successfully
    member_leave = client.post(
        f"/api/v1/groups/{group_id}/leave",
        headers={"Authorization": f"Bearer {token_member}"},
    )
    assert member_leave.status_code == 200

    # Now owner is sole member, owner can leave
    owner_leave_solo = client.post(
        f"/api/v1/groups/{group_id}/leave",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert owner_leave_solo.status_code == 200


def test_shared_group_transactions_and_permissions(client: TestClient):
    """Test group transaction CRUD and role-based permissions (member cannot edit another member's entry)."""
    token_owner = _get_auth_token(client, "owner7@example.com", "Owner")
    token_member_a = _get_auth_token(client, "memA@example.com", "Member A")
    token_member_b = _get_auth_token(client, "memB@example.com", "Member B")

    # Create group
    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Shared Ledger Group"},
    )
    group_id = group_res.json()["id"]

    # Both members join
    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 7, "max_uses": 5},
    )
    code = inv_res.json()["code"]
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_member_a}"}, json={"code": code})
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_member_b}"}, json={"code": code})

    exp_cat_id = _get_first_category_id(client, token_owner, "expense")

    # Member A records a shared group transaction
    tx_res = client.post(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_member_a}"},
        json={
            "type": "expense",
            "amount": 150000.00,
            "category_id": exp_cat_id,
            "description": "Belanja Dapur Mingguan",
        },
    )
    assert tx_res.status_code == 201
    tx_data = tx_res.json()
    assert tx_data["group_id"] == group_id
    assert tx_data["owner_user_id"] is None
    tx_id = tx_data["id"]

    # Member B can view the transaction
    get_res = client.get(
        f"/api/v1/groups/{group_id}/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_member_b}"},
    )
    assert get_res.status_code == 200
    assert Decimal(str(get_res.json()["amount"])) == Decimal("150000.00")

    # Member B CANNOT update Member A's transaction
    patch_b = client.patch(
        f"/api/v1/groups/{group_id}/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_member_b}"},
        json={"amount": 999999.00},
    )
    assert patch_b.status_code == 403

    # Member B CANNOT delete Member A's transaction
    del_b = client.delete(
        f"/api/v1/groups/{group_id}/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_member_b}"},
    )
    assert del_b.status_code == 403

    # Owner CAN update Member A's transaction
    patch_owner = client.patch(
        f"/api/v1/groups/{group_id}/transactions/{tx_id}",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"amount": 175000.00},
    )
    assert patch_owner.status_code == 200
    assert Decimal(str(patch_owner.json()["amount"])) == Decimal("175000.00")


def test_group_dashboard_and_reports(client: TestClient):
    """Test group dashboard and financial reports with member contributions."""
    token_owner = _get_auth_token(client, "owner8@example.com", "Owner")
    token_member = _get_auth_token(client, "member8@example.com", "Member")

    group_res = client.post(
        "/api/v1/groups",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"name": "Analytics Group"},
    )
    group_id = group_res.json()["id"]

    inv_res = client.post(
        f"/api/v1/groups/{group_id}/invitations",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"expires_in_days": 7, "max_uses": 2},
    )
    client.post("/api/v1/groups/join", headers={"Authorization": f"Bearer {token_member}"}, json={"code": inv_res.json()["code"]})

    inc_cat_id = _get_first_category_id(client, token_owner, "income")
    exp_cat_id = _get_first_category_id(client, token_owner, "expense")

    # Owner adds group income: 8,000,000
    client.post(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"type": "income", "amount": 8000000.00, "category_id": inc_cat_id, "description": "Gaji Masuk Rekening Bersama"},
    )

    # Member adds group expense: 1,200,000
    client.post(
        f"/api/v1/groups/{group_id}/transactions",
        headers={"Authorization": f"Bearer {token_member}"},
        json={"type": "expense", "amount": 1200000.00, "category_id": exp_cat_id, "description": "Belanja Bulanan Supermarket"},
    )

    # 1. Dashboard
    dash_res = client.get(
        f"/api/v1/groups/{group_id}/dashboard",
        headers={"Authorization": f"Bearer {token_member}"},
    )
    assert dash_res.status_code == 200
    dash_data = dash_res.json()
    assert Decimal(str(dash_data["total_income"])) == Decimal("8000000.00")
    assert Decimal(str(dash_data["total_expense"])) == Decimal("1200000.00")
    assert Decimal(str(dash_data["net_balance"])) == Decimal("6800000.00")
    assert len(dash_data["member_contributions"]) == 2

    # 2. Reports
    report_res = client.get(
        f"/api/v1/groups/{group_id}/reports?period=monthly",
        headers={"Authorization": f"Bearer {token_owner}"},
    )
    assert report_res.status_code == 200
    report_data = report_res.json()
    assert Decimal(str(report_data["total_income"])) == Decimal("8000000.00")
    assert Decimal(str(report_data["total_expense"])) == Decimal("1200000.00")
    assert Decimal(str(report_data["net_savings"])) == Decimal("6800000.00")
    # Savings rate: (6,800,000 / 8,000,000) * 100 = 85.0%
    assert report_data["savings_rate"] == 85.0
    assert len(report_data["member_contributions"]) == 2
