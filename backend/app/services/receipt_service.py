"""Receipt service handling upload, OCR processing, review, and transaction confirmation."""
import os
import uuid
from datetime import datetime, date
from decimal import Decimal
from typing import Any, Dict, List, Optional
from fastapi import UploadFile, HTTPException, status
from sqlalchemy.orm import Session

from app.models.receipt import Receipt
from app.models.transaction import Transaction
from app.models.transaction_item import TransactionItem
from app.models.user import User
from app.repositories.receipt_repository import ReceiptRepository
from app.repositories.category_repository import CategoryRepository
from app.repositories.group_repository import GroupRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.receipt import ReceiptConfirmRequest
from app.services.ocr_service import OCRService


def _make_json_serializable(data: Any) -> Any:
    """Recursively convert Decimal, datetime/date, and other types into JSON-serializable primitives."""
    if isinstance(data, dict):
        return {k: _make_json_serializable(v) for k, v in data.items()}
    elif isinstance(data, (list, tuple, set)):
        return [_make_json_serializable(v) for v in data]
    elif isinstance(data, Decimal):
        return float(data) if data % 1 else int(data)
    elif isinstance(data, (datetime, date)):
        return data.isoformat()
    return data


class ReceiptService:
    """Business logic for receipt scanning, OCR extraction, and conversion to transactions."""

    @classmethod
    def upload_and_process_receipt(
        cls,
        db: Session,
        file: UploadFile,
        user_id: str,
        group_id: Optional[str] = None,
        merchant_name: Optional[str] = None,
    ) -> Receipt:
        """Upload receipt image, run OCR extraction, and store draft receipt record."""
        # 1. Validate target group membership if group_id is supplied
        if group_id:
            membership = GroupRepository.get_member(db, group_id, user_id)
            if not membership or not membership.is_active:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Anda bukan anggota aktif dalam grup keluarga ini.",
                )

        # 2. Validate file and save to private storage
        file_path, file_name, file_size, mime_type = OCRService.validate_and_save_receipt_image(file)

        # 3. Perform OCR
        raw_text = OCRService.perform_ocr(file_path)

        # 4. Parse Indonesian receipt information
        parsed_data = OCRService.parse_receipt_text(raw_text)

        # User-supplied merchant name takes precedence over raw OCR extraction
        user_merchant = merchant_name.strip() if merchant_name and merchant_name.strip() else None

        # 5. Create Receipt ORM instance
        receipt_id = str(uuid.uuid4())
        receipt = Receipt(
            id=receipt_id,
            user_id=user_id,
            group_id=group_id,
            file_path=file_path,
            file_name=file_name,
            file_size=file_size,
            mime_type=mime_type,
            merchant_name=user_merchant or parsed_data.get("merchant_name"),
            receipt_date=parsed_data.get("receipt_date"),
            total_amount=parsed_data.get("total_amount"),
            raw_ocr_data=_make_json_serializable(parsed_data),
            status="draft",
        )

        db.add(receipt)
        db.flush()

        # 6. Create line items if any were extracted
        extracted_items = parsed_data.get("items", [])
        for item_data in extracted_items:
            item = TransactionItem(
                id=str(uuid.uuid4()),
                receipt_id=receipt_id,
                transaction_id=None,
                item_name=item_data["item_name"],
                quantity=item_data.get("quantity", Decimal("1.00")),
                price_per_unit=item_data.get("price_per_unit", Decimal("0.00")),
                total_price=item_data.get("total_price", Decimal("0.00")),
            )
            db.add(item)

        db.commit()
        db.refresh(receipt)
        return receipt

    @classmethod
    def get_receipt(cls, db: Session, receipt_id: str, user_id: str) -> Receipt:
        """Fetch receipt draft with IDOR protection."""
        receipt = ReceiptRepository.get_by_id(db, receipt_id)
        if not receipt:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Struk tidak ditemukan.",
            )

        # Authorization: user must be the uploader or an active member of the target group
        if receipt.user_id != user_id:
            if not receipt.group_id or not GroupRepository.get_member(db, receipt.group_id, user_id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Anda tidak memiliki izin untuk melihat struk ini.",
                )

        return receipt

    @classmethod
    def confirm_receipt_transaction(
        cls,
        db: Session,
        receipt_id: str,
        user: User,
        payload: ReceiptConfirmRequest,
    ) -> Transaction:
        """Review and confirm receipt draft into a formal financial transaction."""
        receipt = cls.get_receipt(db, receipt_id, user.id)

        if receipt.status == "confirmed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Struk ini sudah pernah dikonfirmasi sebelumnya.",
            )

        # Validate category exists
        category = CategoryRepository.get_by_id(db, payload.category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kategori yang dipilih tidak valid.",
            )

        # Determine scope: personal vs family
        target_group_id: Optional[str] = None
        target_owner_user_id: Optional[str] = None

        if payload.target_scope == "family":
            target_group_id = payload.group_id or receipt.group_id
            if not target_group_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Harap tentukan grup keluarga tujuan untuk pencatatan transaksi.",
                )
            membership = GroupRepository.get_member(db, target_group_id, user.id)
            if not membership or not membership.is_active:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Anda bukan anggota aktif dalam grup keluarga ini.",
                )
        else:
            target_owner_user_id = user.id

        # Determine transaction description
        merchant = payload.merchant_name or receipt.merchant_name
        description = payload.description or (f"Belanja di {merchant}" if merchant else "Pembayaran struk belanja")

        # Determine transaction date
        tx_date = payload.transaction_date or receipt.receipt_date or datetime.now()

        # Create Transaction record
        tx_id = str(uuid.uuid4())
        notes_text = (
            payload.notes.strip()
            if payload.notes and payload.notes.strip()
            else f"Dibuat dari struk {receipt.file_name}"
        )
        transaction = Transaction(
            id=tx_id,
            type="expense",
            amount=payload.total_amount,
            category_id=payload.category_id,
            transaction_date=tx_date,
            description=description,
            notes=notes_text,
            owner_user_id=target_owner_user_id,
            group_id=target_group_id,
            created_by_user_id=user.id,
            input_method="ocr",
            receipt_id=receipt.id,
        )
        db.add(transaction)

        # Update receipt record
        receipt.status = "confirmed"
        if payload.merchant_name:
            receipt.merchant_name = payload.merchant_name
        receipt.total_amount = payload.total_amount
        receipt.receipt_date = tx_date
        receipt.group_id = target_group_id

        # Update or create line items
        if payload.items is not None:
            # Remove previous draft items
            for old_item in receipt.items:
                db.delete(old_item)
            db.flush()

            # Insert confirmed line items
            for item_in in payload.items:
                qty = item_in.quantity or Decimal("1.00")
                unit_price = item_in.price_per_unit or Decimal("0.00")
                total_p = item_in.total_price if item_in.total_price is not None else (qty * unit_price)

                new_item = TransactionItem(
                    id=str(uuid.uuid4()),
                    transaction_id=tx_id,
                    receipt_id=receipt.id,
                    item_name=item_in.item_name,
                    quantity=qty,
                    price_per_unit=unit_price,
                    total_price=total_p,
                )
                db.add(new_item)
        else:
            # Link existing receipt items to the new transaction
            for item in receipt.items:
                item.transaction_id = tx_id

        db.commit()
        db.refresh(transaction)
        return transaction

    @classmethod
    def delete_receipt(cls, db: Session, receipt_id: str, user_id: str) -> None:
        """Delete receipt draft and remove image file from disk."""
        receipt = cls.get_receipt(db, receipt_id, user_id)

        # Only uploader can delete their receipt draft
        if receipt.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Anda tidak memiliki hak untuk menghapus struk ini.",
            )

        # Remove image from storage if present
        if receipt.file_path and os.path.exists(receipt.file_path):
            try:
                os.remove(receipt.file_path)
            except OSError:
                pass

        ReceiptRepository.delete(db, receipt)

    @classmethod
    def list_user_receipts(cls, db: Session, user_id: str, limit: int = 20) -> List[Receipt]:
        """List user's uploaded receipts."""
        return ReceiptRepository.list_by_user(db, user_id, limit)
