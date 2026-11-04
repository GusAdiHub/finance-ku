"""User repository for database operations."""
from typing import Optional
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.models.user import User


class UserRepository:
    """Repository handling all database interactions for User entity."""

    @staticmethod
    def get_by_id(db: Session, user_id: str) -> Optional[User]:
        """Fetch a user by primary key UUID."""
        stmt = select(User).where(User.id == user_id)
        return db.scalar(stmt)

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        """Fetch a user by unique email address (case-insensitive search)."""
        stmt = select(User).where(User.email == email.strip().lower())
        return db.scalar(stmt)

    @staticmethod
    def exists_by_email(db: Session, email: str) -> bool:
        """Check if an email address is already registered."""
        stmt = select(User.id).where(User.email == email.strip().lower())
        return db.scalar(stmt) is not None

    @staticmethod
    def exists_by_name(db: Session, name: str) -> bool:
        """Check if a username/name is already registered."""
        stmt = select(User.id).where(func.lower(User.name) == name.strip().lower())
        return db.scalar(stmt) is not None

    @staticmethod
    def get_by_identifier(db: Session, identifier: str) -> Optional[User]:
        """Fetch a user by email, local username email, or name (case-insensitive)."""
        clean_id = identifier.strip().lower()

        # 1. Exact email match
        user = db.scalar(select(User).where(func.lower(User.email) == clean_id))
        if user:
            return user

        # 2. Local username email match (username@sakuku.local)
        local_email = f"{clean_id}@sakuku.local"
        user = db.scalar(select(User).where(func.lower(User.email) == local_email))
        if user:
            return user

        # 3. Exact username/name match
        user = db.scalars(select(User).where(func.lower(User.name) == clean_id)).first()
        return user

    @staticmethod
    def create(db: Session, user: User) -> User:
        """Persist a new user to the database."""
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def update(db: Session, user: User) -> User:
        """Commit updates to an existing user."""
        db.commit()
        db.refresh(user)
        return user
