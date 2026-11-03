"""User ORM model."""
from typing import TYPE_CHECKING, List
from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.group_member import GroupMember
    from app.models.group_invitation import GroupInvitation
    from app.models.category import Category
    from app.models.transaction import Transaction
    from app.models.receipt import Receipt
    from app.models.audit_log import AuditLog


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """User account model."""

    __tablename__ = "users"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    created_groups: Mapped[List["FinanceGroup"]] = relationship(
        "FinanceGroup",
        back_populates="creator",
        foreign_keys="FinanceGroup.created_by_user_id",
    )
    group_memberships: Mapped[List["GroupMember"]] = relationship(
        "GroupMember",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    created_invitations: Mapped[List["GroupInvitation"]] = relationship(
        "GroupInvitation",
        back_populates="creator",
        foreign_keys="GroupInvitation.created_by_user_id",
    )
    personal_transactions: Mapped[List["Transaction"]] = relationship(
        "Transaction",
        back_populates="owner_user",
        foreign_keys="Transaction.owner_user_id",
    )
    created_transactions: Mapped[List["Transaction"]] = relationship(
        "Transaction",
        back_populates="creator",
        foreign_keys="Transaction.created_by_user_id",
    )
    custom_categories: Mapped[List["Category"]] = relationship(
        "Category",
        back_populates="user",
        foreign_keys="Category.user_id",
    )
    receipts: Mapped[List["Receipt"]] = relationship(
        "Receipt",
        back_populates="user",
        foreign_keys="Receipt.user_id",
    )
    audit_logs: Mapped[List["AuditLog"]] = relationship(
        "AuditLog",
        back_populates="user",
        foreign_keys="AuditLog.user_id",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} is_active={self.is_active}>"
