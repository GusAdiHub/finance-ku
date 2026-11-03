"""Database package initialization."""
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from app.database.session import SessionLocal, engine, get_db

# Import models so Base.metadata is fully populated with all table schemas
import app.models  # noqa: F401

__all__ = [
    "Base",
    "TimestampMixin",
    "UUIDPrimaryKeyMixin",
    "SessionLocal",
    "engine",
    "get_db",
]
