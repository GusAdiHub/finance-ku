"""Declarative base class for SQLAlchemy models."""
import uuid
from datetime import datetime
from sqlalchemy import CHAR, DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""
    pass


class TimestampMixin:
    """Mixin that adds created_at and updated_at timestamps in UTC."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
        comment="Record creation timestamp (UTC)",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
        comment="Record last update timestamp (UTC)",
    )


class UUIDPrimaryKeyMixin:
    """Mixin that adds standard CHAR(36) UUID primary key."""

    id: Mapped[str] = mapped_column(
        CHAR(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        comment="Unique identifier (UUID v4)",
    )
