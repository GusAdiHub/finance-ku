"""Financial reports endpoints."""
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.report import PersonalReportResponse
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get(
    "/personal",
    response_model=PersonalReportResponse,
    status_code=status.HTTP_200_OK,
    summary="Get personal financial report",
)
def get_personal_report(
    start_date: Optional[datetime] = Query(None, description="Start date of report period (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date of report period (UTC)"),
    period: str = Query("monthly", description="Report interval label ('monthly', 'yearly', 'daily', 'custom')"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> PersonalReportResponse:
    """Generate a detailed financial report including savings rate, breakdowns, and monthly trends."""
    now = datetime.now(timezone.utc)
    if not end_date:
        end_date = now
    if not start_date:
        if period == "yearly":
            start_date = datetime(end_date.year, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
        elif period == "weekly":
            start_date = end_date - timedelta(days=7)
        elif period == "daily":
            start_date = datetime(end_date.year, end_date.month, end_date.day, 0, 0, 0, tzinfo=timezone.utc)
        else:
            # Default to beginning of the current month
            start_date = datetime(end_date.year, end_date.month, 1, 0, 0, 0, tzinfo=timezone.utc)

    return ReportService.get_personal_report(
        db=db,
        user=current_user,
        start_date=start_date,
        end_date=end_date,
        period_name=period,
    )
