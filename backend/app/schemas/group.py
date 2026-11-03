"""Group, Membership, and Invitation Pydantic schemas."""
from datetime import datetime
from decimal import Decimal
from typing import List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.dashboard import CategoryBreakdownItem
from app.schemas.report import MonthlyTrendItem
from app.schemas.transaction import TransactionResponse


class GroupBase(BaseModel):
    """Base schema for finance group."""

    name: str = Field(..., min_length=1, max_length=100, description="Family group name")
    description: Optional[str] = Field(None, description="Optional description of the group")


class GroupCreate(GroupBase):
    """Schema for creating a new family group."""
    pass


class GroupUpdate(BaseModel):
    """Schema for updating group information."""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None


class GroupMemberResponse(BaseModel):
    """Schema for group member information."""

    id: str
    user_id: str
    user_name: str
    user_email: str
    role: Literal["owner", "admin", "member"]
    joined_at: datetime
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class GroupResponse(GroupBase):
    """Schema returned for group details."""

    id: str
    created_by_user_id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    user_role: Optional[Literal["owner", "admin", "member"]] = None
    members_count: int = 1

    model_config = ConfigDict(from_attributes=True)


class UpdateMemberRoleRequest(BaseModel):
    """Schema for modifying a group member's role."""

    role: Literal["admin", "member"] = Field(
        ...,
        description="Target role for the member: 'admin' or 'member'",
    )


class InvitationCreateRequest(BaseModel):
    """Schema for generating a new group invitation code."""

    expires_in_days: int = Field(7, ge=1, le=30, description="Validity period in days (1-30)")
    max_uses: int = Field(1, ge=1, le=100, description="Maximum number of times this code can be used")


class InvitationResponse(BaseModel):
    """Schema for group invitation."""

    id: str
    group_id: str
    code: Optional[str] = None  # Only returned on initial creation
    expires_at: datetime
    max_uses: int
    uses_count: int
    is_revoked: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class JoinGroupRequest(BaseModel):
    """Schema for joining a group using an invitation code."""

    code: str = Field(..., min_length=6, max_length=32, description="Invitation code")


class MemberContributionItem(BaseModel):
    """Summary of financial transactions entered by a specific group member."""

    user_id: str
    user_name: str
    total_expense: Decimal
    total_income: Decimal
    transaction_count: int


class GroupDashboardResponse(BaseModel):
    """Aggregated financial dashboard for a shared family group."""

    group_id: str
    group_name: str
    total_income: Decimal
    total_expense: Decimal
    net_balance: Decimal
    recent_transactions: List[TransactionResponse]
    expense_by_category: List[CategoryBreakdownItem]
    income_by_category: List[CategoryBreakdownItem]
    member_contributions: List[MemberContributionItem]
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None


class GroupReportResponse(BaseModel):
    """Comprehensive financial report for a shared family group."""

    group_id: str
    group_name: str
    period: str
    start_date: datetime
    end_date: datetime
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    savings_rate: float
    expense_by_category: List[CategoryBreakdownItem]
    income_by_category: List[CategoryBreakdownItem]
    monthly_trends: List[MonthlyTrendItem]
    member_contributions: List[MemberContributionItem]
