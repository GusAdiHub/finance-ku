"""Receipt repository for database operations."""
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload
from app.models.receipt import Receipt
from app.models.transaction_item import TransactionItem


class ReceiptRepository:
    """Repository handling all database interactions for Receipt and TransactionItem entities."""

    @staticmethod
    def get_by_id(db: Session, receipt_id: str) -> Optional[Receipt]:
        """Fetch receipt by ID with its items loaded."""
        stmt = (
            select(Receipt)
            .options(selectinload(Receipt.items))
            .where(Receipt.id == receipt_id)
        )
        return db.scalar(stmt)

    @staticmethod
    def get_by_id_for_user(db: Session, receipt_id: str, user_id: str) -> Optional[Receipt]:
        """Fetch receipt by ID owned by user, preventing IDOR."""
        stmt = (
            select(Receipt)
            .options(selectinload(Receipt.items))
            .where(Receipt.id == receipt_id, Receipt.user_id == user_id)
        )
        return db.scalar(stmt)

    @staticmethod
    def create(db: Session, receipt: Receipt) -> Receipt:
        """Persist a new receipt draft record."""
        db.add(receipt)
        db.commit()
        db.refresh(receipt)
        return receipt

    @staticmethod
    def update(db: Session, receipt: Receipt) -> Receipt:
        """Update an existing receipt record."""
        db.commit()
        db.refresh(receipt)
        return receipt

    @staticmethod
    def delete(db: Session, receipt: Receipt) -> None:
        """Delete a receipt record and its items (cascading)."""
        db.delete(receipt)
        db.commit()

    @staticmethod
    def list_by_user(db: Session, user_id: str, limit: int = 20) -> List[Receipt]:
        """List recent receipts uploaded by the user."""
        stmt = (
            select(Receipt)
            .options(selectinload(Receipt.items))
            .where(Receipt.user_id == user_id)
            .order_by(Receipt.created_at.desc())
            .limit(limit)
        )
        return list(db.scalars(stmt).all())
