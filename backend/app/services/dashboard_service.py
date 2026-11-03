"""Dashboard service layer for personal financial statistics."""
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.dashboard import (
    CategoryBreakdownItem,
    PersonalDashboardResponse,
)
from app.schemas.transaction import TransactionResponse


class DashboardService:
    """Business logic for generating personal financial dashboard views."""

    @classmethod
    def get_personal_dashboard(
        cls,
        db: Session,
        user: User,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> PersonalDashboardResponse:
        """Calculate and return personal financial metrics for dashboard."""
        # 1. Total income, total expense, and net balance
        summary = TransactionRepository.get_personal_summary(
            db=db,
            user_id=user.id,
            start_date=start_date,
            end_date=end_date,
        )
        total_income = summary["total_income"]
        total_expense = summary["total_expense"]
        net_balance = summary["net_balance"]

        # 2. Expense category breakdown
        expense_rows = TransactionRepository.get_personal_category_breakdown(
            db=db,
            user_id=user.id,
            transaction_type="expense",
            start_date=start_date,
            end_date=end_date,
        )
        expense_breakdown: List[CategoryBreakdownItem] = []
        for r in expense_rows:
            pct = float((r["total_amount"] / total_expense * 100)) if total_expense > 0 else 0.0
            expense_breakdown.append(
                CategoryBreakdownItem(
                    category_id=r["category_id"],
                    category_name=r["category_name"],
                    category_icon=r["category_icon"],
                    category_color=r["category_color"],
                    total_amount=r["total_amount"],
                    percentage=round(pct, 2),
                    transaction_count=r["transaction_count"],
                )
            )

        # 3. Income category breakdown
        income_rows = TransactionRepository.get_personal_category_breakdown(
            db=db,
            user_id=user.id,
            transaction_type="income",
            start_date=start_date,
            end_date=end_date,
        )
        income_breakdown: List[CategoryBreakdownItem] = []
        for r in income_rows:
            pct = float((r["total_amount"] / total_income * 100)) if total_income > 0 else 0.0
            income_breakdown.append(
                CategoryBreakdownItem(
                    category_id=r["category_id"],
                    category_name=r["category_name"],
                    category_icon=r["category_icon"],
                    category_color=r["category_color"],
                    total_amount=r["total_amount"],
                    percentage=round(pct, 2),
                    transaction_count=r["transaction_count"],
                )
            )

        # 4. Recent transactions
        recent_txs = TransactionRepository.get_personal_recent_transactions(
            db=db,
            user_id=user.id,
            limit=5,
        )

        return PersonalDashboardResponse(
            total_income=total_income,
            total_expense=total_expense,
            net_balance=net_balance,
            recent_transactions=[TransactionResponse.model_validate(tx) for tx in recent_txs],
            expense_by_category=expense_breakdown,
            income_by_category=income_breakdown,
            start_date=start_date,
            end_date=end_date,
        )
