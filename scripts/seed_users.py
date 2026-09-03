"""
Seed script to initialize test user accounts for all 4 roles in the live database.
Can be run repeatedly (idempotent).
"""
import asyncio
from sqlalchemy import select
from backend.app.core.database import async_session_maker
from backend.app.core.security import get_password_hash
from backend.app.models.user import User, UserRole

TEST_USERS = [
    {
        "email": "driver@tiyrasense.in",
        "password": "DriverPass2026!",
        "full_name": "Ramen Borah",
        "role": UserRole.DRIVER,
        "phone_number": "+91-98640-12345",
        "organization": "All Assam Commercial Truckers Union",
    },
    {
        "email": "worker@tiyrasense.in",
        "password": "WorkerPass2026!",
        "full_name": "Dipankar Saikia",
        "role": UserRole.FIELD_WORKER,
        "phone_number": "+91-94350-54321",
        "organization": "Nongpoh Disaster Inspection Unit",
    },
    {
        "email": "official@tiyrasense.in",
        "password": "OfficialPass2026!",
        "full_name": "Dr. Anamika Barua",
        "role": UserRole.OFFICIAL,
        "phone_number": "+91-361-2237001",
        "organization": "Assam State Disaster Management Authority (ASDMA)",
    },
    {
        "email": "admin@tiyrasense.in",
        "password": "AdminPass2026!",
        "full_name": "System Administrator",
        "role": UserRole.ADMIN,
        "phone_number": "+91-361-2237000",
        "organization": "North Eastern Council Logistics Tech Cell",
    },
]


async def seed_users():
    print("Connecting to database and seeding initial user accounts...")
    async with async_session_maker() as session:
        for user_data in TEST_USERS:
            stmt = select(User).where(User.email == user_data["email"])
            existing = (await session.execute(stmt)).scalar_one_or_none()

            if existing:
                print(f"  [EXISTS] User '{user_data['email']}' ({user_data['role']}) already seeded.")
            else:
                new_user = User(
                    email=user_data["email"],
                    password_hash=get_password_hash(user_data["password"]),
                    full_name=user_data["full_name"],
                    role=user_data["role"],
                    phone_number=user_data.get("phone_number"),
                    organization=user_data.get("organization"),
                )
                session.add(new_user)
                print(f"  [CREATED] Seeded user '{user_data['email']}' with role '{user_data['role']}'.")

        await session.commit()
    print("User seeding completed successfully!")


if __name__ == "__main__":
    asyncio.run(seed_users())
