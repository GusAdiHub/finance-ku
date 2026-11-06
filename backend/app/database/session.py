"""Database connection and session management."""
from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.core.config import settings

# Engine configuration with connection pooling for PostgreSQL
engine = create_engine(
    settings.sync_database_url,
    pool_pre_ping=True,  # Proactively test connection before using from pool
    pool_size=10,
    max_overflow=20,
    echo=settings.DEBUG and settings.APP_ENV == "development",
)

# Session factory
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency to yield a database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
