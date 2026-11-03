"""Receipt ORM model."""
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Any, Dict, List, Optional
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    Numeric,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.transaction import Transaction
    from app.models.transaction_item import TransactionItem
    from app.models.user import User


class Receipt(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Receipt file upload and OCR processing model."""

    __tablename__ = "receipts"
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'confirmed', 'rejected', 'failed')",
            name="ck_receipts_status",
        ),
        Index("ix_receipts_user_status", "user_id", "status"),
        Index("ix_receipts_group_id", "group_id"),
    )

    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        comment="User who uploaded the receipt",
    )
    group_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="RESTRICT"),
        nullable=True,
        comment="Target finance group if receipt belongs to group ledger",
    )
    file_path: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
        comment="Relative path in private storage directory",
    )
    file_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        comment="Sanitized uploaded filename",
    )
    file_size: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        comment="File size in bytes",
    )
    mime_type: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="MIME content type (e.g. image/jpeg, image/png)",
    )
    merchant_name: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
        comment="Extracted or user-edited merchant/store name",
    )
    receipt_date: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable=True,
        comment="Extracted date on receipt",
    )
    total_amount: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2),
        nullable=True,
        comment="Extracted or confirmed total payment amount",
    )
    raw_ocr_data: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON,
        nullable=True,
        comment="Raw JSON output from OCR engine for audit/parsing",
    )
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="draft",
        comment="Receipt processing status: draft, confirmed, rejected, failed",
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="receipts",
        foreign_keys=[user_id],
    )
    group: Mapped[Optional["FinanceGroup"]] = relationship(
        "FinanceGroup",
        back_populates="receipts",
        foreign_keys=[group_id],
    )
    items: Mapped[List["TransactionItem"]] = relationship(
        "TransactionItem",
        back_populates="receipt",
        foreign_keys="TransactionItem.receipt_id",
        cascade="all, delete-orphan",
    )
    transactions: Mapped[List["Transaction"]] = relationship(
        "Transaction",
        back_populates="receipt",
        foreign_keys="Transaction.receipt_id",
    )

    def __repr__(self) -> str:
        return f"<Receipt id={self.id} status={self.status} total_amount={self.total_amount}>"
