"""Authentication endpoints: register, login, logout, profile, and change password."""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import (
    get_current_active_user,
    get_current_token,
    get_current_user,
)
from app.database.session import get_db
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    MessageResponse,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
)
from app.schemas.user import UserResponse, UserUpdateRequest
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user account",
)
def register(
    request: UserRegisterRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Register a new user and return an authentication token with user profile."""
    user = AuthService.register(db, request)
    return AuthService.create_token_response(user)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="User login with email and password",
)
def login(
    request: UserLoginRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Authenticate user with email and password and return access token."""
    user = AuthService.authenticate(db, request.email, request.password)
    return AuthService.create_token_response(user)


@router.post(
    "/logout",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke current session token",
)
def logout(
    token: str = Depends(get_current_token),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    """Revoke current access token so it cannot be used again."""
    AuthService.revoke_token(token)
    return MessageResponse(
        message="Successfully logged out.",
        success=True,
    )


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user profile",
)
def get_current_user_profile(
    current_user: User = Depends(get_current_active_user),
) -> UserResponse:
    """Return the profile data of the currently authenticated user."""
    return UserResponse.model_validate(current_user)


@router.patch(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update current user profile",
)
def update_profile(
    request: UserUpdateRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> UserResponse:
    """Update profile information (e.g. name, email) for the current user."""
    updated_user = AuthService.update_profile(db, current_user, request)
    return UserResponse.model_validate(updated_user)


@router.post(
    "/change-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Change account password",
)
def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Change the password of the currently authenticated user."""
    AuthService.change_password(db, current_user, request)
    return MessageResponse(
        message="Password has been changed successfully.",
        success=True,
    )
