"""Category management endpoints."""
from typing import List, Literal, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.category import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
)
from app.services.category_service import CategoryService

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get(
    "",
    response_model=List[CategoryResponse],
    status_code=status.HTTP_200_OK,
    summary="List all categories",
)
def list_categories(
    category_type: Optional[Literal["income", "expense"]] = Query(
        None,
        alias="type",
        description="Filter by type: 'income' or 'expense'",
    ),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[CategoryResponse]:
    """Retrieve available system and personal custom categories."""
    categories = CategoryService.list_categories(
        db=db,
        user=current_user,
        category_type=category_type,
    )
    return [CategoryResponse.model_validate(c) for c in categories]


@router.post(
    "",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create custom personal category",
)
def create_category(
    request: CategoryCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> CategoryResponse:
    """Create a new personal category."""
    new_category = CategoryService.create_custom_category(
        db=db,
        user=current_user,
        request=request,
    )
    return CategoryResponse.model_validate(new_category)


@router.patch(
    "/{category_id}",
    response_model=CategoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Update custom personal category",
)
def update_category(
    category_id: str,
    request: CategoryUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> CategoryResponse:
    """Update a custom category owned by the authenticated user."""
    updated = CategoryService.update_custom_category(
        db=db,
        user=current_user,
        category_id=category_id,
        request=request,
    )
    return CategoryResponse.model_validate(updated)


@router.delete(
    "/{category_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete custom personal category",
)
def delete_category(
    category_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Delete a custom category owned by the authenticated user."""
    CategoryService.delete_custom_category(
        db=db,
        user=current_user,
        category_id=category_id,
    )
    return MessageResponse(
        message="Category deleted successfully.",
        success=True,
    )
