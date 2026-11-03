"""Transaction Pydantic schemas."""
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.category import CategoryResponse


class TransactionBase(BaseModel):
    """Base transaction schema."""

    type: Literal["income", "expense"] = Field(
        ...,
        description="Transaction type: 'income' or 'expense'",
    )
    amount: Decimal = Field(
        ...,
        gt=0,
        decimal_places=2,
        description="Monetary amount in IDR (must be greater than 0)",
    )
    category_id: str = Field(..., description="ID of category")
    transaction_date: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Transaction timestamp in UTC",
    )
    description: Optional[str] = Field(
        None,
        max_length=255,
        description="Short summary or payee name",
    )
    notes: Optional[str] = Field(None, description="Detailed notes")


class TransactionCreate(TransactionBase):
    """Schema for creating a personal transaction."""

    input_method: Literal["manual", "ocr", "voice"] = Field(
        default="manual",
        description="Source of transaction entry",
    )
    receipt_id: Optional[str] = Field(None, description="Associated receipt ID if from OCR")


class TransactionUpdate(BaseModel):
    """Schema for updating an existing transaction."""

    type: Optional[Literal["income", "expense"]] = None
    amount: Optional[Decimal] = Field(None, gt=0, decimal_places=2)
    category_id: Optional[str] = None
    transaction_date: Optional[datetime] = None
    description: Optional[str] = Field(None, max_length=255)
    notes: Optional[str] = None


class TransactionResponse(TransactionBase):
    """Schema returned for transaction data."""

    id: str
    owner_user_id: Optional[str] = None
    group_id: Optional[str] = None
    created_by_user_id: str
    input_method: str
    receipt_id: Optional[str] = None
    category: Optional[CategoryResponse] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaginatedTransactionResponse(BaseModel):
    """Paginated list of transactions."""

    items: List[TransactionResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
