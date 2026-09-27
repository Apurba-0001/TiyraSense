import uuid
from typing import List
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.api.deps import get_current_user, require_role
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from backend.app.models.user import (
    User,
    UserRole,
    SYSTEM_FALLBACK_USERS,
    DELETED_USER_IDS,
    DELETED_USER_EMAILS,
)
from backend.app.schemas.auth import (
    TokenResponse,
    UserCreate,
    UserLogin,
    UserOut,
    UserUpdate,
    RegistrationRole,
    ManagedUserOut,
    ManagedUserUpdate,
    UserInvite,
)

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(
    login_data: UserLogin,
    db: AsyncSession = Depends(get_db_session),
):
    """Authenticate credentials and issue a signed Bearer JWT token with role claims."""
    email_clean = login_data.email.lower().strip()
    if email_clean in DELETED_USER_EMAILS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account has been permanently deleted.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = None
    try:
        stmt = select(User).where(User.email == email_clean)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
    except Exception:
        pass

    # Direct database check against live Supabase cloud table if not in local PostgreSQL session
    if not user:
        try:
            from backend.app.services.supabase_service import SupabaseService
            sb_user = await SupabaseService.get_user_by_email(email_clean)
            if sb_user:
                role_val = sb_user.get("role", "DRIVER").upper().replace(" ", "_")
                try:
                    user_role = UserRole(role_val)
                except ValueError:
                    user_role = UserRole.DRIVER
                user = User(
                    id=uuid.UUID(sb_user["id"]) if "id" in sb_user else uuid.uuid4(),
                    email=sb_user.get("email", email_clean),
                    password_hash=sb_user.get("password_hash", get_password_hash("WelcomeTiyra2026!")),
                    full_name=sb_user.get("full_name", "User"),
                    role=user_role,
                    phone_number=sb_user.get("phone_number"),
                    organization=sb_user.get("organization"),
                )
        except Exception:
            pass

    # Graceful fallback to verified dev accounts if database daemon is not running (development and test only)
    if not user and settings.APP_ENV in ("development", "test"):
        if email_clean not in DELETED_USER_EMAILS:
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
        # Fallback when database daemon is not running (development and test only)
        if settings.APP_ENV not in ("development", "test"):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Database service unavailable. Registration requires an active database connection.",
            )

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


@router.get("/users", response_model=List[ManagedUserOut])
async def list_users(
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db_session),
):
    """Retrieve all users across the system from database, ensuring no deleted accounts reappear."""
    results_map = {}

    # 1. Fetch from PostgreSQL database
    try:
        stmt = select(User).order_by(User.created_at.desc())
        res = await db.execute(stmt)
        db_users = res.scalars().all()
        for u in db_users:
            if u.email.lower() not in DELETED_USER_EMAILS and u.id not in DELETED_USER_IDS:
                results_map[u.email.lower()] = ManagedUserOut(
                    id=str(u.id),
                    email=u.email,
                    full_name=u.full_name,
                    phone_number=u.phone_number,
                    role=u.role.value if hasattr(u.role, "value") else str(u.role),
                    organization=u.organization,
                    status="ACTIVE",
                    last_active="Active",
                    registered=u.created_at.strftime("%b %d, %Y") if hasattr(u, "created_at") and u.created_at else "Recent",
                )
    except Exception:
        pass

    # 2. Fetch from live Supabase Cloud users table
    try:
        from backend.app.services.supabase_service import SupabaseService
        sb_users = await SupabaseService.get_users()
        for su in sb_users:
            email_key = su.get("email", "").lower().strip()
            su_id_str = str(su.get("id", ""))
            try:
                su_uuid = uuid.UUID(su_id_str)
            except Exception:
                su_uuid = None
            if email_key and email_key not in DELETED_USER_EMAILS and (not su_uuid or su_uuid not in DELETED_USER_IDS):
                if email_key not in results_map:
                    results_map[email_key] = ManagedUserOut(
                        id=su_id_str or str(uuid.uuid4()),
                        email=su.get("email", ""),
                        full_name=su.get("full_name", "User"),
                        phone_number=su.get("phone_number"),
                        role=su.get("role", "DRIVER").upper().replace(" ", "_"),
                        organization=su.get("organization"),
                        status=su.get("status", "ACTIVE"),
                        last_active="Active",
                        registered="Cloud Verified",
                    )
    except Exception:
        pass

    # 3. Merge verified development / system accounts ONLY if not deleted and not already in results
    for email, u in SYSTEM_FALLBACK_USERS.items():
        email_key = email.lower().strip()
        if email_key not in DELETED_USER_EMAILS and u.id not in DELETED_USER_IDS and email_key not in results_map:
            results_map[email_key] = ManagedUserOut(
                id=str(u.id),
                email=u.email,
                full_name=u.full_name,
                phone_number=u.phone_number,
                role=u.role.value if hasattr(u.role, "value") else str(u.role),
                organization=u.organization,
                status="ACTIVE",
                last_active="Active",
                registered="System Verified",
            )

    all_users = list(results_map.values())

    # 4. Strict Single-Admin deduplication enforcement
    # If multiple accounts are marked ADMIN, keep only the designated primary admin and normalize others
    admin_users = [u for u in all_users if u.role == "ADMIN"]
    if len(admin_users) > 1:
        # Keep the first admin as the sole ADMIN, demote excess legacy entries to OFFICIAL
        primary_admin = admin_users[0]
        for u in all_users:
            if u.role == "ADMIN" and u.id != primary_admin.id and u.email != primary_admin.email:
                u.role = "OFFICIAL"

    return all_users


@router.post("/users/invite", response_model=ManagedUserOut, status_code=status.HTTP_201_CREATED)
async def invite_user(
    invite_in: UserInvite,
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db_session),
):
    """Invite and register a new user from the User Management dashboard."""
    email_clean = invite_in.email.lower().strip()
    # Check existing
    try:
        stmt = select(User).where(User.email == email_clean)
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if (existing or email_clean in SYSTEM_FALLBACK_USERS) and email_clean not in DELETED_USER_EMAILS:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User with email '{email_clean}' already exists.",
            )

        role_str = invite_in.role.upper().replace(" ", "_")
        if role_str == "ADMIN":
            # Strict single-admin policy
            admin_count = 0
            try:
                stmt_admin = select(User).where(User.role == UserRole.ADMIN)
                res_admin = await db.execute(stmt_admin)
                admin_count += len([u for u in res_admin.scalars().all() if u.id not in DELETED_USER_IDS])
            except Exception:
                pass
            for u in SYSTEM_FALLBACK_USERS.values():
                if u.role == UserRole.ADMIN and u.id not in DELETED_USER_IDS and u.email.lower() not in DELETED_USER_EMAILS:
                    admin_count += 1
            if admin_count >= 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="System policy strictly enforces a single Administrator account. Multiple Government Officials are permitted, but only one Admin is allowed.",
                )

        try:
            db_role = UserRole(role_str)
        except ValueError:
            db_role = UserRole.OFFICIAL

        temp_password = "WelcomeTiyra2026!"
        new_id = uuid.uuid4()
        new_user = User(
            id=new_id,
            email=email_clean,
            password_hash=get_password_hash(temp_password),
            full_name=invite_in.name.strip(),
            role=db_role,
            phone_number=invite_in.phone_number,
            organization=invite_in.organization,
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        SYSTEM_FALLBACK_USERS[email_clean] = new_user

        # Remove from deleted sets if re-invited
        DELETED_USER_EMAILS.discard(email_clean)
        DELETED_USER_IDS.discard(new_id)

        # Sync to Supabase
        try:
            from backend.app.services.supabase_service import SupabaseService
            await SupabaseService.update_user_profile(
                user_id=str(new_user.id),
                email=new_user.email,
                full_name=new_user.full_name,
                phone_number=new_user.phone_number,
                organization=new_user.organization,
                role=new_user.role.value,
                status="PENDING",
            )
        except Exception:
            pass

        return ManagedUserOut(
            id=str(new_user.id),
            email=new_user.email,
            full_name=new_user.full_name,
            phone_number=new_user.phone_number,
            role=new_user.role.value,
            organization=new_user.organization,
            status="PENDING",
            last_active="Invited",
            registered="Today",
        )
    except HTTPException:
        raise
    except Exception:
        role_str = invite_in.role.upper().replace(" ", "_")
        if role_str == "ADMIN":
            admin_count = sum(
                1 for u in SYSTEM_FALLBACK_USERS.values()
                if u.role == UserRole.ADMIN and u.id not in DELETED_USER_IDS and u.email.lower() not in DELETED_USER_EMAILS
            )
            if admin_count >= 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="System policy strictly enforces a single Administrator account. Multiple Government Officials are permitted, but only one Admin is allowed.",
                )
        try:
            db_role = UserRole(role_str)
        except ValueError:
            db_role = UserRole.OFFICIAL

        new_id = uuid.uuid4()
        fallback_user = User(
            id=new_id,
            email=email_clean,
            password_hash=get_password_hash("WelcomeTiyra2026!"),
            full_name=invite_in.name.strip(),
            role=db_role,
            phone_number=invite_in.phone_number,
            organization=invite_in.organization,
        )
        SYSTEM_FALLBACK_USERS[email_clean] = fallback_user
        DELETED_USER_EMAILS.discard(email_clean)
        DELETED_USER_IDS.discard(new_id)

        return ManagedUserOut(
            id=str(fallback_user.id),
            email=fallback_user.email,
            full_name=fallback_user.full_name,
            phone_number=fallback_user.phone_number,
            role=fallback_user.role.value,
            organization=fallback_user.organization,
            status="PENDING",
            last_active="Invited",
            registered="Today",
        )


@router.patch("/users/{user_id}", response_model=ManagedUserOut)
async def update_managed_user(
    user_id: str,
    update_in: ManagedUserUpdate,
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db_session),
):
    """Update a user's role, status, or organization details."""
    target_uuid = None
    try:
        target_uuid = uuid.UUID(user_id)
    except ValueError:
        pass

    target_user = None
    target_email = ""

    # 1. Check local PostgreSQL
    if target_uuid:
        try:
            stmt = select(User).where(User.id == target_uuid)
            target_user = (await db.execute(stmt)).scalar_one_or_none()
        except Exception:
            pass

    # 2. Check fallback users
    if not target_user:
        target_user = next((u for u in SYSTEM_FALLBACK_USERS.values() if str(u.id) == user_id), None)

    if target_user:
        target_email = target_user.email

    # Enforce single-admin policy if promoting to ADMIN
    if update_in.role:
        role_str = update_in.role.upper().replace(" ", "_")
        if role_str == "ADMIN":
            admin_count = 0
            try:
                stmt_admin = select(User).where(User.role == UserRole.ADMIN, User.id != target_uuid)
                res_admin = await db.execute(stmt_admin)
                admin_count += len([u for u in res_admin.scalars().all() if u.id not in DELETED_USER_IDS])
            except Exception:
                pass
            for u in SYSTEM_FALLBACK_USERS.values():
                if u.role == UserRole.ADMIN and str(u.id) != user_id and u.id not in DELETED_USER_IDS and u.email.lower() not in DELETED_USER_EMAILS:
                    admin_count += 1
            if admin_count >= 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="System policy strictly enforces a single Administrator account. Demote the existing Admin before assigning another.",
                )
            if target_user:
                target_user.role = UserRole.ADMIN
        else:
            try:
                if target_user:
                    target_user.role = UserRole(role_str)
            except ValueError:
                pass

    if update_in.full_name and target_user:
        target_user.full_name = update_in.full_name.strip()
    if update_in.organization is not None and target_user:
        target_user.organization = update_in.organization
    if update_in.phone_number is not None and target_user:
        target_user.phone_number = update_in.phone_number

    if target_user:
        try:
            await db.commit()
        except Exception:
            pass

    # Sync to Supabase
    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.update_user_profile(
            user_id=user_id,
            email=target_email or user_id,
            full_name=update_in.full_name or (target_user.full_name if target_user else "User"),
            phone_number=update_in.phone_number if update_in.phone_number is not None else (target_user.phone_number if target_user else None),
            organization=update_in.organization if update_in.organization is not None else (target_user.organization if target_user else None),
            role=update_in.role,
            status=update_in.status,
        )
    except Exception:
        pass

    return ManagedUserOut(
        id=user_id,
        email=target_email or "user@tiyrasense.in",
        full_name=update_in.full_name or (target_user.full_name if target_user else "User"),
        phone_number=update_in.phone_number or (target_user.phone_number if target_user else None),
        role=update_in.role or (target_user.role.value if target_user else "OFFICIAL"),
        organization=update_in.organization or (target_user.organization if target_user else None),
        status=update_in.status or "ACTIVE",
        last_active="Active",
        registered="Recent",
    )


@router.delete("/users/{user_id}")
async def delete_managed_user(
    user_id: str,
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db_session),
):
    """Permanently delete a user from PostgreSQL, Supabase, and in-memory caches."""
    target_uuid = None
    try:
        target_uuid = uuid.UUID(user_id)
    except ValueError:
        pass

    target_email = None

    # 1. Find and delete from PostgreSQL
    if target_uuid:
        try:
            stmt = select(User).where(User.id == target_uuid)
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if existing:
                target_email = existing.email.lower().strip()
                await db.execute(delete(User).where(User.id == target_uuid))
                await db.commit()
        except Exception:
            pass

    # 2. Check fallback map
    for email, u in list(SYSTEM_FALLBACK_USERS.items()):
        if str(u.id) == user_id or email.lower().strip() == user_id.lower().strip():
            target_email = email.lower().strip()
            SYSTEM_FALLBACK_USERS.pop(email, None)

    if target_uuid:
        DELETED_USER_IDS.add(target_uuid)
    if target_email:
        DELETED_USER_EMAILS.add(target_email)

    # 3. Delete from Supabase
    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.delete_user(user_id=user_id, email=target_email)
    except Exception:
        pass

    return {
        "success": True,
        "message": f"User {user_id} ({target_email or 'account'}) permanently deleted from the system.",
    }


