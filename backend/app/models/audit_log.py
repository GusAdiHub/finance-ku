"""AuditLog ORM model."""
from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, Optional
from sqlalchemy import DateTime, ForeignKey, Index, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.user import User


class AuditLog(Base, UUIDPrimaryKeyMixin):
    """Audit log tracking critical financial and security events."""

    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_logs_group_created", "group_id", "created_at"),
        Index("ix_audit_logs_user_created", "user_id", "created_at"),
        Index("ix_audit_logs_entity", "entity_type", "entity_id"),
    )

    user_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        comment="Actor user who performed the action",
    )
    group_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="SET NULL"),
        nullable=True,
        comment="Associated group for shared activity",
    )
    action: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="Action name (e.g. TRANSACTION_CREATE, MEMBER_JOIN, ROLE_CHANGE)",
    )
    entity_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        comment="Entity modified: 'transaction', 'group', 'member', 'category', 'receipt'",
    )
    entity_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        nullable=True,
        comment="ID of the modified entity",
    )
    details: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON,
        nullable=True,
        comment="Structured payload of change (never stores passwords, tokens, or secrets)",
    )
    ip_address: Mapped[Optional[str]] = mapped_column(
        String(45),
        nullable=True,
        comment="Client IP address (IPv4 or IPv6)",
    )
    user_agent: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
        comment="Client browser/device user-agent",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
        comment="Audit event timestamp (UTC)",
    )

    # Relationships
    user: Mapped[Optional["User"]] = relationship(
        "User",
        back_populates="audit_logs",
        foreign_keys=[user_id],
    )
    group: Mapped[Optional["FinanceGroup"]] = relationship(
        "FinanceGroup",
        back_populates="audit_logs",
        foreign_keys=[group_id],
    )

    def __repr__(self) -> str:
        return f"<AuditLog id={self.id} action='{self.action}' entity='{self.entity_type}'>"
