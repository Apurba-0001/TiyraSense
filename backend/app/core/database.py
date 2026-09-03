from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import declarative_base
from backend.app.core.config import settings

# Async PostgreSQL + PostGIS Engine
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=(settings.APP_ENV == "development" and settings.BACKEND_LOG_LEVEL == "debug"),
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

# Async Session Factory
async_session_maker = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

Base = declarative_base()


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields an isolated async database session with automatic rollback on error."""
    async with async_session_maker() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
