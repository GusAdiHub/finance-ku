"""Report Pydantic schemas."""
from datetime import datetime
from decimal import Decimal
from typing import List
from pydantic import BaseModel
from app.schemas.dashboard import CategoryBreakdownItem


class MonthlyTrendItem(BaseModel):
    """Monthly summary trend item."""

    month: str
    income: Decimal
    expense: Decimal
    net: Decimal


class PersonalReportResponse(BaseModel):
    """Comprehensive personal financial report."""

    period: str
    start_date: datetime
    end_date: datetime
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    savings_rate: float
    expense_by_category: List[CategoryBreakdownItem]
    income_by_category: List[CategoryBreakdownItem]
    monthly_trends: List[MonthlyTrendItem]
