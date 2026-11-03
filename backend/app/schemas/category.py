"""Category Pydantic schemas."""
from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, ConfigDict, Field


class CategoryBase(BaseModel):
    """Base category schema."""

    name: str = Field(..., min_length=1, max_length=100, description="Category name")
    type: Literal["income", "expense"] = Field(
        ...,
        description="Category classification: 'income' or 'expense'",
    )
    icon: Optional[str] = Field(None, max_length=50, description="Icon identifier")
    color: Optional[str] = Field(None, max_length=20, description="Hex color code (e.g. #10B981)")


class CategoryCreate(CategoryBase):
    """Schema for creating a custom personal category."""
    pass


class CategoryUpdate(BaseModel):
    """Schema for updating a custom category."""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    icon: Optional[str] = Field(None, max_length=50)
    color: Optional[str] = Field(None, max_length=20)


class CategoryResponse(CategoryBase):
    """Schema returned for category data."""

    id: str
    is_system: bool
    user_id: Optional[str] = None
    group_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
