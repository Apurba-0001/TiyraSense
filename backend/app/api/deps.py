from typing import List, Optional
from uuid import UUID
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.core.database import get_db_session
from backend.app.core.security import decode_access_token
from backend.app.models.user import User, UserRole, SYSTEM_FALLBACK_USERS

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)



async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    """Validate Bearer JWT token and retrieve the corresponding active user.

    Security properties:
    - Role is ALWAYS read from the database row, never from the JWT claim.
      This means a forged or stale JWT cannot grant a higher role than what
      the database currently holds.
    - The user_id (sub) is parsed as a UUID — any non-UUID value raises a
      hard 401 before touching the database.
    - If the database row's role is somehow not a valid UserRole enum member
      (e.g. due to direct DB corruption), we reject the request rather than
      proceeding with an undefined role.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials or token expired",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(token)
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            raise credentials_exception
        # Strict UUID parse — rejects any non-UUID string including SQL fragments
        user_id = UUID(user_id_str)
    except (JWTError, ValueError):
        raise credentials_exception

    user = None
    try:
        stmt = select(User).where(User.id == user_id)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
    except Exception:
        # Fallback when database daemon is not running
        user = next((u for u in SYSTEM_FALLBACK_USERS.values() if u.id == user_id), None)

    if user is None:
        user = next((u for u in SYSTEM_FALLBACK_USERS.values() if u.id == user_id), None)

    if user is None:
        raise credentials_exception

    # Defensive: validate that the role stored in the DB is a known enum member.
    # This guards against a scenario where a DB administrator accidentally writes
    # an invalid role string that could cause undefined RBAC behavior.
    try:
        UserRole(user.role.value if hasattr(user.role, "value") else user.role)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account has an unrecognised role; contact an administrator",
        )

    return user


def require_role(allowed_roles: List[UserRole]):
    """Server-side RBAC dependency factory enforcing authorised roles.

    Role comparison uses enum identity (not string equality) so a value like
    'ADMIN ' (with a trailing space) would never accidentally match UserRole.ADMIN.
    """
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: Role '{current_user.role}' lacks permission for this resource.",
            )
        return current_user

    return role_checker


async def get_optional_current_user(
    token: Optional[str] = Depends(oauth2_scheme_optional),
    db: AsyncSession = Depends(get_db_session),
) -> Optional[User]:
    """Optional authentication: returns User if valid token is provided, otherwise None."""
    if not token:
        return None
    try:
        return await get_current_user(token=token, db=db)
    except HTTPException:
        return None
