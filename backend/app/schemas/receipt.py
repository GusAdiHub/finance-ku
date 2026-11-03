"""Receipt and TransactionItem Pydantic schemas."""
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, computed_field, field_serializer


class TransactionItemBase(BaseModel):
    """Base schema for receipt line items."""
    item_name: str = Field(..., min_length=1, max_length=255, description="Item or product name")
    quantity: Decimal = Field(default=Decimal("1.00"), gt=0, description="Quantity of items")
    price_per_unit: Decimal = Field(default=Decimal("0.00"), ge=0, description="Price per unit in IDR")
    total_price: Decimal = Field(default=Decimal("0.00"), ge=0, description="Total price (quantity * unit price)")


class TransactionItemCreate(BaseModel):
    """Schema for creating a line item manually or from OCR."""
    item_name: str = Field(..., min_length=1, max_length=255)
    quantity: Decimal = Field(default=Decimal("1.00"), gt=0)
    price_per_unit: Decimal = Field(default=Decimal("0.00"), ge=0)
    total_price: Optional[Decimal] = Field(default=None, ge=0)


class TransactionItemResponse(TransactionItemBase):
    """Schema for returning transaction line items."""
    id: str
    receipt_id: Optional[str] = None
    transaction_id: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("price_per_unit", "total_price", mode="plain", check_fields=False)
    def serialize_prices(self, v: Optional[Decimal]) -> Optional[int | float]:
        if v is None:
            return None
        return int(round(v)) if v % 1 == 0 else float(v)


class ReceiptBase(BaseModel):
    """Base receipt metadata schema."""
    merchant_name: Optional[str] = None
    receipt_date: Optional[datetime] = None
    total_amount: Optional[Decimal] = None


class ReceiptResponse(BaseModel):
    """Schema for receipt upload and OCR extraction results."""
    id: str
    user_id: str
    group_id: Optional[str] = None
    file_name: str
    file_size: int
    mime_type: str
    merchant_name: Optional[str] = None
    receipt_date: Optional[datetime] = None
    total_amount: Optional[Decimal] = None
    raw_ocr_data: Optional[Dict[str, Any]] = None
    status: str
    items: List[TransactionItemResponse] = []
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("total_amount", mode="plain", check_fields=False)
    def serialize_total_amount(self, v: Optional[Decimal]) -> Optional[int | float]:
        if v is None:
            return None
        return int(round(v)) if v % 1 == 0 else float(v)

    @computed_field
    def ocr_status(self) -> Optional[str]:
        """Convenience accessor for OCR status: 'success', 'partial', 'unavailable', or 'empty'."""
        if isinstance(self.raw_ocr_data, dict):
            return self.raw_ocr_data.get("ocr_status")
        return None

    @computed_field
    def ocr_message(self) -> Optional[str]:
        """User-friendly message explaining the OCR result or recommendations."""
        if isinstance(self.raw_ocr_data, dict):
            return self.raw_ocr_data.get("ocr_message")
        return None


class ReceiptConfirmRequest(BaseModel):
    """Schema for reviewing and confirming receipt into a final transaction."""
    category_id: str = Field(..., description="Selected expense category UUID")
    merchant_name: Optional[str] = Field(None, max_length=255, description="Store or merchant name")
    transaction_date: Optional[datetime] = Field(None, description="Date of the receipt transaction")
    total_amount: Decimal = Field(..., gt=0, description="Confirmed total transaction amount")
    description: Optional[str] = Field(None, max_length=255, description="Description or note")
    notes: Optional[str] = Field(None, description="Detailed notes or reimbursement status")
    target_scope: str = Field("personal", description="Target ledger: 'personal' or 'family'")
    group_id: Optional[str] = Field(None, description="Family group ID if scope is family")
    items: Optional[List[TransactionItemCreate]] = Field(None, description="Updated line items breakdown")
