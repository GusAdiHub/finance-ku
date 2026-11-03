"""Personal transaction management endpoints."""
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.transaction import (
    PaginatedTransactionResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)
from app.services.transaction_service import TransactionService

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.get(
    "",
    response_model=PaginatedTransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="List personal transactions with filters",
)
def list_transactions(
    start_date: Optional[datetime] = Query(None, description="Start date filter (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date filter (UTC)"),
    transaction_type: Optional[Literal["income", "expense"]] = Query(
        None,
        alias="type",
        description="Filter by type ('income' or 'expense')",
    ),
    category_id: Optional[str] = Query(None, description="Filter by category ID"),
    search: Optional[str] = Query(None, description="Keyword search in description or notes"),
    min_amount: Optional[Decimal] = Query(None, ge=0, description="Minimum amount filter"),
    max_amount: Optional[Decimal] = Query(None, ge=0, description="Maximum amount filter"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> PaginatedTransactionResponse:
    """List personal transactions for the authenticated user."""
    return TransactionService.list_personal_transactions(
        db=db,
        user=current_user,
        start_date=start_date,
        end_date=end_date,
        transaction_type=transaction_type,
        category_id=category_id,
        search=search,
        min_amount=min_amount,
        max_amount=max_amount,
        page=page,
        page_size=page_size,
    )


@router.post(
    "",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a personal transaction",
)
def create_transaction(
    request: TransactionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Create a new personal transaction scoped to the current user."""
    tx = TransactionService.create_personal_transaction(
        db=db,
        user=current_user,
        request=request,
    )
    return TransactionResponse.model_validate(tx)


@router.get(
    "/{transaction_id}",
    response_model=TransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="Get personal transaction detail",
)
def get_transaction(
    transaction_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Retrieve details of a single personal transaction."""
    tx = TransactionService.get_personal_transaction(
        db=db,
        user=current_user,
        transaction_id=transaction_id,
    )
    return TransactionResponse.model_validate(tx)


@router.patch(
    "/{transaction_id}",
    response_model=TransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a personal transaction",
)
def update_transaction(
    transaction_id: str,
    request: TransactionUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Update an existing personal transaction."""
    tx = TransactionService.update_personal_transaction(
        db=db,
        user=current_user,
        transaction_id=transaction_id,
        request=request,
    )
    return TransactionResponse.model_validate(tx)


@router.delete(
    "/{transaction_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete a personal transaction",
)
def delete_transaction(
    transaction_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Delete a personal transaction."""
    TransactionService.delete_personal_transaction(
        db=db,
        user=current_user,
        transaction_id=transaction_id,
    )
    return MessageResponse(
        message="Transaction deleted successfully.",
        success=True,
    )
