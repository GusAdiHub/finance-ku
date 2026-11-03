"""Authentication and user management service layer."""
from typing import Set
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    ChangePasswordRequest,
    TokenResponse,
    UserRegisterRequest,
)
from app.schemas.user import UserResponse, UserUpdateRequest


class AuthService:
    """Business logic for user authentication, registration, and profile management."""

    # In-memory revoked tokens store for logout (can be backed by Redis / DB in production)
    _revoked_tokens: Set[str] = set()

    @classmethod
    def register(cls, db: Session, request: UserRegisterRequest) -> User:
        """Register a new user account."""
        normalized_email = request.email.strip().lower()

        # Check for existing user with identical email
        if UserRepository.exists_by_email(db, normalized_email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is already registered.",
            )

        # Hash password and create user
        password_hash = get_password_hash(request.password)
        new_user = User(
            name=request.name.strip(),
            email=normalized_email,
            password_hash=password_hash,
            is_active=True,
        )

        return UserRepository.create(db, new_user)

    @classmethod
    def authenticate(cls, db: Session, email: str, password: str) -> User:
        """Authenticate user credentials and return User if valid and active."""
        normalized_email = email.strip().lower()
        user = UserRepository.get_by_email(db, normalized_email)

        # Constant-time-like rejection for non-existent users
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account has been deactivated. Please contact support.",
            )

        return user

    @classmethod
    def create_token_response(cls, user: User) -> TokenResponse:
        """Generate JWT access token and return TokenResponse with user details."""
        token = create_access_token(subject=user.id, email=user.email)
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=UserResponse.model_validate(user),
        )

    @classmethod
    def change_password(
        cls,
        db: Session,
        user: User,
        request: ChangePasswordRequest,
    ) -> None:
        """Change the password for the current authenticated user."""
        if not verify_password(request.current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect.",
            )

        if request.current_password == request.new_password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be different from current password.",
            )

        user.password_hash = get_password_hash(request.new_password)
        UserRepository.update(db, user)

    @classmethod
    def update_profile(
        cls,
        db: Session,
        user: User,
        request: UserUpdateRequest,
    ) -> User:
        """Update authenticated user profile information."""
        if request.name is not None and request.name.strip():
            user.name = request.name.strip()

        if request.email is not None:
            normalized_email = request.email.strip().lower()
            if normalized_email != user.email:
                if UserRepository.exists_by_email(db, normalized_email):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Email is already taken by another user.",
                    )
                user.email = normalized_email

        return UserRepository.update(db, user)

    @classmethod
    def revoke_token(cls, token: str) -> None:
        """Mark a token as revoked on logout."""
        cls._revoked_tokens.add(token)

    @classmethod
    def is_token_revoked(cls, token: str) -> bool:
        """Check if a token has been revoked."""
        return token in cls._revoked_tokens
