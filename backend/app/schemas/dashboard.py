"""Dashboard Pydantic schemas."""
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel
from app.schemas.transaction import TransactionResponse


class CategoryBreakdownItem(BaseModel):
    """Aggregated financial figures by category."""

    category_id: str
    category_name: str
    category_icon: Optional[str] = None
    category_color: Optional[str] = None
    total_amount: Decimal
    percentage: float
    transaction_count: int


class PersonalDashboardResponse(BaseModel):
    """Aggregated dashboard statistics for personal finance."""

    total_income: Decimal
    total_expense: Decimal
    net_balance: Decimal
    recent_transactions: List[TransactionResponse]
    expense_by_category: List[CategoryBreakdownItem]
    income_by_category: List[CategoryBreakdownItem]
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
