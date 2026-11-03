"""Group service layer managing family finance groups, memberships, and invitations."""
import hashlib
import secrets
import string
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.finance_group import FinanceGroup
from app.models.group_invitation import GroupInvitation
from app.models.group_member import GroupMember
from app.models.user import User
from app.repositories.group_repository import GroupRepository
from app.schemas.group import (
    GroupCreate,
    GroupMemberResponse,
    GroupResponse,
    GroupUpdate,
    InvitationCreateRequest,
    UpdateMemberRoleRequest,
)


class GroupService:
    """Business logic for Family Finance groups and memberships."""

    @classmethod
    def create_group(
        cls,
        db: Session,
        user: User,
        request: GroupCreate,
    ) -> FinanceGroup:
        """Create a new family finance group and designate creator as owner."""
        group = FinanceGroup(
            name=request.name.strip(),
            description=request.description.strip() if request.description else None,
            created_by_user_id=user.id,
            is_active=True,
        )
        created_group = GroupRepository.create(db, group)

        # Automatically add creator as owner
        owner_member = GroupMember(
            group_id=created_group.id,
            user_id=user.id,
            role="owner",
            is_active=True,
        )
        GroupRepository.add_member(db, owner_member)

        return created_group

    @classmethod
    def get_user_groups(
        cls,
        db: Session,
        user: User,
    ) -> List[GroupResponse]:
        """List all groups where user is an active member."""
        results = GroupRepository.get_user_groups_with_role(db, user.id)

        # Auto-migrate legacy "Keluarga Cemara" group names to event format
        for group, role, count in results:
            if "Cemara" in (group.name or "") or "Keluarga Cemara" in (group.name or ""):
                group.name = "Panitia Event & Proyek"
                if not group.description or "Cemara" in group.description:
                    group.description = "[ANGGARAN:10000000] Kas operasional dan bukti nota belanja panitia event"
                GroupRepository.update(db, group)

        return [
            GroupResponse(
                id=group.id,
                name=group.name,
                description=group.description,
                created_by_user_id=group.created_by_user_id,
                is_active=group.is_active,
                created_at=group.created_at,
                updated_at=group.updated_at,
                user_role=role,
                members_count=count,
            )
            for group, role, count in results
        ]

    @classmethod
    def get_group_detail(
        cls,
        db: Session,
        user: User,
        group_id: str,
    ) -> GroupResponse:
        """Fetch group details ensuring user is an active member."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found or you are not an active member.",
            )

        group = GroupRepository.get_by_id(db, group_id)
        if not group or not group.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found.",
            )

        # Auto-migrate legacy name if accessed directly
        if "Cemara" in (group.name or "") or "Keluarga Cemara" in (group.name or ""):
            group.name = "Panitia Event & Proyek"
            if not group.description or "Cemara" in group.description:
                group.description = "[ANGGARAN:10000000] Kas operasional dan bukti nota belanja panitia event"
            GroupRepository.update(db, group)

        count = GroupRepository.count_active_members(db, group_id)

        return GroupResponse(
            id=group.id,
            name=group.name,
            description=group.description,
            created_by_user_id=group.created_by_user_id,
            is_active=group.is_active,
            created_at=group.created_at,
            updated_at=group.updated_at,
            user_role=membership.role,
            members_count=count,
        )

    @classmethod
    def update_group(
        cls,
        db: Session,
        user: User,
        group_id: str,
        request: GroupUpdate,
    ) -> GroupResponse:
        """Update group name or description (owner or admin only)."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found.",
            )

        if membership.role not in ("owner", "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the group owner or an admin can update group settings.",
            )

        group = GroupRepository.get_by_id(db, group_id)
        if not group or not group.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found.",
            )

        if request.name is not None and request.name.strip():
            group.name = request.name.strip()
        if request.description is not None:
            group.description = request.description.strip() if request.description else None

        updated = GroupRepository.update(db, group)
        count = GroupRepository.count_active_members(db, group_id)

        return GroupResponse(
            id=updated.id,
            name=updated.name,
            description=updated.description,
            created_by_user_id=updated.created_by_user_id,
            is_active=updated.is_active,
            created_at=updated.created_at,
            updated_at=updated.updated_at,
            user_role=membership.role,
            members_count=count,
        )

    @classmethod
    def delete_group(
        cls,
        db: Session,
        user: User,
        group_id: str,
    ) -> None:
        """Soft-delete a group (owner only)."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership or membership.role != "owner":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the group owner can delete the group.",
            )

        group = GroupRepository.get_by_id(db, group_id)
        if not group or not group.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found.",
            )

        group.is_active = False
        GroupRepository.update(db, group)

    @classmethod
    def list_members(
        cls,
        db: Session,
        user: User,
        group_id: str,
    ) -> List[GroupMemberResponse]:
        """List active members of a group (accessible by any active member)."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found or you are not an active member.",
            )

        members = GroupRepository.get_active_members(db, group_id)
        return [
            GroupMemberResponse(
                id=m.id,
                user_id=m.user_id,
                user_name=m.user.name if m.user else "Unknown",
                user_email=m.user.email if m.user else "",
                role=m.role,
                joined_at=m.joined_at,
                is_active=m.is_active,
            )
            for m in members
        ]

    @classmethod
    def update_member_role(
        cls,
        db: Session,
        user: User,
        group_id: str,
        member_id: str,
        request: UpdateMemberRoleRequest,
    ) -> GroupMemberResponse:
        """Modify a member's role (owner only)."""
        caller_membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not caller_membership or caller_membership.role != "owner":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the group owner can modify member roles.",
            )

        target_member = GroupRepository.get_member_by_id(db, member_id)
        if not target_member or target_member.group_id != group_id or not target_member.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group member not found.",
            )

        if target_member.role == "owner":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Owner role cannot be modified with this endpoint.",
            )

        target_member.role = request.role
        updated = GroupRepository.update_member(db, target_member)

        return GroupMemberResponse(
            id=updated.id,
            user_id=updated.user_id,
            user_name=updated.user.name if updated.user else "Unknown",
            user_email=updated.user.email if updated.user else "",
            role=updated.role,
            joined_at=updated.joined_at,
            is_active=updated.is_active,
        )

    @classmethod
    def remove_member(
        cls,
        db: Session,
        user: User,
        group_id: str,
        member_id: str,
    ) -> None:
        """Remove a member from the group (owner or admin only)."""
        caller_membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not caller_membership or caller_membership.role not in ("owner", "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group owner or admin can remove members.",
            )

        target_member = GroupRepository.get_member_by_id(db, member_id)
        if not target_member or target_member.group_id != group_id or not target_member.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group member not found.",
            )

        # Cannot remove owner
        if target_member.role == "owner":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="The group owner cannot be removed.",
            )

        # Admin cannot remove another admin or owner
        if caller_membership.role == "admin" and target_member.role == "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="An admin cannot remove another admin.",
            )

        target_member.is_active = False
        GroupRepository.update_member(db, target_member)

    @classmethod
    def leave_group(
        cls,
        db: Session,
        user: User,
        group_id: str,
    ) -> None:
        """Allow a member to leave a group."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="You are not an active member of this group.",
            )

        if membership.role == "owner":
            active_count = GroupRepository.count_active_members(db, group_id)
            if active_count > 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Owner cannot leave the group while other active members exist. Please transfer ownership first.",
                )
            # If owner is sole member, deactivating group as well
            group = GroupRepository.get_by_id(db, group_id)
            if group:
                group.is_active = False
                GroupRepository.update(db, group)

        membership.is_active = False
        GroupRepository.update_member(db, membership)

    # -------------------------------------------------------------------------
    # Invitation Methods
    # -------------------------------------------------------------------------

    @classmethod
    def create_invitation(
        cls,
        db: Session,
        user: User,
        group_id: str,
        request: InvitationCreateRequest,
    ) -> Tuple[GroupInvitation, str]:
        """Generate a random invitation code and store its cryptographic hash."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership or membership.role not in ("owner", "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group owner or admin can generate invitation codes.",
            )

        # Generate a random 8-character uppercase alphanumeric code
        alphabet = string.ascii_uppercase + string.digits
        raw_code = "".join(secrets.choice(alphabet) for _ in range(8))
        code_hash = hashlib.sha256(raw_code.encode("utf-8")).hexdigest()

        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(days=request.expires_in_days)

        invitation = GroupInvitation(
            group_id=group_id,
            created_by_user_id=user.id,
            code_hash=code_hash,
            expires_at=expires_at,
            max_uses=request.max_uses,
            uses_count=0,
            is_revoked=False,
        )
        saved = GroupRepository.create_invitation(db, invitation)
        return saved, raw_code

    @classmethod
    def list_invitations(
        cls,
        db: Session,
        user: User,
        group_id: str,
    ) -> List[GroupInvitation]:
        """List active invitations for a group (owner/admin only)."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership or membership.role not in ("owner", "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group owner or admin can view invitation codes.",
            )
        return GroupRepository.get_active_invitations_for_group(db, group_id)

    @classmethod
    def revoke_invitation(
        cls,
        db: Session,
        user: User,
        group_id: str,
        invitation_id: str,
    ) -> None:
        """Revoke an active invitation code."""
        membership = GroupRepository.get_member(db, group_id, user.id, active_only=True)
        if not membership or membership.role not in ("owner", "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group owner or admin can revoke invitations.",
            )

        invitation = GroupRepository.get_invitation_by_id(db, invitation_id)
        if not invitation or invitation.group_id != group_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found.",
            )

        invitation.is_revoked = True
        GroupRepository.update_invitation(db, invitation)

    @classmethod
    def join_group_with_code(
        cls,
        db: Session,
        user: User,
        raw_code: str,
    ) -> FinanceGroup:
        """Join a group using an active, unexpired, unrevoked invitation code."""
        clean_code = raw_code.strip().upper()
        code_hash = hashlib.sha256(clean_code.encode("utf-8")).hexdigest()

        invitation = GroupRepository.get_invitation_by_code_hash(db, code_hash)
        now = datetime.now(timezone.utc)

        if (
            not invitation
            or invitation.is_revoked
            or invitation.expires_at <= now
            or invitation.uses_count >= invitation.max_uses
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid, expired, or fully utilized invitation code.",
            )

        # Check existing membership
        existing_membership = GroupRepository.get_member(
            db,
            invitation.group_id,
            user.id,
            active_only=False,
        )

        if existing_membership and existing_membership.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already an active member of this group.",
            )

        if existing_membership:
            # Reactivate membership
            existing_membership.is_active = True
            existing_membership.role = "member"
            existing_membership.joined_at = now
            GroupRepository.update_member(db, existing_membership)
        else:
            # Create new membership
            new_member = GroupMember(
                group_id=invitation.group_id,
                user_id=user.id,
                role="member",
                is_active=True,
            )
            GroupRepository.add_member(db, new_member)

        # Increment uses count
        invitation.uses_count += 1
        GroupRepository.update_invitation(db, invitation)

        group = GroupRepository.get_by_id(db, invitation.group_id)
        if not group:
            raise HTTPException(status_code=404, detail="Group not found.")
        return group
