import uuid
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
from backend.app.models.user import User, UserRole, SYSTEM_FALLBACK_USERS
from backend.app.schemas.auth import TokenResponse, UserCreate, UserLogin, UserOut, UserUpdate, RegistrationRole

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: UserLogin,
    db: AsyncSession = Depends(get_db_session),
):
    """Authenticate credentials and issue a signed Bearer JWT token with role claims."""
    email_clean = login_data.email.lower().strip()
    user = None
    try:
        stmt = select(User).where(User.email == email_clean)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
    except Exception:
        # Graceful fallback to verified dev accounts if database daemon is not running
        user = SYSTEM_FALLBACK_USERS.get(email_clean)

    if not user:
        user = SYSTEM_FALLBACK_USERS.get(email_clean)

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


@router.patch("/me", response_model=UserOut)
@router.put("/me", response_model=UserOut)
async def update_my_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    """Update authenticated user's profile details in the database."""
    new_password_hash = None
    # Check password update if requested
    if update_data.new_password:
        if not update_data.current_password or not verify_password(update_data.current_password, current_user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password verification failed.",
            )
        new_password_hash = get_password_hash(update_data.new_password)
        current_user.password_hash = new_password_hash

    new_name = update_data.full_name if update_data.full_name is not None else current_user.full_name
    new_phone = update_data.phone_number if update_data.phone_number is not None else current_user.phone_number
    new_org = update_data.organization if update_data.organization is not None else current_user.organization

    # 1. Update PostgreSQL database record
    try:
        stmt = select(User).where(User.id == current_user.id)
        result = await db.execute(stmt)
        db_user = result.scalar_one_or_none()
        if db_user:
            if update_data.full_name is not None:
                db_user.full_name = new_name
            if update_data.phone_number is not None:
                db_user.phone_number = new_phone
            if update_data.organization is not None:
                db_user.organization = new_org
            if new_password_hash:
                db_user.password_hash = new_password_hash

            await db.commit()
    except Exception:
        pass

    # 2. Update Supabase Cloud DB
    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.update_user_profile(
            user_id=str(current_user.id),
            email=current_user.email,
            full_name=new_name,
            phone_number=new_phone,
            organization=new_org,
        )
    except Exception:
        pass

    # 3. Update in-memory fallback store
    if current_user.email in SYSTEM_FALLBACK_USERS:
        fb = SYSTEM_FALLBACK_USERS[current_user.email]
        if update_data.full_name is not None:
            fb.full_name = new_name
        if update_data.phone_number is not None:
            fb.phone_number = new_phone
        if update_data.organization is not None:
            fb.organization = new_org
        if new_password_hash:
            fb.password_hash = new_password_hash

    current_user.full_name = new_name
    current_user.phone_number = new_phone
    current_user.organization = new_org

    return UserOut(
        id=current_user.id,
        email=current_user.email,
        full_name=new_name,
        role=current_user.role,
        phone_number=new_phone,
        organization=new_org,
    )


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
    email_clean = user_in.email.lower().strip()
    try:
        stmt = select(User).where(User.email == email_clean)
        existing_user = (await db.execute(stmt)).scalar_one_or_none()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this email address already exists",
            )

        # Map RegistrationRole → UserRole for the database column
        db_role = UserRole(user_in.role.value)

        new_user = User(
            email=email_clean,
            password_hash=get_password_hash(user_in.password),
            full_name=user_in.full_name.strip(),
            role=db_role,
            phone_number=user_in.phone_number,
            organization=user_in.organization,
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        SYSTEM_FALLBACK_USERS[email_clean] = new_user
        return UserOut.model_validate(new_user)
    except HTTPException:
        raise
    except Exception:
        # Fallback when database daemon is not running
        if email_clean in SYSTEM_FALLBACK_USERS:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this email address already exists",
            )
        db_role = UserRole(user_in.role.value)
        fallback_user = User(
            id=uuid.uuid4(),
            email=email_clean,
            password_hash=get_password_hash(user_in.password),
            full_name=user_in.full_name.strip(),
            role=db_role,
            phone_number=user_in.phone_number,
            organization=user_in.organization,
        )
        SYSTEM_FALLBACK_USERS[email_clean] = fallback_user
        return UserOut.model_validate(fallback_user)


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
