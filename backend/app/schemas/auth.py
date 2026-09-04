import enum
from uuid import UUID
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from backend.app.models.user import UserRole


class RegistrationRole(str, enum.Enum):
    """Roles available for self-service registration.

    OFFICIAL and ADMIN are intentionally excluded; those roles can only
    be granted by a database administrator via a direct UPDATE on the
    users table. A caller cannot escalate privileges through this endpoint.
    """

    DRIVER = "DRIVER"
    FIELD_WORKER = "FIELD_WORKER"


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class UserOut(BaseModel):
    id: UUID
    email: str
    full_name: str
    role: UserRole
    phone_number: Optional[str] = None
    organization: Optional[str] = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    user: UserOut


class UserCreate(BaseModel):
    """Payload for public account registration.

    Only DRIVER and FIELD_WORKER are accepted.  Any attempt to submit
    OFFICIAL or ADMIN is rejected at deserialization by Pydantic before
    the endpoint logic runs.
    """

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=128)
    # RegistrationRole ensures callers cannot self-assign OFFICIAL or ADMIN
    role: RegistrationRole = RegistrationRole.DRIVER
    phone_number: Optional[str] = None
    organization: Optional[str] = None
