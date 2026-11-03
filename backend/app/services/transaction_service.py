"""Transaction service layer for managing personal transactions."""
import math
from datetime import datetime
from decimal import Decimal
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.transaction import (
    PaginatedTransactionResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)
from app.services.category_service import CategoryService


class TransactionService:
    """Business logic for personal financial transactions."""

    @classmethod
    def create_personal_transaction(
        cls,
        db: Session,
        user: User,
        request: TransactionCreate,
    ) -> Transaction:
        """Create a new personal transaction scoped to the authenticated user."""
        # Validate that category exists and is accessible to user
        category = CategoryService.get_category_for_user(db, user, request.category_id)

        # Validate category type aligns with transaction type
        if category.type != request.type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Selected category '{category.name}' has type '{category.type}', but transaction type is '{request.type}'.",
            )

        new_transaction = Transaction(
            type=request.type,
            amount=request.amount,
            category_id=category.id,
            transaction_date=request.transaction_date,
            description=request.description.strip() if request.description else None,
            notes=request.notes.strip() if request.notes else None,
            owner_user_id=user.id,
            group_id=None,
            created_by_user_id=user.id,
            input_method=request.input_method,
            receipt_id=request.receipt_id,
        )

        return TransactionRepository.create(db, new_transaction)

    @classmethod
    def get_personal_transaction(
        cls,
        db: Session,
        user: User,
        transaction_id: str,
    ) -> Transaction:
        """Get a personal transaction by ID, ensuring ownership (IDOR prevention)."""
        tx = TransactionRepository.get_personal_transaction(db, transaction_id, user.id)
        if not tx:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found or you do not have permission to view it.",
            )
        return tx

    @classmethod
    def list_personal_transactions(
        cls,
        db: Session,
        user: User,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        transaction_type: Optional[str] = None,
        category_id: Optional[str] = None,
        search: Optional[str] = None,
        min_amount: Optional[Decimal] = None,
        max_amount: Optional[Decimal] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedTransactionResponse:
        """List personal transactions with filtering and pagination."""
        if page < 1:
            page = 1
        if page_size < 1 or page_size > 100:
            page_size = 20

        items, total = TransactionRepository.get_personal_transactions_paginated(
            db=db,
            user_id=user.id,
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

        total_pages = math.ceil(total / page_size) if total > 0 else 1

        return PaginatedTransactionResponse(
            items=[TransactionResponse.model_validate(tx) for tx in items],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )

    @classmethod
    def update_personal_transaction(
        cls,
        db: Session,
        user: User,
        transaction_id: str,
        request: TransactionUpdate,
    ) -> Transaction:
        """Update a personal transaction owned by the user."""
        tx = cls.get_personal_transaction(db, user, transaction_id)

        target_type = request.type if request.type is not None else tx.type

        # Validate category if changed or type changed
        if request.category_id is not None:
            category = CategoryService.get_category_for_user(db, user, request.category_id)
            if category.type != target_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category '{category.name}' has type '{category.type}', incompatible with transaction type '{target_type}'.",
                )
            tx.category_id = category.id
        elif request.type is not None and request.type != tx.type:
            # Type was updated but category was not provided: check current category type
            if tx.category and tx.category.type != target_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Current category '{tx.category.name}' has type '{tx.category.type}', which conflicts with new transaction type '{target_type}'. Please specify a compatible category_id.",
                )

        if request.type is not None:
            tx.type = request.type

        if request.amount is not None:
            tx.amount = request.amount

        if request.transaction_date is not None:
            tx.transaction_date = request.transaction_date

        if request.description is not None:
            tx.description = request.description.strip() if request.description else None

        if request.notes is not None:
            tx.notes = request.notes.strip() if request.notes else None

        return TransactionRepository.update(db, tx)

    @classmethod
    def delete_personal_transaction(
        cls,
        db: Session,
        user: User,
        transaction_id: str,
    ) -> None:
        """Delete a personal transaction owned by the user."""
        tx = cls.get_personal_transaction(db, user, transaction_id)
        TransactionRepository.delete(db, tx)
