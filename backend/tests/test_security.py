"""Unit tests for security utilities: password hashing and JWT tokens."""
from datetime import timedelta
import time
from app.core.security import (
    create_access_token,
    decode_access_token,
    get_password_hash,
    verify_password,
)


def test_password_hashing_and_verification():
    """Test that passwords hash securely and verify correctly."""
    password = "MySecurePassword123!"
    hashed = get_password_hash(password)

    assert hashed != password
    assert len(hashed) > 20
    assert verify_password(password, hashed) is True
    assert verify_password("WrongPassword!", hashed) is False
    assert verify_password("", hashed) is False
    assert verify_password(password, "") is False


def test_jwt_token_creation_and_decoding():
    """Test generating and decoding valid JWT access tokens."""
    user_id = "11111111-2222-3333-4444-555555555555"
    email = "test@example.com"

    token = create_access_token(subject=user_id, email=email)
    assert isinstance(token, str)
    assert len(token.split(".")) == 3

    payload = decode_access_token(token)
    assert payload is not None
    assert payload.get("sub") == user_id
    assert payload.get("email") == email
    assert payload.get("type") == "access"
    assert "exp" in payload
    assert "iat" in payload


def test_jwt_token_expiration():
    """Test that expired JWT tokens are rejected."""
    user_id = "test-user-id"
    email = "expired@example.com"

    # Token with negative expiry (already expired in the past)
    expired_token = create_access_token(
        subject=user_id,
        email=email,
        expires_delta=timedelta(seconds=-10),
    )

    payload = decode_access_token(expired_token)
    assert payload is None


def test_jwt_tampered_token():
    """Test that tampered tokens fail validation."""
    token = create_access_token(subject="user-123", email="user@example.com")
    parts = token.split(".")
    # Tamper with signature
    tampered_token = f"{parts[0]}.{parts[1]}.tampered_signature"

    payload = decode_access_token(tampered_token)
    assert payload is None
