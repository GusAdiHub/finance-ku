"""Family Finance endpoints: groups, members, invitations, shared transactions, dashboard, and reports."""
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import List, Literal, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_active_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.group import (
    GroupCreate,
    GroupDashboardResponse,
    GroupMemberResponse,
    GroupReportResponse,
    GroupResponse,
    GroupUpdate,
    InvitationCreateRequest,
    InvitationResponse,
    JoinGroupRequest,
    UpdateMemberRoleRequest,
)
from app.schemas.transaction import (
    PaginatedTransactionResponse,
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)
from app.services.group_service import GroupService
from app.services.group_transaction_service import GroupTransactionService

router = APIRouter(prefix="/groups", tags=["Family Finance Groups"])


# ---------------------------------------------------------------------------
# Group Management Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "",
    response_model=GroupResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new family finance group",
)
def create_group(
    request: GroupCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    """Create a new shared family group. Creator automatically becomes owner."""
    group = GroupService.create_group(db, current_user, request)
    return GroupResponse(
        id=group.id,
        name=group.name,
        description=group.description,
        created_by_user_id=group.created_by_user_id,
        is_active=group.is_active,
        created_at=group.created_at,
        updated_at=group.updated_at,
        user_role="owner",
        members_count=1,
    )


@router.get(
    "",
    response_model=List[GroupResponse],
    status_code=status.HTTP_200_OK,
    summary="List all groups current user belongs to",
)
def list_user_groups(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[GroupResponse]:
    """Retrieve all family groups where the current user is an active member."""
    return GroupService.get_user_groups(db, current_user)


@router.post(
    "/join",
    response_model=GroupResponse,
    status_code=status.HTTP_200_OK,
    summary="Join a family group using invitation code",
)
def join_group(
    request: JoinGroupRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    """Join a family finance group with a valid, active invitation code."""
    group = GroupService.join_group_with_code(db, current_user, request.code)
    return GroupService.get_group_detail(db, current_user, group.id)


@router.get(
    "/{group_id}",
    response_model=GroupResponse,
    status_code=status.HTTP_200_OK,
    summary="Get family group details",
)
def get_group_detail(
    group_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    """Retrieve details for a specific group."""
    return GroupService.get_group_detail(db, current_user, group_id)


@router.patch(
    "/{group_id}",
    response_model=GroupResponse,
    status_code=status.HTTP_200_OK,
    summary="Update family group details (owner/admin only)",
)
def update_group(
    group_id: str,
    request: GroupUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    """Update group name or description."""
    return GroupService.update_group(db, current_user, group_id, request)


@router.delete(
    "/{group_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete a family/event group (owner only)",
)
def delete_group(
    group_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Soft-delete a group and deactivate it."""
    GroupService.delete_group(db, current_user, group_id)
    return MessageResponse(
        message="Group deleted successfully.",
        success=True,
    )


@router.post(
    "/{group_id}/leave",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Leave a family group",
)
def leave_group(
    group_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Leave a family group."""
    GroupService.leave_group(db, current_user, group_id)
    return MessageResponse(
        message="You have successfully left the group.",
        success=True,
    )


# ---------------------------------------------------------------------------
# Group Members Endpoints
# ---------------------------------------------------------------------------

@router.get(
    "/{group_id}/members",
    response_model=List[GroupMemberResponse],
    status_code=status.HTTP_200_OK,
    summary="List active members of a family group",
)
def list_group_members(
    group_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[GroupMemberResponse]:
    """Retrieve active members of the group."""
    return GroupService.list_members(db, current_user, group_id)


@router.patch(
    "/{group_id}/members/{member_id}",
    response_model=GroupMemberResponse,
    status_code=status.HTTP_200_OK,
    summary="Change a member's role (owner only)",
)
def update_member_role(
    group_id: str,
    member_id: str,
    request: UpdateMemberRoleRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupMemberResponse:
    """Promote or demote a member's role (admin or member)."""
    return GroupService.update_member_role(db, current_user, group_id, member_id, request)


@router.delete(
    "/{group_id}/members/{member_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Remove a member from group (owner or admin only)",
)
def remove_group_member(
    group_id: str,
    member_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Remove a member from the group."""
    GroupService.remove_member(db, current_user, group_id, member_id)
    return MessageResponse(
        message="Member removed successfully.",
        success=True,
    )


# ---------------------------------------------------------------------------
# Group Invitations Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/{group_id}/invitations",
    response_model=InvitationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create invitation code (owner/admin only)",
)
def create_invitation(
    group_id: str,
    request: InvitationCreateRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InvitationResponse:
    """Generate a random invitation code for joining this group."""
    invitation, raw_code = GroupService.create_invitation(db, current_user, group_id, request)
    return InvitationResponse(
        id=invitation.id,
        group_id=invitation.group_id,
        code=raw_code,
        expires_at=invitation.expires_at,
        max_uses=invitation.max_uses,
        uses_count=invitation.uses_count,
        is_revoked=invitation.is_revoked,
        created_at=invitation.created_at,
    )


@router.get(
    "/{group_id}/invitations",
    response_model=List[InvitationResponse],
    status_code=status.HTTP_200_OK,
    summary="List active invitations for group (owner/admin only)",
)
def list_invitations(
    group_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[InvitationResponse]:
    """Retrieve active invitations."""
    invitations = GroupService.list_invitations(db, current_user, group_id)
    return [InvitationResponse.model_validate(inv) for inv in invitations]


@router.delete(
    "/{group_id}/invitations/{invitation_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke an invitation code (owner/admin only)",
)
def revoke_invitation(
    group_id: str,
    invitation_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Revoke an invitation code."""
    GroupService.revoke_invitation(db, current_user, group_id, invitation_id)
    return MessageResponse(
        message="Invitation revoked successfully.",
        success=True,
    )


# ---------------------------------------------------------------------------
# Group Shared Transactions Endpoints
# ---------------------------------------------------------------------------

@router.get(
    "/{group_id}/transactions",
    response_model=PaginatedTransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="List group shared transactions",
)
def list_group_transactions(
    group_id: str,
    start_date: Optional[datetime] = Query(None, description="Start date filter (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date filter (UTC)"),
    transaction_type: Optional[Literal["income", "expense"]] = Query(
        None,
        alias="type",
        description="Filter by type",
    ),
    category_id: Optional[str] = Query(None, description="Filter by category ID"),
    created_by_user_id: Optional[str] = Query(None, description="Filter by member who recorded"),
    search: Optional[str] = Query(None, description="Keyword search in description or notes"),
    min_amount: Optional[Decimal] = Query(None, ge=0, description="Minimum amount filter"),
    max_amount: Optional[Decimal] = Query(None, ge=0, description="Maximum amount filter"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> PaginatedTransactionResponse:
    """List shared transactions in the group with filtering and pagination."""
    return GroupTransactionService.list_group_transactions(
        db=db,
        user=current_user,
        group_id=group_id,
        start_date=start_date,
        end_date=end_date,
        transaction_type=transaction_type,
        category_id=category_id,
        created_by_user_id=created_by_user_id,
        search=search,
        min_amount=min_amount,
        max_amount=max_amount,
        page=page,
        page_size=page_size,
    )


@router.post(
    "/{group_id}/transactions",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a shared group transaction",
)
def create_group_transaction(
    group_id: str,
    request: TransactionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Record a transaction in the group Shared Ledger."""
    tx = GroupTransactionService.create_group_transaction(
        db=db,
        user=current_user,
        group_id=group_id,
        request=request,
    )
    return TransactionResponse.model_validate(tx)


@router.get(
    "/{group_id}/transactions/{transaction_id}",
    response_model=TransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="Get group transaction detail",
)
def get_group_transaction(
    group_id: str,
    transaction_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Retrieve details of a group transaction."""
    tx = GroupTransactionService.get_group_transaction(
        db=db,
        user=current_user,
        group_id=group_id,
        transaction_id=transaction_id,
    )
    return TransactionResponse.model_validate(tx)


@router.patch(
    "/{group_id}/transactions/{transaction_id}",
    response_model=TransactionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a group transaction",
)
def update_group_transaction(
    group_id: str,
    transaction_id: str,
    request: TransactionUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    """Update a group transaction (owners/admins can update any; members only their own)."""
    tx = GroupTransactionService.update_group_transaction(
        db=db,
        user=current_user,
        group_id=group_id,
        transaction_id=transaction_id,
        request=request,
    )
    return TransactionResponse.model_validate(tx)


@router.delete(
    "/{group_id}/transactions/{transaction_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete a group transaction",
)
def delete_group_transaction(
    group_id: str,
    transaction_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Delete a group transaction."""
    GroupTransactionService.delete_group_transaction(
        db=db,
        user=current_user,
        group_id=group_id,
        transaction_id=transaction_id,
    )
    return MessageResponse(
        message="Transaction deleted successfully.",
        success=True,
    )


# ---------------------------------------------------------------------------
# Group Dashboard & Reports Endpoints
# ---------------------------------------------------------------------------

@router.get(
    "/{group_id}/dashboard",
    response_model=GroupDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get group finance dashboard",
)
def get_group_dashboard(
    group_id: str,
    start_date: Optional[datetime] = Query(None, description="Start date filter (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date filter (UTC)"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupDashboardResponse:
    """Retrieve shared dashboard with member contribution metrics."""
    return GroupTransactionService.get_group_dashboard(
        db=db,
        user=current_user,
        group_id=group_id,
        start_date=start_date,
        end_date=end_date,
    )


@router.get(
    "/{group_id}/reports",
    response_model=GroupReportResponse,
    status_code=status.HTTP_200_OK,
    summary="Get group financial report",
)
def get_group_report(
    group_id: str,
    start_date: Optional[datetime] = Query(None, description="Start date (UTC)"),
    end_date: Optional[datetime] = Query(None, description="End date (UTC)"),
    period: str = Query("monthly", description="Report interval label"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GroupReportResponse:
    """Generate comprehensive shared financial report for the family group."""
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
            start_date = datetime(end_date.year, end_date.month, 1, 0, 0, 0, tzinfo=timezone.utc)

    return GroupTransactionService.get_group_report(
        db=db,
        user=current_user,
        group_id=group_id,
        start_date=start_date,
        end_date=end_date,
        period_name=period,
    )
