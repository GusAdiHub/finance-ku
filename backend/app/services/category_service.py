"""Category service layer for managing categories."""
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.category import Category
from app.models.user import User
from app.repositories.category_repository import CategoryRepository
from app.schemas.category import CategoryCreate, CategoryUpdate


class CategoryService:
    """Business logic for default and custom categories."""

    @classmethod
    def list_categories(
        cls,
        db: Session,
        user: User,
        category_type: Optional[str] = None,
    ) -> List[Category]:
        """List all available system categories and the user's custom categories."""
        return CategoryRepository.get_available_categories(
            db,
            user_id=user.id,
            category_type=category_type,
        )

    @classmethod
    def get_category_for_user(
        cls,
        db: Session,
        user: User,
        category_id: str,
    ) -> Category:
        """Fetch category if it belongs to system or the user, otherwise raise 404."""
        category = CategoryRepository.get_by_id(db, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if not category.is_system and category.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        return category

    @classmethod
    def create_custom_category(
        cls,
        db: Session,
        user: User,
        request: CategoryCreate,
    ) -> Category:
        """Create a new custom category for the user."""
        name = request.name.strip()
        if CategoryRepository.exists_name_for_user(db, name, user.id, request.type):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category '{name}' with type '{request.type}' already exists.",
            )

        new_category = Category(
            name=name,
            type=request.type,
            icon=request.icon,
            color=request.color,
            is_system=False,
            user_id=user.id,
            group_id=None,
        )
        return CategoryRepository.create(db, new_category)

    @classmethod
    def update_custom_category(
        cls,
        db: Session,
        user: User,
        category_id: str,
        request: CategoryUpdate,
    ) -> Category:
        """Update a custom category owned by the user."""
        category = CategoryRepository.get_by_id(db, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if category.is_system:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="System categories cannot be modified.",
            )

        if category.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if request.name is not None and request.name.strip():
            new_name = request.name.strip()
            if CategoryRepository.exists_name_for_user(
                db,
                new_name,
                user.id,
                category.type,
                exclude_id=category.id,
            ):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category '{new_name}' with type '{category.type}' already exists.",
                )
            category.name = new_name

        if request.icon is not None:
            category.icon = request.icon

        if request.color is not None:
            category.color = request.color

        return CategoryRepository.update(db, category)

    @classmethod
    def delete_custom_category(
        cls,
        db: Session,
        user: User,
        category_id: str,
    ) -> None:
        """Delete a custom category owned by the user, if not used in transactions."""
        category = CategoryRepository.get_by_id(db, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if category.is_system:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="System categories cannot be deleted.",
            )

        if category.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if CategoryRepository.is_used_in_transactions(db, category_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete category because it is currently used by existing transactions.",
            )

        CategoryRepository.delete(db, category)
