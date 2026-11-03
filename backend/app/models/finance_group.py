"""FinanceGroup ORM model."""
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.group_member import GroupMember
    from app.models.group_invitation import GroupInvitation
    from app.models.category import Category
    from app.models.transaction import Transaction
    from app.models.receipt import Receipt
    from app.models.audit_log import AuditLog


class FinanceGroup(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Family Finance Group model (Shared Ledger)."""

    __tablename__ = "finance_groups"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    creator: Mapped["User"] = relationship(
        "User",
        back_populates="created_groups",
        foreign_keys=[created_by_user_id],
    )
    members: Mapped[List["GroupMember"]] = relationship(
        "GroupMember",
        back_populates="group",
        cascade="all, delete-orphan",
    )
    invitations: Mapped[List["GroupInvitation"]] = relationship(
        "GroupInvitation",
        back_populates="group",
        cascade="all, delete-orphan",
    )
    transactions: Mapped[List["Transaction"]] = relationship(
        "Transaction",
        back_populates="group",
        foreign_keys="Transaction.group_id",
    )
    categories: Mapped[List["Category"]] = relationship(
        "Category",
        back_populates="group",
        foreign_keys="Category.group_id",
    )
    receipts: Mapped[List["Receipt"]] = relationship(
        "Receipt",
        back_populates="group",
        foreign_keys="Receipt.group_id",
    )
    audit_logs: Mapped[List["AuditLog"]] = relationship(
        "AuditLog",
        back_populates="group",
        foreign_keys="AuditLog.group_id",
    )

    def __repr__(self) -> str:
        return f"<FinanceGroup id={self.id} name='{self.name}' is_active={self.is_active}>"
