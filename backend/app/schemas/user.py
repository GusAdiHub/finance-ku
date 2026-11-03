"""User Pydantic schemas."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    """Base user schema."""

    name: str = Field(..., min_length=1, max_length=100, description="Full name of user")
    email: EmailStr = Field(..., max_length=255, description="Unique email address")


class UserResponse(UserBase):
    """Schema returned for user details."""

    id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserUpdateRequest(BaseModel):
    """Schema for updating user profile."""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[EmailStr] = Field(None, max_length=255)
