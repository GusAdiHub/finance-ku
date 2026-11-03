"""Transaction repository for database operations."""
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session, selectinload
from app.models.category import Category
from app.models.transaction import Transaction


class TransactionRepository:
    """Repository handling all database interactions for Transaction entity."""

    @staticmethod
    def get_by_id(db: Session, transaction_id: str) -> Optional[Transaction]:
        """Fetch a transaction by ID with its category loaded."""
        stmt = (
            select(Transaction)
            .options(selectinload(Transaction.category))
            .where(Transaction.id == transaction_id)
        )
        return db.scalar(stmt)

    @staticmethod
    def get_personal_transaction(
        db: Session,
        transaction_id: str,
        user_id: str,
    ) -> Optional[Transaction]:
        """Fetch a personal transaction owned by the specified user (prevents IDOR)."""
        stmt = (
            select(Transaction)
            .options(selectinload(Transaction.category))
            .where(
                Transaction.id == transaction_id,
                Transaction.owner_user_id == user_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def get_personal_transactions_paginated(
        db: Session,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        transaction_type: Optional[str] = None,
        category_id: Optional[str] = None,
        search: Optional[str] = None,
        min_amount: Optional[Decimal] = None,
        max_amount: Optional[Decimal] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Transaction], int]:
        """Fetch paginated personal transactions matching filter criteria."""
        base_stmt = select(Transaction).where(Transaction.owner_user_id == user_id)

        # Filters
        if start_date:
            base_stmt = base_stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            base_stmt = base_stmt.where(Transaction.transaction_date <= end_date)
        if transaction_type:
            base_stmt = base_stmt.where(Transaction.type == transaction_type)
        if category_id:
            base_stmt = base_stmt.where(Transaction.category_id == category_id)
        if search and search.strip():
            term = f"%{search.strip()}%"
            base_stmt = base_stmt.where(
                or_(
                    Transaction.description.ilike(term),
                    Transaction.notes.ilike(term),
                )
            )
        if min_amount is not None:
            base_stmt = base_stmt.where(Transaction.amount >= min_amount)
        if max_amount is not None:
            base_stmt = base_stmt.where(Transaction.amount <= max_amount)

        # Total count
        count_stmt = select(func.count()).select_from(base_stmt.subquery())
        total = db.scalar(count_stmt) or 0

        # Paginated items
        items_stmt = (
            base_stmt.options(selectinload(Transaction.category))
            .order_by(
                Transaction.transaction_date.desc(),
                Transaction.created_at.desc(),
            )
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        items = list(db.scalars(items_stmt).all())

        return items, total

    @staticmethod
    def get_personal_summary(
        db: Session,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Dict[str, Decimal]:
        """Calculate total income, total expense, and net balance for a personal ledger."""
        income_case = case((Transaction.type == "income", Transaction.amount), else_=Decimal("0.00"))
        expense_case = case((Transaction.type == "expense", Transaction.amount), else_=Decimal("0.00"))

        stmt = select(
            func.coalesce(func.sum(income_case), Decimal("0.00")).label("total_income"),
            func.coalesce(func.sum(expense_case), Decimal("0.00")).label("total_expense"),
        ).where(Transaction.owner_user_id == user_id)

        if start_date:
            stmt = stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            stmt = stmt.where(Transaction.transaction_date <= end_date)

        row = db.execute(stmt).one()
        total_income = Decimal(str(row.total_income))
        total_expense = Decimal(str(row.total_expense))
        net_balance = total_income - total_expense

        return {
            "total_income": total_income,
            "total_expense": total_expense,
            "net_balance": net_balance,
        }

    @staticmethod
    def get_personal_category_breakdown(
        db: Session,
        user_id: str,
        transaction_type: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        """Calculate amount and percentage aggregated by category for personal transactions."""
        stmt = (
            select(
                Category.id.label("category_id"),
                Category.name.label("category_name"),
                Category.icon.label("category_icon"),
                Category.color.label("category_color"),
                func.sum(Transaction.amount).label("total_amount"),
                func.count(Transaction.id).label("transaction_count"),
            )
            .join(Category, Transaction.category_id == Category.id)
            .where(
                Transaction.owner_user_id == user_id,
                Transaction.type == transaction_type,
            )
        )

        if start_date:
            stmt = stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            stmt = stmt.where(Transaction.transaction_date <= end_date)

        stmt = stmt.group_by(
            Category.id,
            Category.name,
            Category.icon,
            Category.color,
        ).order_by(func.sum(Transaction.amount).desc())

        rows = db.execute(stmt).all()
        return [
            {
                "category_id": r.category_id,
                "category_name": r.category_name,
                "category_icon": r.category_icon,
                "category_color": r.category_color,
                "total_amount": Decimal(str(r.total_amount)),
                "transaction_count": int(r.transaction_count),
            }
            for r in rows
        ]

    @staticmethod
    def get_personal_recent_transactions(
        db: Session,
        user_id: str,
        limit: int = 5,
    ) -> List[Transaction]:
        """Fetch the most recent personal transactions."""
        stmt = (
            select(Transaction)
            .options(selectinload(Transaction.category))
            .where(Transaction.owner_user_id == user_id)
            .order_by(
                Transaction.transaction_date.desc(),
                Transaction.created_at.desc(),
            )
            .limit(limit)
        )
        return list(db.scalars(stmt).all())

    # -------------------------------------------------------------------------
    # Group Transaction Operations (Shared Ledger)
    # -------------------------------------------------------------------------

    @staticmethod
    def get_group_transaction(
        db: Session,
        transaction_id: str,
        group_id: str,
    ) -> Optional[Transaction]:
        """Fetch a group transaction ensuring it belongs to the target group."""
        stmt = (
            select(Transaction)
            .options(selectinload(Transaction.category))
            .where(
                Transaction.id == transaction_id,
                Transaction.group_id == group_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def get_group_transactions_paginated(
        db: Session,
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
    ) -> Tuple[List[Transaction], int]:
        """Fetch paginated group transactions matching filter criteria."""
        base_stmt = select(Transaction).where(Transaction.group_id == group_id)

        if start_date:
            base_stmt = base_stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            base_stmt = base_stmt.where(Transaction.transaction_date <= end_date)
        if transaction_type:
            base_stmt = base_stmt.where(Transaction.type == transaction_type)
        if category_id:
            base_stmt = base_stmt.where(Transaction.category_id == category_id)
        if created_by_user_id:
            base_stmt = base_stmt.where(Transaction.created_by_user_id == created_by_user_id)
        if search and search.strip():
            term = f"%{search.strip()}%"
            base_stmt = base_stmt.where(
                or_(
                    Transaction.description.ilike(term),
                    Transaction.notes.ilike(term),
                )
            )
        if min_amount is not None:
            base_stmt = base_stmt.where(Transaction.amount >= min_amount)
        if max_amount is not None:
            base_stmt = base_stmt.where(Transaction.amount <= max_amount)

        count_stmt = select(func.count()).select_from(base_stmt.subquery())
        total = db.scalar(count_stmt) or 0

        items_stmt = (
            base_stmt.options(selectinload(Transaction.category))
            .order_by(
                Transaction.transaction_date.desc(),
                Transaction.created_at.desc(),
            )
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        items = list(db.scalars(items_stmt).all())
        return items, total

    @staticmethod
    def get_group_summary(
        db: Session,
        group_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Dict[str, Decimal]:
        """Calculate total income, total expense, and net balance for a shared family group."""
        income_case = case((Transaction.type == "income", Transaction.amount), else_=Decimal("0.00"))
        expense_case = case((Transaction.type == "expense", Transaction.amount), else_=Decimal("0.00"))

        stmt = select(
            func.coalesce(func.sum(income_case), Decimal("0.00")).label("total_income"),
            func.coalesce(func.sum(expense_case), Decimal("0.00")).label("total_expense"),
        ).where(Transaction.group_id == group_id)

        if start_date:
            stmt = stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            stmt = stmt.where(Transaction.transaction_date <= end_date)

        row = db.execute(stmt).one()
        total_income = Decimal(str(row.total_income))
        total_expense = Decimal(str(row.total_expense))
        net_balance = total_income - total_expense

        return {
            "total_income": total_income,
            "total_expense": total_expense,
            "net_balance": net_balance,
        }

    @staticmethod
    def get_group_category_breakdown(
        db: Session,
        group_id: str,
        transaction_type: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        """Calculate amount aggregated by category for group transactions."""
        stmt = (
            select(
                Category.id.label("category_id"),
                Category.name.label("category_name"),
                Category.icon.label("category_icon"),
                Category.color.label("category_color"),
                func.sum(Transaction.amount).label("total_amount"),
                func.count(Transaction.id).label("transaction_count"),
            )
            .join(Category, Transaction.category_id == Category.id)
            .where(
                Transaction.group_id == group_id,
                Transaction.type == transaction_type,
            )
        )

        if start_date:
            stmt = stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            stmt = stmt.where(Transaction.transaction_date <= end_date)

        stmt = stmt.group_by(
            Category.id,
            Category.name,
            Category.icon,
            Category.color,
        ).order_by(func.sum(Transaction.amount).desc())

        rows = db.execute(stmt).all()
        return [
            {
                "category_id": r.category_id,
                "category_name": r.category_name,
                "category_icon": r.category_icon,
                "category_color": r.category_color,
                "total_amount": Decimal(str(r.total_amount)),
                "transaction_count": int(r.transaction_count),
            }
            for r in rows
        ]

    @staticmethod
    def get_group_recent_transactions(
        db: Session,
        group_id: str,
        limit: int = 5,
    ) -> List[Transaction]:
        """Fetch the most recent group transactions."""
        stmt = (
            select(Transaction)
            .options(selectinload(Transaction.category))
            .where(Transaction.group_id == group_id)
            .order_by(
                Transaction.transaction_date.desc(),
                Transaction.created_at.desc(),
            )
            .limit(limit)
        )
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_group_member_contributions(
        db: Session,
        group_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        """Calculate transaction count and amounts entered by each member."""
        from app.models.user import User

        expense_case = case((Transaction.type == "expense", Transaction.amount), else_=Decimal("0.00"))
        income_case = case((Transaction.type == "income", Transaction.amount), else_=Decimal("0.00"))

        stmt = (
            select(
                User.id.label("user_id"),
                User.name.label("user_name"),
                func.coalesce(func.sum(expense_case), Decimal("0.00")).label("total_expense"),
                func.coalesce(func.sum(income_case), Decimal("0.00")).label("total_income"),
                func.count(Transaction.id).label("transaction_count"),
            )
            .join(User, Transaction.created_by_user_id == User.id)
            .where(Transaction.group_id == group_id)
        )

        if start_date:
            stmt = stmt.where(Transaction.transaction_date >= start_date)
        if end_date:
            stmt = stmt.where(Transaction.transaction_date <= end_date)

        stmt = stmt.group_by(User.id, User.name).order_by(func.sum(expense_case).desc())
        rows = db.execute(stmt).all()

        return [
            {
                "user_id": r.user_id,
                "user_name": r.user_name,
                "total_expense": Decimal(str(r.total_expense)),
                "total_income": Decimal(str(r.total_income)),
                "transaction_count": int(r.transaction_count),
            }
            for r in rows
        ]

    @staticmethod
    def create(db: Session, transaction: Transaction) -> Transaction:
        """Persist a new transaction."""
        db.add(transaction)
        db.commit()
        db.refresh(transaction)
        return transaction

    @staticmethod
    def update(db: Session, transaction: Transaction) -> Transaction:
        """Commit updates to an existing transaction."""
        db.commit()
        db.refresh(transaction)
        return transaction

    @staticmethod
    def delete(db: Session, transaction: Transaction) -> None:
        """Delete a transaction from the database."""
        db.delete(transaction)
        db.commit()
