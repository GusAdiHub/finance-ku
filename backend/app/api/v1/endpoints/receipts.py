"""Receipt management and OCR processing API endpoints."""
from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.receipt import ReceiptConfirmRequest, ReceiptResponse
from app.schemas.transaction import TransactionResponse
from app.services.receipt_service import ReceiptService

router = APIRouter(prefix="/receipts", tags=["Receipts (OCR)"])


@router.post(
    "",
    response_model=ReceiptResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload receipt image and run OCR extraction",
)
def upload_receipt(
    file: UploadFile = File(..., description="Receipt image file (JPEG, PNG, WebP)"),
    group_id: Optional[str] = Form(None, description="Optional target family group ID"),
    merchant_name: Optional[str] = Form(None, description="Optional user-provided merchant or store name"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ReceiptResponse:
    """Upload a physical receipt image, perform OCR parsing, and create a draft receipt."""
    receipt = ReceiptService.upload_and_process_receipt(
        db=db,
        file=file,
        user_id=current_user.id,
        group_id=group_id,
        merchant_name=merchant_name,
    )
    return ReceiptResponse.model_validate(receipt)


@router.get(
    "",
    response_model=List[ReceiptResponse],
    summary="List recent uploaded receipts",
)
def list_receipts(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> List[ReceiptResponse]:
    """Retrieve recent receipts uploaded by the current authenticated user."""
    receipts = ReceiptService.list_user_receipts(db, current_user.id, limit=limit)
    return [ReceiptResponse.model_validate(r) for r in receipts]


@router.get(
    "/{receipt_id}",
    response_model=ReceiptResponse,
    summary="Get receipt draft details and extracted line items",
)
def get_receipt(
    receipt_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ReceiptResponse:
    """Fetch details and OCR breakdown for a specific receipt draft."""
    receipt = ReceiptService.get_receipt(db, receipt_id, current_user.id)
    return ReceiptResponse.model_validate(receipt)


@router.post(
    "/{receipt_id}/confirm",
    response_model=TransactionResponse,
    summary="Confirm receipt draft into an official financial transaction",
)
def confirm_receipt(
    receipt_id: str,
    payload: ReceiptConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> TransactionResponse:
    """Review and confirm receipt data, creating a formal Personal or Family expense transaction."""
    transaction = ReceiptService.confirm_receipt_transaction(
        db=db,
        receipt_id=receipt_id,
        user=current_user,
        payload=payload,
    )
    return TransactionResponse.model_validate(transaction)


@router.delete(
    "/{receipt_id}",
    response_model=MessageResponse,
    summary="Delete a receipt draft and its uploaded file",
)
def delete_receipt(
    receipt_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> MessageResponse:
    """Delete a draft receipt and remove its physical file from storage."""
    ReceiptService.delete_receipt(db, receipt_id, current_user.id)
    return MessageResponse(message="Struk berhasil dihapus.")
