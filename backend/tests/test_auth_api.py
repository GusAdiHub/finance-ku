"""Integration tests for all authentication API endpoints."""
import pytest
from fastapi.testclient import TestClient


def test_health_endpoints(client: TestClient):
    """Test health check endpoints."""
    res1 = client.get("/health")
    assert res1.status_code == 200
    assert res1.json()["status"] == "healthy"

    res2 = client.get("/api/v1/health")
    assert res2.status_code == 200
    assert res2.json()["status"] == "healthy"


def test_register_success(client: TestClient):
    """Test registering a new user."""
    payload = {
        "name": "Budi Santoso",
        "email": "budi.santoso@example.com",
        "password": "Password123!",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0
    assert "user" in data
    assert data["user"]["name"] == "Budi Santoso"
    assert data["user"]["email"] == "budi.santoso@example.com"
    assert data["user"]["is_active"] is True
    assert "id" in data["user"]


def test_register_duplicate_email(client: TestClient):
    """Test that registering duplicate email returns 400 Bad Request."""
    payload = {
        "name": "User One",
        "email": "duplicate@example.com",
        "password": "Password123!",
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 201

    # Attempt to register again with same email
    res2 = client.post("/api/v1/auth/register", json=payload)
    assert res2.status_code == 400
    assert "already registered" in res2.json()["detail"].lower()


def test_register_validation_error(client: TestClient):
    """Test validation errors for invalid register requests."""
    # Password too short (<8 chars)
    payload_short_pwd = {
        "name": "Short Pwd",
        "email": "short@example.com",
        "password": "123",
    }
    res = client.post("/api/v1/auth/register", json=payload_short_pwd)
    assert res.status_code == 422

    # Invalid email format
    payload_bad_email = {
        "name": "Bad Email",
        "email": "not-an-email",
        "password": "ValidPassword123!",
    }
    res2 = client.post("/api/v1/auth/register", json=payload_bad_email)
    assert res2.status_code == 422


def test_login_success(client: TestClient):
    """Test successful user login with email and with username."""
    # First register user
    reg_payload = {
        "name": "Login User",
        "email": "login.user@example.com",
        "password": "SecretPassword123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # Login using email
    login_payload_email = {
        "email": "login.user@example.com",
        "password": "SecretPassword123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload_email)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "login.user@example.com"

    # Login using username
    login_payload_username = {
        "username": "Login User",
        "password": "SecretPassword123!",
    }
    res_user = client.post("/api/v1/auth/login", json=login_payload_username)
    assert res_user.status_code == 200
    assert "access_token" in res_user.json()


def test_register_and_login_with_username_only(client: TestClient):
    """Test registering with username only (no email) and logging in with username."""
    reg_payload = {
        "name": "gusadi_user",
        "password": "SecretPassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert reg_data["user"]["name"] == "gusadi_user"
    assert "gusadi_user" in reg_data["user"]["email"]

    # Login with username
    login_payload = {
        "username": "gusadi_user",
        "password": "SecretPassword123!",
    }
    login_res = client.post("/api/v1/auth/login", json=login_payload)
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()


def test_login_incorrect_password(client: TestClient):
    """Test login with incorrect password returns 401."""
    reg_payload = {
        "name": "Test User",
        "email": "test.wrongpwd@example.com",
        "password": "CorrectPassword123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    login_payload = {
        "email": "test.wrongpwd@example.com",
        "password": "WrongPassword123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 401
    assert "incorrect" in response.json()["detail"].lower()


def test_login_nonexistent_email(client: TestClient):
    """Test login with non-existent email returns 401."""
    login_payload = {
        "email": "nonexistent@example.com",
        "password": "SomePassword123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 401


def test_get_me_success(client: TestClient):
    """Test retrieving current user profile with valid Bearer token."""
    reg_payload = {
        "name": "Profile User",
        "email": "profile@example.com",
        "password": "Password123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Profile User"
    assert data["email"] == "profile@example.com"
    assert data["is_active"] is True
    assert "id" in data


def test_get_me_unauthorized(client: TestClient):
    """Test GET /auth/me without token returns 401."""
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401


def test_patch_me_profile(client: TestClient):
    """Test updating user profile name and email."""
    reg_payload = {
        "name": "Old Name",
        "email": "old.email@example.com",
        "password": "Password123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    # Update name and email
    update_payload = {
        "name": "New Name",
        "email": "new.email@example.com",
    }
    response = client.patch(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
        json=update_payload,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "New Name"
    assert data["email"] == "new.email@example.com"


def test_patch_me_duplicate_email(client: TestClient):
    """Test updating email to an existing email returns 400."""
    # Create user A
    client.post(
        "/api/v1/auth/register",
        json={"name": "User A", "email": "usera@example.com", "password": "Password123!"},
    )

    # Create user B
    res_b = client.post(
        "/api/v1/auth/register",
        json={"name": "User B", "email": "userb@example.com", "password": "Password123!"},
    )
    token_b = res_b.json()["access_token"]

    # User B tries to change email to User A's email
    response = client.patch(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token_b}"},
        json={"email": "usera@example.com"},
    )
    assert response.status_code == 400
    assert "already taken" in response.json()["detail"].lower()


def test_change_password_success(client: TestClient):
    """Test changing password and verifying new password works."""
    reg_payload = {
        "name": "Pwd User",
        "email": "pwd.user@example.com",
        "password": "InitialPassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    # Change password
    change_payload = {
        "current_password": "InitialPassword123!",
        "new_password": "UpdatedPassword456!",
    }
    change_res = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json=change_payload,
    )
    assert change_res.status_code == 200
    assert change_res.json()["success"] is True

    # Old password should now fail
    old_login = client.post(
        "/api/v1/auth/login",
        json={"email": "pwd.user@example.com", "password": "InitialPassword123!"},
    )
    assert old_login.status_code == 401

    # New password should succeed
    new_login = client.post(
        "/api/v1/auth/login",
        json={"email": "pwd.user@example.com", "password": "UpdatedPassword456!"},
    )
    assert new_login.status_code == 200


def test_change_password_wrong_current(client: TestClient):
    """Test changing password with incorrect current password returns 400."""
    reg_payload = {
        "name": "Pwd User 2",
        "email": "pwd.user2@example.com",
        "password": "CorrectPassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    change_payload = {
        "current_password": "WrongCurrentPassword!",
        "new_password": "NewPassword123!",
    }
    change_res = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json=change_payload,
    )
    assert change_res.status_code == 400
    assert "incorrect" in change_res.json()["detail"].lower()


def test_change_password_same_new_password(client: TestClient):
    """Test changing password to same password returns 400."""
    reg_payload = {
        "name": "Pwd User 3",
        "email": "pwd.user3@example.com",
        "password": "SamePassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    change_payload = {
        "current_password": "SamePassword123!",
        "new_password": "SamePassword123!",
    }
    change_res = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json=change_payload,
    )
    assert change_res.status_code == 400
    assert "different" in change_res.json()["detail"].lower()


def test_logout_revokes_token(client: TestClient):
    """Test logging out revokes the bearer token."""
    reg_payload = {
        "name": "Logout User",
        "email": "logout@example.com",
        "password": "Password123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    # Verify access to /me works before logout
    res_before = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_before.status_code == 200

    # Call /logout
    res_logout = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_logout.status_code == 200
    assert res_logout.json()["success"] is True

    # Subsequent request using the revoked token must return 401
    res_after = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_after.status_code == 401
    assert "revoked" in res_after.json()["detail"].lower()
