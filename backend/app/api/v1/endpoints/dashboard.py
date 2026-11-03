"""Dashboard endpoints."""
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.dashboard import PersonalDashboardResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get(
    "/personal",
    response_model=PersonalDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get personal finance dashboard",
)
def get_personal_dashboard(
    start_date: Optional[datetime] = Query(None, description="Start date filter (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date filter (UTC)"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> PersonalDashboardResponse:
    """Retrieve summarized statistics, balances, recent transactions, and category breakdowns."""
    return DashboardService.get_personal_dashboard(
        db=db,
        user=current_user,
        start_date=start_date,
        end_date=end_date,
    )
