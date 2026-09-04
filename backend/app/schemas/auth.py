import enum
import re
from uuid import UUID
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
from backend.app.models.user import UserRole

# Rejects strings containing ASCII control characters (0x00-0x1F, 0x7F).
# Null bytes (\x00) are the most dangerous for SQL/OS injection; other
# control characters can corrupt logs, bypass length checks, or confuse
# downstream parsers.
_CONTROL_CHAR_RE = re.compile(r"[\x00-\x1f\x7f]")

# Allowed phone format: optional leading +, then digits, spaces, hyphens.
_PHONE_RE = re.compile(r"^\+?[\d\s\-]{6,20}$")


def _reject_control_chars(value: str, field_name: str) -> str:
    """Raise ValueError if value contains any ASCII control character."""
    if _CONTROL_CHAR_RE.search(value):
        raise ValueError(f"{field_name} must not contain control characters or null bytes")
    return value


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

    @field_validator("password")
    @classmethod
    def password_no_null_bytes(cls, v: str) -> str:
        return _reject_control_chars(v, "password")


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

    All string fields are validated to reject control characters and null
    bytes, which are the primary vectors for SQL injection via string
    concatenation and log injection attacks.
    """

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=128)
    # RegistrationRole ensures callers cannot self-assign OFFICIAL or ADMIN
    role: RegistrationRole = RegistrationRole.DRIVER
    phone_number: Optional[str] = Field(default=None, max_length=20)
    organization: Optional[str] = Field(default=None, max_length=128)

    @field_validator("password")
    @classmethod
    def password_no_control_chars(cls, v: str) -> str:
        return _reject_control_chars(v, "password")

    @field_validator("full_name")
    @classmethod
    def full_name_no_control_chars(cls, v: str) -> str:
        return _reject_control_chars(v.strip(), "full_name")

    @field_validator("phone_number")
    @classmethod
    def phone_format(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        v = v.strip()
        _reject_control_chars(v, "phone_number")
        if not _PHONE_RE.match(v):
            raise ValueError("phone_number must contain only digits, spaces, hyphens, and an optional leading +")
        return v

    @field_validator("organization")
    @classmethod
    def organization_no_control_chars(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return _reject_control_chars(v.strip(), "organization")


__all__ = [
    "UserRole",
    "RegistrationRole",
    "UserLogin",
    "UserOut",
    "TokenResponse",
    "UserCreate",
]

