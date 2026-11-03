"""GroupMember ORM model."""
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Index, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.user import User


class GroupMember(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Membership association between User and FinanceGroup."""

    __tablename__ = "group_members"
    __table_args__ = (
        UniqueConstraint("group_id", "user_id", name="uq_group_members_group_user"),
        CheckConstraint("role IN ('owner', 'admin', 'member')", name="ck_group_members_role"),
        Index("ix_group_members_group_active", "group_id", "is_active"),
        Index("ix_group_members_user_active", "user_id", "is_active"),
    )

    group_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="RESTRICT"),
        nullable=False,
    )
    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    role: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="member",
        comment="Member role: owner, admin, or member",
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
        comment="Timestamp when user joined group",
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
        comment="Active membership flag (false if member left or removed)",
    )

    # Relationships
    group: Mapped["FinanceGroup"] = relationship("FinanceGroup", back_populates="members")
    user: Mapped["User"] = relationship("User", back_populates="group_memberships")

    def __repr__(self) -> str:
        return f"<GroupMember id={self.id} group_id={self.group_id} user_id={self.user_id} role={self.role}>"
