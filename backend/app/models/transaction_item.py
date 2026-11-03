"""TransactionItem ORM model."""
from decimal import Decimal
from typing import TYPE_CHECKING, Optional
from sqlalchemy import CheckConstraint, ForeignKey, Index, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.receipt import Receipt
    from app.models.transaction import Transaction


class TransactionItem(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Line items breakdown for transactions and receipt drafts."""

    __tablename__ = "transaction_items"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_transaction_items_qty_positive"),
        CheckConstraint("price_per_unit >= 0", name="ck_transaction_items_price_nonneg"),
        CheckConstraint("total_price >= 0", name="ck_transaction_items_total_nonneg"),
        CheckConstraint(
            "(transaction_id IS NOT NULL OR receipt_id IS NOT NULL)",
            name="ck_transaction_items_has_parent",
        ),
        Index("ix_transaction_items_tx_id", "transaction_id"),
        Index("ix_transaction_items_rcpt_id", "receipt_id"),
    )

    transaction_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("transactions.id", ondelete="CASCADE"),
        nullable=True,
        comment="Associated confirmed transaction",
    )
    receipt_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=True,
        comment="Associated receipt draft",
    )
    item_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        comment="Product or item description",
    )
    quantity: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        nullable=False,
        default=Decimal("1.00"),
        comment="Item count or quantity",
    )
    price_per_unit: Mapped[Decimal] = mapped_column(
        Numeric(15, 2),
        nullable=False,
        comment="Unit price in IDR",
    )
    total_price: Mapped[Decimal] = mapped_column(
        Numeric(15, 2),
        nullable=False,
        comment="Total item cost (quantity * price_per_unit)",
    )

    # Relationships
    transaction: Mapped[Optional["Transaction"]] = relationship(
        "Transaction",
        back_populates="items",
        foreign_keys=[transaction_id],
    )
    receipt: Mapped[Optional["Receipt"]] = relationship(
        "Receipt",
        back_populates="items",
        foreign_keys=[receipt_id],
    )

    def __repr__(self) -> str:
        return f"<TransactionItem id={self.id} item='{self.item_name}' total={self.total_price}>"
