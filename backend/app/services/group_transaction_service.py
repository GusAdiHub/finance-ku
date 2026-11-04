"""Service layer managing shared transactions, dashboard, and reports for family groups."""
from collections import defaultdict
from datetime import datetime
from decimal import Decimal
import math
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.finance_group import FinanceGroup
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.category_repository import CategoryRepository
from app.repositories.group_repository import GroupRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.dashboard import CategoryBreakdownItem
from app.schemas.group import (
    GroupDashboardResponse,
    GroupReportResponse,
    MemberContributionItem,
)
from app.schemas.report import MonthlyTrendItem
from app.schemas.transaction import (
    PaginatedTransactionResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)


class GroupTransactionService:
    """Business logic for Family Finance shared transactions and analytics."""

    @classmethod
    def _ensure_active_membership(
        cls,
        db: Session,
        group_id: str,
        user_id: str,
    ) -> str:
        """Validate membership and return member role, or raise 404/403."""
        membership = GroupRepository.get_member(db, group_id, user_id, active_only=True)
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found or you are not an active member.",
            )
        return membership.role

    @classmethod
    def create_group_transaction(
        cls,
        db: Session,
        user: User,
        group_id: str,
        request: TransactionCreate,
    ) -> Transaction:
        """Create a shared transaction for a family group."""
        cls._ensure_active_membership(db, group_id, user.id)

        # Validate category
        category = CategoryRepository.get_by_id(db, request.category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        # Allow system categories, group categories, or personal categories
        if not category.is_system and category.group_id != group_id and category.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not accessible for this group.",
            )

        if category.type != request.type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category '{category.name}' has type '{category.type}', incompatible with transaction type '{request.type}'.",
            )

        # Shared transaction: owner_user_id is NULL, group_id is populated
        tx = Transaction(
            type=request.type,
            amount=request.amount,
            category_id=category.id,
            transaction_date=request.transaction_date,
            description=request.description.strip() if request.description else None,
            notes=request.notes.strip() if request.notes else None,
            owner_user_id=None,
            group_id=group_id,
            created_by_user_id=user.id,
            input_method=request.input_method,
            receipt_id=request.receipt_id,
        )
        return TransactionRepository.create(db, tx)

    @classmethod
    def get_group_transaction(
        cls,
        db: Session,
        user: User,
        group_id: str,
        transaction_id: str,
    ) -> Transaction:
        """Fetch a single transaction from a group."""
        cls._ensure_active_membership(db, group_id, user.id)
        tx = TransactionRepository.get_group_transaction(db, transaction_id, group_id)
        if not tx:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found in this group.",
            )
        return tx

    @classmethod
    def list_group_transactions(
        cls,
        db: Session,
        user: User,
        group_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        transaction_type: Optional[str] = None,
        category_id: Optional[str] = None,
        created_by_user_id: Optional[str] = None,
        search: Optional[str] = None,
        min_amount: Optional[Decimal] = None,
        max_amount: Optional[Decimal] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedTransactionResponse:
        """List group transactions with filtering and pagination."""
        cls._ensure_active_membership(db, group_id, user.id)

        if page < 1:
            page = 1
        if page_size < 1 or page_size > 100:
            page_size = 20

        items, total = TransactionRepository.get_group_transactions_paginated(
            db=db,
            group_id=group_id,
            start_date=start_date,
            end_date=end_date,
            transaction_type=transaction_type,
            category_id=category_id,
            created_by_user_id=created_by_user_id,
            search=search,
            min_amount=min_amount,
            max_amount=max_amount,
            page=page,
            page_size=page_size,
        )
        total_pages = math.ceil(total / page_size) if total > 0 else 1

        return PaginatedTransactionResponse(
            items=[TransactionResponse.model_validate(tx) for tx in items],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )

    @classmethod
    def update_group_transaction(
        cls,
        db: Session,
        user: User,
        group_id: str,
        transaction_id: str,
        request: TransactionUpdate,
    ) -> Transaction:
        """Update a group transaction. Owner/admin can edit any; members can only edit their own."""
        role = cls._ensure_active_membership(db, group_id, user.id)
        tx = TransactionRepository.get_group_transaction(db, transaction_id, group_id)
        if not tx:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found in this group.",
            )

        # Authorization: member can only edit their own transaction
        if role == "member" and tx.created_by_user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Regular members can only modify transactions they recorded.",
            )

        target_type = request.type if request.type is not None else tx.type

        if request.category_id is not None:
            category = CategoryRepository.get_by_id(db, request.category_id)
            if not category:
                raise HTTPException(status_code=404, detail="Category not found.")
            if category.type != target_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category type '{category.type}' incompatible with transaction type '{target_type}'.",
                )
            tx.category_id = category.id

        if request.type is not None:
            tx.type = request.type
        if request.amount is not None:
            tx.amount = request.amount
        if request.transaction_date is not None:
            tx.transaction_date = request.transaction_date
        if request.description is not None:
            tx.description = request.description.strip() if request.description else None
        if request.notes is not None:
            tx.notes = request.notes.strip() if request.notes else None

        return TransactionRepository.update(db, tx)

    @classmethod
    def delete_group_transaction(
        cls,
        db: Session,
        user: User,
        group_id: str,
        transaction_id: str,
    ) -> None:
        """Delete a group transaction. Owner/admin can delete any; members can only delete their own."""
        role = cls._ensure_active_membership(db, group_id, user.id)
        tx = TransactionRepository.get_group_transaction(db, transaction_id, group_id)
        if not tx:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found in this group.",
            )

        if role == "member" and tx.created_by_user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Regular members can only delete transactions they recorded.",
            )

        TransactionRepository.delete(db, tx)

    @classmethod
    def get_group_dashboard(
        cls,
        db: Session,
        user: User,
        group_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> GroupDashboardResponse:
        """Generate aggregated financial dashboard for family group."""
        cls._ensure_active_membership(db, group_id, user.id)
        group = GroupRepository.get_by_id(db, group_id)
        if not group:
            raise HTTPException(status_code=404, detail="Group not found.")

        # Summary
        summary = TransactionRepository.get_group_summary(db, group_id, start_date, end_date)
        total_income = summary["total_income"]
        total_expense = summary["total_expense"]
        pending_reimbursement = summary.get("pending_reimbursement", Decimal("0.00"))
        net_balance = summary["net_balance"]

        # Category breakdowns
        expense_rows = TransactionRepository.get_group_category_breakdown(
            db, group_id, "expense", start_date, end_date
        )
        expense_breakdown = [
            CategoryBreakdownItem(
                category_id=r["category_id"],
                category_name=r["category_name"],
                category_icon=r["category_icon"],
                category_color=r["category_color"],
                total_amount=r["total_amount"],
                percentage=round(float(r["total_amount"] / total_expense * 100), 2) if total_expense > 0 else 0.0,
                transaction_count=r["transaction_count"],
            )
            for r in expense_rows
        ]

        income_rows = TransactionRepository.get_group_category_breakdown(
            db, group_id, "income", start_date, end_date
        )
        income_breakdown = [
            CategoryBreakdownItem(
                category_id=r["category_id"],
                category_name=r["category_name"],
                category_icon=r["category_icon"],
                category_color=r["category_color"],
                total_amount=r["total_amount"],
                percentage=round(float(r["total_amount"] / total_income * 100), 2) if total_income > 0 else 0.0,
                transaction_count=r["transaction_count"],
            )
            for r in income_rows
        ]

        # Recent transactions
        recent_txs = TransactionRepository.get_group_recent_transactions(db, group_id, limit=5)

        # Member contributions
        contributions = TransactionRepository.get_group_member_contributions(db, group_id, start_date, end_date)
        member_items = [
            MemberContributionItem(
                user_id=c["user_id"],
                user_name=c["user_name"],
                total_expense=c["total_expense"],
                total_income=c["total_income"],
                transaction_count=c["transaction_count"],
            )
            for c in contributions
        ]

        return GroupDashboardResponse(
            group_id=group.id,
            group_name=group.name,
            total_income=total_income,
            total_expense=total_expense,
            pending_reimbursement=pending_reimbursement,
            net_balance=net_balance,
            recent_transactions=[TransactionResponse.model_validate(tx) for tx in recent_txs],
            expense_by_category=expense_breakdown,
            income_by_category=income_breakdown,
            member_contributions=member_items,
            start_date=start_date,
            end_date=end_date,
        )

    @classmethod
    def get_group_report(
        cls,
        db: Session,
        user: User,
        group_id: str,
        start_date: datetime,
        end_date: datetime,
        period_name: str = "custom",
    ) -> GroupReportResponse:
        """Generate complete shared financial report for the family group."""
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

        cls._ensure_active_membership(db, group_id, user.id)
        group = GroupRepository.get_by_id(db, group_id)
        if not group:
            raise HTTPException(status_code=404, detail="Group not found.")

        # Summary
        summary = TransactionRepository.get_group_summary(db, group_id, clean_start, clean_end)
        total_income = summary["total_income"]
        total_expense = summary["total_expense"]
        pending_reimbursement = summary.get("pending_reimbursement", Decimal("0.00"))
        net_savings = total_income - total_expense
        savings_rate = float((net_savings / total_income * 100)) if total_income > 0 else 0.0

        # Category breakdowns
        expense_rows = TransactionRepository.get_group_category_breakdown(
            db, group_id, "expense", clean_start, clean_end
        )
        expense_breakdown = [
            CategoryBreakdownItem(
                category_id=r["category_id"],
                category_name=r["category_name"],
                category_icon=r["category_icon"],
                category_color=r["category_color"],
                total_amount=r["total_amount"],
                percentage=round(float(r["total_amount"] / total_expense * 100), 2) if total_expense > 0 else 0.0,
                transaction_count=r["transaction_count"],
            )
            for r in expense_rows
        ]

        income_rows = TransactionRepository.get_group_category_breakdown(
            db, group_id, "income", clean_start, clean_end
        )
        income_breakdown = [
            CategoryBreakdownItem(
                category_id=r["category_id"],
                category_name=r["category_name"],
                category_icon=r["category_icon"],
                category_color=r["category_color"],
                total_amount=r["total_amount"],
                percentage=round(float(r["total_amount"] / total_income * 100), 2) if total_income > 0 else 0.0,
                transaction_count=r["transaction_count"],
            )
            for r in income_rows
        ]

        # Monthly trends
        stmt = (
            select(Transaction.type, Transaction.amount, Transaction.transaction_date, Transaction.notes)
            .where(
                Transaction.group_id == group_id,
                Transaction.transaction_date >= clean_start,
                Transaction.transaction_date <= clean_end,
            )
            .order_by(Transaction.transaction_date.asc())
        )
        tx_rows = db.execute(stmt).all()
        monthly_data: dict[str, dict[str, Decimal]] = defaultdict(
            lambda: {"income": Decimal("0.00"), "expense": Decimal("0.00")}
        )
        for tx_type, amount, tx_date, notes in tx_rows:
            m_key = tx_date.strftime("%Y-%m")
            if tx_type == "income":
                monthly_data[m_key]["income"] += amount
            elif tx_type == "expense":
                # Realized expense only (un-reimbursed talangan does not reduce event cash yet)
                is_pending = bool(notes and "[REIMBURSE_PENDING]" in notes)
                if not is_pending:
                    monthly_data[m_key]["expense"] += amount

        monthly_trends = [
            MonthlyTrendItem(
                month=m,
                income=vals["income"],
                expense=vals["expense"],
                net=vals["income"] - vals["expense"],
            )
            for m, vals in sorted(monthly_data.items())
        ]

        # Member contributions
        contributions = TransactionRepository.get_group_member_contributions(db, group_id, start_date, end_date)
        member_items = [
            MemberContributionItem(
                user_id=c["user_id"],
                user_name=c["user_name"],
                total_expense=c["total_expense"],
                total_income=c["total_income"],
                transaction_count=c["transaction_count"],
            )
            for c in contributions
        ]

        return GroupReportResponse(
            group_id=group.id,
            group_name=group.name,
            period=period_name,
            start_date=start_date,
            end_date=end_date,
            total_income=total_income,
            total_expense=total_expense,
            pending_reimbursement=pending_reimbursement,
            net_savings=net_savings,
            savings_rate=round(savings_rate, 2),
            expense_by_category=expense_breakdown,
            income_by_category=income_breakdown,
            monthly_trends=monthly_trends,
            member_contributions=member_items,
        )
