from uuid import UUID
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from backend.app.models.user import UserRole


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
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=128)
    role: UserRole = UserRole.DRIVER
    phone_number: Optional[str] = None
    organization: Optional[str] = None
