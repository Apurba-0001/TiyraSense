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


# Verified development accounts available when PostgreSQL daemon is offline
SYSTEM_FALLBACK_USERS = {
    "driver@tiyrasense.in": User(
        id=uuid.UUID("a1b2c3d4-e5f6-4a1b-8c2d-000000000001"),
        email="driver@tiyrasense.in",
        password_hash="$2b$12$Zobv1AD5JNz5hX1PmgyL8eaFZQvkUAeI.yZot4g0o0dRFlQK1qqnu",
        full_name="Ramen Borah",
        role=UserRole.DRIVER,
        phone_number="+91-98640-12345",
        organization="All Assam Commercial Truckers Union",
    ),
    "worker@tiyrasense.in": User(
        id=uuid.UUID("a1b2c3d4-e5f6-4a1b-8c2d-000000000002"),
        email="worker@tiyrasense.in",
        password_hash="$2b$12$rkdmKrQJ7NwEXfiE0POcR.eF/vqvsyDR1obmWVDIjdhcndOdP.Sum",
        full_name="Dipankar Saikia",
        role=UserRole.FIELD_WORKER,
        phone_number="+91-94350-54321",
        organization="Nongpoh Disaster Inspection Unit",
    ),
    "official@tiyrasense.in": User(
        id=uuid.UUID("a1b2c3d4-e5f6-4a1b-8c2d-000000000003"),
        email="official@tiyrasense.in",
        password_hash="$2b$12$2Tn8Ucl6MVcRdw6fcKJygukoDpaC6kRQCo4irQyL1a37gtIfGuPqS",
        full_name="Dr. Anamika Barua",
        role=UserRole.OFFICIAL,
        phone_number="+91-361-2237001",
        organization="Assam State Disaster Management Authority (ASDMA)",
    ),
    "admin@tiyrasense.in": User(
        id=uuid.UUID("a1b2c3d4-e5f6-4a1b-8c2d-000000000004"),
        email="admin@tiyrasense.in",
        password_hash="$2b$12$EaX/eqdG7KCiBIbcjCrRvOhDJivgZQmBqTQxgMLHLF1qWgfValtUi",
        full_name="System Administrator",
        role=UserRole.ADMIN,
        phone_number="+91-361-2237000",
        organization="North Eastern Council Logistics Tech Cell",
    ),
}
