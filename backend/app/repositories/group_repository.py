"""Group, Membership, and Invitation repository for database operations."""
from datetime import datetime, timezone
from typing import List, Optional, Tuple
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload
from app.models.finance_group import FinanceGroup
from app.models.group_invitation import GroupInvitation
from app.models.group_member import GroupMember


class GroupRepository:
    """Repository handling all database interactions for FinanceGroup and related entities."""

    # -------------------------------------------------------------------------
    # Group Operations
    # -------------------------------------------------------------------------

    @staticmethod
    def get_by_id(db: Session, group_id: str) -> Optional[FinanceGroup]:
        """Fetch a group by ID."""
        stmt = select(FinanceGroup).where(FinanceGroup.id == group_id)
        return db.scalar(stmt)

    @staticmethod
    def create(db: Session, group: FinanceGroup) -> FinanceGroup:
        """Persist a new finance group."""
        db.add(group)
        db.commit()
        db.refresh(group)
        return group

    @staticmethod
    def update(db: Session, group: FinanceGroup) -> FinanceGroup:
        """Commit updates to an existing group."""
        db.commit()
        db.refresh(group)
        return group

    @staticmethod
    def get_user_groups_with_role(
        db: Session,
        user_id: str,
    ) -> List[Tuple[FinanceGroup, str, int]]:
        """Fetch all groups where user is an active member, along with their role and member count."""
        # Find active memberships for the user
        member_stmt = (
            select(GroupMember.group_id, GroupMember.role)
            .where(
                GroupMember.user_id == user_id,
                GroupMember.is_active.is_(True),
            )
        )
        user_memberships = db.execute(member_stmt).all()
        if not user_memberships:
            return []

        group_roles = {row.group_id: row.role for row in user_memberships}
        group_ids = list(group_roles.keys())

        # Fetch groups and count active members
        groups_stmt = (
            select(
                FinanceGroup,
                func.count(GroupMember.id).label("members_count"),
            )
            .outerjoin(
                GroupMember,
                (GroupMember.group_id == FinanceGroup.id) & (GroupMember.is_active.is_(True)),
            )
            .where(
                FinanceGroup.id.in_(group_ids),
                FinanceGroup.is_active.is_(True),
            )
            .group_by(FinanceGroup.id)
            .order_by(FinanceGroup.created_at.desc())
        )
        results = db.execute(groups_stmt).all()

        return [
            (row[0], group_roles.get(row[0].id, "member"), int(row[1]))
            for row in results
        ]

    # -------------------------------------------------------------------------
    # Member Operations
    # -------------------------------------------------------------------------

    @staticmethod
    def get_member(
        db: Session,
        group_id: str,
        user_id: str,
        active_only: bool = True,
    ) -> Optional[GroupMember]:
        """Fetch membership association for a user in a specific group."""
        stmt = (
            select(GroupMember)
            .options(selectinload(GroupMember.user))
            .where(
                GroupMember.group_id == group_id,
                GroupMember.user_id == user_id,
            )
        )
        if active_only:
            stmt = stmt.where(GroupMember.is_active.is_(True))
        return db.scalar(stmt)

    @staticmethod
    def get_member_by_id(db: Session, member_id: str) -> Optional[GroupMember]:
        """Fetch a group member by member association primary key ID."""
        stmt = (
            select(GroupMember)
            .options(selectinload(GroupMember.user))
            .where(GroupMember.id == member_id)
        )
        return db.scalar(stmt)

    @staticmethod
    def get_active_members(db: Session, group_id: str) -> List[GroupMember]:
        """Fetch all active members of a group with user details."""
        stmt = (
            select(GroupMember)
            .options(selectinload(GroupMember.user))
            .where(
                GroupMember.group_id == group_id,
                GroupMember.is_active.is_(True),
            )
            .order_by(GroupMember.joined_at.asc())
        )
        return list(db.scalars(stmt).all())

    @staticmethod
    def count_active_members(db: Session, group_id: str) -> int:
        """Count active members in a group."""
        stmt = select(func.count(GroupMember.id)).where(
            GroupMember.group_id == group_id,
            GroupMember.is_active.is_(True),
        )
        return db.scalar(stmt) or 0

    @staticmethod
    def add_member(db: Session, member: GroupMember) -> GroupMember:
        """Persist a new or reactivated group membership."""
        db.add(member)
        db.commit()
        db.refresh(member)
        return member

    @staticmethod
    def update_member(db: Session, member: GroupMember) -> GroupMember:
        """Commit updates to a group membership."""
        db.commit()
        db.refresh(member)
        return member

    # -------------------------------------------------------------------------
    # Invitation Operations
    # -------------------------------------------------------------------------

    @staticmethod
    def create_invitation(db: Session, invitation: GroupInvitation) -> GroupInvitation:
        """Persist a new group invitation."""
        db.add(invitation)
        db.commit()
        db.refresh(invitation)
        return invitation

    @staticmethod
    def get_invitation_by_id(db: Session, invitation_id: str) -> Optional[GroupInvitation]:
        """Fetch invitation by primary key ID."""
        stmt = select(GroupInvitation).where(GroupInvitation.id == invitation_id)
        return db.scalar(stmt)

    @staticmethod
    def get_invitation_by_code_hash(db: Session, code_hash: str) -> Optional[GroupInvitation]:
        """Fetch invitation matching hashed code."""
        stmt = select(GroupInvitation).where(GroupInvitation.code_hash == code_hash)
        return db.scalar(stmt)

    @staticmethod
    def get_active_invitations_for_group(db: Session, group_id: str) -> List[GroupInvitation]:
        """Fetch active invitations for a group."""
        now_naive = datetime.now(timezone.utc).replace(tzinfo=None)
        stmt = (
            select(GroupInvitation)
            .where(
                GroupInvitation.group_id == group_id,
                GroupInvitation.is_revoked.is_(False),
                GroupInvitation.expires_at > now_naive,
                GroupInvitation.uses_count < GroupInvitation.max_uses,
            )
            .order_by(GroupInvitation.created_at.desc())
        )
        return list(db.scalars(stmt).all())

    @staticmethod
    def update_invitation(db: Session, invitation: GroupInvitation) -> GroupInvitation:
        """Commit updates to an invitation."""
        db.commit()
        db.refresh(invitation)
        return invitation
