"""Schemas for voice input and parsing."""
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field


class VoiceParseRequest(BaseModel):
    """Request payload for parsing spoken Indonesian financial text."""
    text: str = Field(..., min_length=1, max_length=500, description="Raw transcript of the spoken input.")


class VoiceParseResponse(BaseModel):
    """Parsed result containing financial transaction draft parameters."""
    raw_text: str
    type: str = Field(default="expense", description="'expense' or 'income'")
    amount: Optional[Decimal] = None
    description: Optional[str] = None
    suggested_category_name: Optional[str] = None
    suggested_category_id: Optional[str] = None
    confidence_score: float = Field(default=0.0, ge=0.0, le=1.0)
