"""Voice input and speech-to-transaction parsing API endpoints."""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.voice import VoiceParseRequest, VoiceParseResponse
from app.services.voice_service import VoiceService

router = APIRouter(prefix="/voice", tags=["Voice Input"])


@router.post(
    "/parse",
    response_model=VoiceParseResponse,
    status_code=status.HTTP_200_OK,
    summary="Parse Indonesian speech transcript into transaction draft",
)
def parse_voice_transaction(
    payload: VoiceParseRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> VoiceParseResponse:
    """Parse spoken text in Indonesian into financial parameters (amount, type, category, description)."""
    parsed = VoiceService.parse_voice_text(
        text=payload.text,
        db=db,
        user_id=current_user.id,
    )
    return VoiceParseResponse(**parsed)
