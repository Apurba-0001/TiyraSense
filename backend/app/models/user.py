import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from backend.app.core.database import Base


class UserRole(str, enum.Enum):
    DRIVER = "DRIVER"
    FIELD_WORKER = "FIELD_WORKER"
    OFFICIAL = "OFFICIAL"
    ADMIN = "ADMIN"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(128), nullable=False)
    phone_number = Column(String(32), nullable=True)
    role = Column(
        SQLEnum(UserRole, name="user_role", create_type=False),
        nullable=False,
        default=UserRole.DRIVER,
    )
    organization = Column(String(128), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<User {self.email} ({self.role})>"
