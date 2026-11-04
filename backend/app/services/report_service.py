"""Report service layer for personal financial statements."""
from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.dashboard import CategoryBreakdownItem
from app.schemas.report import MonthlyTrendItem, PersonalReportResponse


class ReportService:
    """Business logic for personal financial reports and trends."""

    @classmethod
    def get_personal_report(
        cls,
        db: Session,
        user: User,
        start_date: datetime,
        end_date: datetime,
        period_name: str = "custom",
    ) -> PersonalReportResponse:
        """Generate a complete financial report for the user over a time range."""
        clean_start = (
            start_date.astimezone(timezone.utc).replace(tzinfo=None)
            if start_date.tzinfo is not None
            else start_date
        )
        clean_end = (
            end_date.astimezone(timezone.utc).replace(tzinfo=None)
            if end_date.tzinfo is not None
            else end_date
        )

        # 1. Total summary
        summary = TransactionRepository.get_personal_summary(
            db=db,
            user_id=user.id,
            start_date=clean_start,
            end_date=clean_end,
        )
        total_income = summary["total_income"]
        total_expense = summary["total_expense"]
        net_savings = total_income - total_expense
        savings_rate = float((net_savings / total_income * 100)) if total_income > 0 else 0.0

        # 2. Category breakdowns
        expense_rows = TransactionRepository.get_personal_category_breakdown(
            db=db,
            user_id=user.id,
            transaction_type="expense",
            start_date=clean_start,
            end_date=clean_end,
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

        income_rows = TransactionRepository.get_personal_category_breakdown(
            db=db,
            user_id=user.id,
            transaction_type="income",
            start_date=clean_start,
            end_date=clean_end,
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

        # 3. Monthly trends (grouped by YYYY-MM)
        stmt = (
            select(Transaction.type, Transaction.amount, Transaction.transaction_date)
            .where(
                Transaction.owner_user_id == user.id,
                Transaction.transaction_date >= clean_start,
                Transaction.transaction_date <= clean_end,
            )
            .order_by(Transaction.transaction_date.asc())
        )
        tx_rows = db.execute(stmt).all()

        monthly_data: dict[str, dict[str, Decimal]] = defaultdict(
            lambda: {"income": Decimal("0.00"), "expense": Decimal("0.00")}
        )
        for tx_type, amount, tx_date in tx_rows:
            month_key = tx_date.strftime("%Y-%m")
            if tx_type == "income":
                monthly_data[month_key]["income"] += amount
            elif tx_type == "expense":
                monthly_data[month_key]["expense"] += amount

        monthly_trends = [
            MonthlyTrendItem(
                month=m,
                income=vals["income"],
                expense=vals["expense"],
                net=vals["income"] - vals["expense"],
            )
            for m, vals in sorted(monthly_data.items())
        ]

        return PersonalReportResponse(
            period=period_name,
            start_date=start_date,
            end_date=end_date,
            total_income=total_income,
            total_expense=total_expense,
            net_savings=net_savings,
            savings_rate=round(savings_rate, 2),
            expense_by_category=expense_breakdown,
            income_by_category=income_breakdown,
            monthly_trends=monthly_trends,
        )
