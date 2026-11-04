"""Authentication Pydantic schemas."""
from typing import Any, Optional
from pydantic import BaseModel, EmailStr, Field, model_validator
from app.schemas.user import UserResponse


class UserRegisterRequest(BaseModel):
    """Schema for user registration."""

    name: str = Field(..., min_length=1, max_length=100, description="Full name or username of user")
    email: Optional[EmailStr] = Field(None, max_length=255, description="Unique email address (optional)")
    password: str = Field(
        ...,
        min_length=8,
        max_length=128,
        description="Password with at least 8 characters",
    )

    @model_validator(mode="before")
    @classmethod
    def sanitize_empty_email(cls, data: Any) -> Any:
        """Convert empty email string to None to allow optional email."""
        if isinstance(data, dict):
            if "email" in data and isinstance(data["email"], str) and not data["email"].strip():
                data["email"] = None
        return data


class UserLoginRequest(BaseModel):
    """Schema for user login with username or email."""

    username: Optional[str] = Field(None, max_length=255, description="Username or registered email")
    email: Optional[str] = Field(None, max_length=255, description="Registered email address (legacy)")
    password: str = Field(..., min_length=1, description="Account password")

    @model_validator(mode="after")
    def validate_identifier(self) -> "UserLoginRequest":
        if not self.username and not self.email:
            raise ValueError("Username atau email wajib diisi.")
        return self

    @property
    def identifier(self) -> str:
        return (self.username or self.email or "").strip()


class TokenResponse(BaseModel):
    """OAuth2 / JWT token response schema."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: Optional[UserResponse] = None


class ChangePasswordRequest(BaseModel):
    """Schema for changing current user's password."""

    current_password: str = Field(..., min_length=1, description="Current password")
    new_password: str = Field(
        ...,
        min_length=8,
        max_length=128,
        description="New password (minimum 8 characters)",
    )


class MessageResponse(BaseModel):
    """Generic status/message response."""

    message: str
    success: bool = True
