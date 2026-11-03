"""GroupInvitation ORM model."""
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.user import User


class GroupInvitation(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Group invitation model with hashed code and expiration."""

    __tablename__ = "group_invitations"
    __table_args__ = (
        CheckConstraint("max_uses >= 1", name="ck_invitations_max_uses"),
        CheckConstraint("uses_count >= 0", name="ck_invitations_uses_count"),
        Index("ix_invitations_group_status", "group_id", "is_revoked", "expires_at"),
    )

    group_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    created_by_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    code_hash: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
        comment="Cryptographic hash of the random invitation code",
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        comment="Expiration timestamp (UTC)",
    )
    max_uses: Mapped[int] = mapped_column(
        Integer,
        default=1,
        nullable=False,
        comment="Maximum number of times this code can be used",
    )
    uses_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
        comment="Current number of times this code has been used",
    )
    is_revoked: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
        comment="Flag indicating if invitation was revoked by owner/admin",
    )

    # Relationships
    group: Mapped["FinanceGroup"] = relationship("FinanceGroup", back_populates="invitations")
    creator: Mapped["User"] = relationship(
        "User",
        back_populates="created_invitations",
        foreign_keys=[created_by_user_id],
    )

    def __repr__(self) -> str:
        return f"<GroupInvitation id={self.id} group_id={self.group_id} is_revoked={self.is_revoked}>"
