"""Security module: password hashing, verification, and JWT management."""
import base64
import hashlib
import hmac
import json
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

try:
    import bcrypt
except ImportError:
    bcrypt = None

try:
    import jwt as pyjwt
except ImportError:
    pyjwt = None

from app.core.config import settings


# ---------------------------------------------------------------------------
# Password Hashing & Verification
# ---------------------------------------------------------------------------

def get_password_hash(password: str) -> str:
    """Hash a plaintext password using bcrypt (or standard PBKDF2 fallback)."""
    if bcrypt is not None:
        # bcrypt handles up to 72 bytes; encode to utf-8
        pwd_bytes = password.encode("utf-8")
        salt = bcrypt.gensalt(rounds=12)
        hashed = bcrypt.hashpw(pwd_bytes, salt)
        return hashed.decode("utf-8")

    # Fallback to standard PBKDF2-HMAC-SHA256 if bcrypt is not yet installed
    salt = base64.b64encode(hashlib.sha256(str(time.time()).encode()).digest()[:16]).decode()
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode(), 100_000)
    return f"pbkdf2:sha256:100000${salt}${base64.b64encode(key).decode()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a stored hash."""
    if not plain_password or not hashed_password:
        return False

    # Check for bcrypt format ($2b$, $2a$, $2y$)
    if hashed_password.startswith(("$2a$", "$2b$", "$2y$")):
        if bcrypt is not None:
            try:
                return bcrypt.checkpw(
                    plain_password.encode("utf-8"),
                    hashed_password.encode("utf-8"),
                )
            except Exception:
                return False
        return False

    # Check for PBKDF2 fallback format
    if hashed_password.startswith("pbkdf2:sha256:"):
        try:
            _, _, iterations, salt, expected_hash = hashed_password.split("$")
            key = hashlib.pbkdf2_hmac(
                "sha256",
                plain_password.encode("utf-8"),
                salt.encode(),
                int(iterations.replace("pbkdf2:sha256:", "")),
            )
            return hmac.compare_digest(base64.b64encode(key).decode(), expected_hash)
        except Exception:
            return False

    return False


# ---------------------------------------------------------------------------
# JWT Token Generation & Verification (RFC 7519)
# ---------------------------------------------------------------------------

def _b64url_encode(data: bytes) -> str:
    """Encode bytes to URL-safe base64 without padding."""
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")


def _b64url_decode(data: str) -> bytes:
    """Decode URL-safe base64 string with missing padding restored."""
    padded = data + "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(padded)


def _pure_jwt_encode(payload: dict[str, Any], secret_key: str) -> str:
    """Pure Python RFC 7519 HS256 JWT encoder."""
    header = {"alg": "HS256", "typ": "JWT"}
    header_bytes = json.dumps(header, separators=(",", ":")).encode("utf-8")
    payload_bytes = json.dumps(payload, separators=(",", ":")).encode("utf-8")

    segments = [
        _b64url_encode(header_bytes),
        _b64url_encode(payload_bytes),
    ]
    signing_input = ".".join(segments).encode("ascii")
    signature = hmac.new(secret_key.encode("utf-8"), signing_input, hashlib.sha256).digest()
    segments.append(_b64url_encode(signature))
    return ".".join(segments)


def _pure_jwt_decode(token: str, secret_key: str) -> Optional[dict[str, Any]]:
    """Pure Python RFC 7519 HS256 JWT decoder with expiry check."""
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None

        header_b64, payload_b64, signature_b64 = parts
        signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
        expected_sig = hmac.new(secret_key.encode("utf-8"), signing_input, hashlib.sha256).digest()
        actual_sig = _b64url_decode(signature_b64)

        if not hmac.compare_digest(expected_sig, actual_sig):
            return None

        payload = json.loads(_b64url_decode(payload_b64).decode("utf-8"))

        # Check expiration
        exp = payload.get("exp")
        if exp is not None:
            now = datetime.now(timezone.utc).timestamp()
            if now > exp:
                return None

        return payload
    except Exception:
        return None


def create_access_token(
    subject: str,
    email: str,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Create a signed JWT access token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": str(subject),
        "email": email,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }

    if pyjwt is not None:
        return pyjwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return _pure_jwt_encode(payload, settings.SECRET_KEY)


def decode_access_token(token: str) -> Optional[dict[str, Any]]:
    """Decode and validate a JWT access token. Returns payload dict or None if invalid/expired."""
    if not token:
        return None

    if pyjwt is not None:
        try:
            return pyjwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.JWT_ALGORITHM],
            )
        except Exception:
            return None
    return _pure_jwt_decode(token, settings.SECRET_KEY)
