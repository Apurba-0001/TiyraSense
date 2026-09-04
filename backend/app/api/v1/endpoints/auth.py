from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.api.deps import get_current_user, require_role
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from backend.app.models.user import User, UserRole
from backend.app.schemas.auth import TokenResponse, UserCreate, UserLogin, UserOut, RegistrationRole

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: UserLogin,
    db: AsyncSession = Depends(get_db_session),
):
    """Authenticate credentials and issue a signed Bearer JWT token with role claims."""
    stmt = select(User).where(User.email == login_data.email.lower().strip())
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=settings.AUTH_ACCESS_TOKEN_EXPIRE_MINUTES)
    token = create_access_token(
        subject=user.id,
        role=user.role.value,
        expires_delta=access_token_expires,
    )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in_seconds=settings.AUTH_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
async def get_my_profile(current_user: User = Depends(get_current_user)):
    """Retrieve authenticated profile details."""
    return UserOut.model_validate(current_user)


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db_session),
):
    """Register a new user account.

    Only DRIVER and FIELD_WORKER are accepted via this endpoint — enforced
    at the schema level by RegistrationRole.  OFFICIAL and ADMIN roles can
    only be assigned directly in the database by an administrator.
    """
    stmt = select(User).where(User.email == user_in.email.lower().strip())
    existing_user = (await db.execute(stmt)).scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email address already exists",
        )

    # Map RegistrationRole → UserRole for the database column
    db_role = UserRole(user_in.role.value)

    new_user = User(
        email=user_in.email.lower().strip(),
        password_hash=get_password_hash(user_in.password),
        full_name=user_in.full_name.strip(),
        role=db_role,
        phone_number=user_in.phone_number,
        organization=user_in.organization,
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return UserOut.model_validate(new_user)


@router.get("/official-access")
async def verify_official_access(
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
):
    """Test endpoint: requires OFFICIAL or ADMIN role; returns 403 for DRIVER or FIELD_WORKER."""
    return {
        "access": "granted",
        "role": current_user.role,
        "message": "Authorized for Official Operations Dashboard.",
    }


@router.get("/admin-access")
async def verify_admin_access(
    current_user: User = Depends(require_role([UserRole.ADMIN])),
):
    """Test endpoint: requires ADMIN role; returns 403 for any non-admin role."""
    return {
        "access": "granted",
        "role": current_user.role,
        "message": "Authorized for Admin Governance Dashboard.",
    }
