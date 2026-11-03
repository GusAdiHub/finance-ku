"""Category repository for database operations."""
from typing import List, Optional
from sqlalchemy import or_, select
from sqlalchemy.orm import Session
from app.models.category import Category
from app.models.transaction import Transaction


class CategoryRepository:
    """Repository handling database operations for Category entity."""

    @staticmethod
    def get_by_id(db: Session, category_id: str) -> Optional[Category]:
        """Fetch a category by primary key UUID."""
        stmt = select(Category).where(Category.id == category_id)
        return db.scalar(stmt)

    @staticmethod
    def get_available_categories(
        db: Session,
        user_id: str,
        category_type: Optional[str] = None,
    ) -> List[Category]:
        """Fetch all system categories and custom categories owned by the user."""
        stmt = select(Category).where(
            or_(
                Category.is_system.is_(True),
                Category.user_id == user_id,
            )
        )
        if category_type:
            stmt = stmt.where(Category.type == category_type)

        stmt = stmt.order_by(Category.is_system.desc(), Category.name.asc())
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_user_custom_category(
        db: Session,
        category_id: str,
        user_id: str,
    ) -> Optional[Category]:
        """Fetch a custom category owned by the specific user (non-system)."""
        stmt = select(Category).where(
            Category.id == category_id,
            Category.user_id == user_id,
            Category.is_system.is_(False),
        )
        return db.scalar(stmt)

    @staticmethod
    def exists_name_for_user(
        db: Session,
        name: str,
        user_id: str,
        category_type: str,
        exclude_id: Optional[str] = None,
    ) -> bool:
        """Check if a category with the same name and type exists for user or in system."""
        stmt = select(Category.id).where(
            Category.name.ilike(name.strip()),
            Category.type == category_type,
            or_(
                Category.is_system.is_(True),
                Category.user_id == user_id,
            ),
        )
        if exclude_id:
            stmt = stmt.where(Category.id != exclude_id)
        return db.scalar(stmt) is not None

    @staticmethod
    def is_used_in_transactions(db: Session, category_id: str) -> bool:
        """Check whether any transactions reference this category."""
        stmt = select(Transaction.id).where(Transaction.category_id == category_id).limit(1)
        return db.scalar(stmt) is not None

    @staticmethod
    def create(db: Session, category: Category) -> Category:
        """Persist a new category."""
        db.add(category)
        db.commit()
        db.refresh(category)
        return category

    @staticmethod
    def update(db: Session, category: Category) -> Category:
        """Commit updates to an existing category."""
        db.commit()
        db.refresh(category)
        return category

    @staticmethod
    def delete(db: Session, category: Category) -> None:
        """Delete a category from the database."""
        db.delete(category)
        db.commit()
