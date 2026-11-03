"""Transaction ORM model."""
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.category import Category
    from app.models.finance_group import FinanceGroup
    from app.models.receipt import Receipt
    from app.models.transaction_item import TransactionItem
    from app.models.user import User


class Transaction(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Core financial transaction model for Personal and Family Finance."""

    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("type IN ('income', 'expense')", name="ck_transactions_type"),
        CheckConstraint("amount > 0", name="ck_transactions_amount_positive"),
        CheckConstraint(
            "input_method IN ('manual', 'ocr', 'voice')",
            name="ck_transactions_input_method",
        ),
        CheckConstraint(
            "("
            "(owner_user_id IS NOT NULL AND group_id IS NULL) OR "
            "(owner_user_id IS NULL AND group_id IS NOT NULL)"
            ")",
            name="ck_transactions_single_scope",
        ),
        Index("ix_transactions_personal_date", "owner_user_id", "transaction_date"),
        Index("ix_transactions_group_date", "group_id", "transaction_date"),
        Index("ix_transactions_category_id", "category_id"),
        Index("ix_transactions_creator_id", "created_by_user_id"),
        Index("ix_transactions_date", "transaction_date"),
    )

    type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        comment="Transaction type: 'income' or 'expense'",
    )
    amount: Mapped[Decimal] = mapped_column(
        Numeric(15, 2),
        nullable=False,
        comment="Monetary amount in IDR (must be greater than 0)",
    )
    category_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("categories.id", ondelete="RESTRICT"),
        nullable=False,
    )
    transaction_date: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        comment="Date and time of transaction (UTC)",
    )
    description: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
        comment="Short summary / payee / description",
    )
    notes: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
        comment="Detailed optional notes",
    )

    # Scoping: Either personal (owner_user_id) OR group (group_id)
    owner_user_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=True,
        comment="Owner of personal transaction; NULL for group transactions",
    )
    group_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="RESTRICT"),
        nullable=True,
        comment="Target finance group for shared transactions; NULL for personal",
    )
    created_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        comment="User who recorded this transaction",
    )

    # Input method
    input_method: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="manual",
        comment="Input source: 'manual', 'ocr', or 'voice'",
    )

    # Optional linkage to receipt
    receipt_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("receipts.id", ondelete="SET NULL"),
        nullable=True,
        comment="Associated receipt if created via OCR",
    )

    # Relationships
    owner_user: Mapped[Optional["User"]] = relationship(
        "User",
        back_populates="personal_transactions",
        foreign_keys=[owner_user_id],
    )
    creator: Mapped["User"] = relationship(
        "User",
        back_populates="created_transactions",
        foreign_keys=[created_by_user_id],
    )
    group: Mapped[Optional["FinanceGroup"]] = relationship(
        "FinanceGroup",
        back_populates="transactions",
        foreign_keys=[group_id],
    )
    category: Mapped["Category"] = relationship(
        "Category",
        back_populates="transactions",
        foreign_keys=[category_id],
    )
    receipt: Mapped[Optional["Receipt"]] = relationship(
        "Receipt",
        back_populates="transactions",
        foreign_keys=[receipt_id],
    )
    items: Mapped[List["TransactionItem"]] = relationship(
        "TransactionItem",
        back_populates="transaction",
        foreign_keys="TransactionItem.transaction_id",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Transaction id={self.id} type={self.type} amount={self.amount} date={self.transaction_date}>"
