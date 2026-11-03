"""Authentication Pydantic schemas."""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.schemas.user import UserResponse


class UserRegisterRequest(BaseModel):
    """Schema for user registration."""

    name: str = Field(..., min_length=1, max_length=100, description="Full name of user")
    email: EmailStr = Field(..., max_length=255, description="Unique email address")
    password: str = Field(
        ...,
        min_length=8,
        max_length=128,
        description="Password with at least 8 characters",
    )


class UserLoginRequest(BaseModel):
    """Schema for user login."""

    email: EmailStr = Field(..., description="Registered email address")
    password: str = Field(..., min_length=1, description="Account password")


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
