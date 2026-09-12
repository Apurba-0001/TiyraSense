import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import NullPool
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.main import app


@pytest_asyncio.fixture(autouse=True)
async def override_test_db_session():
    """Use NullPool for asyncpg during tests to prevent cross-event-loop connection reuse on Windows."""
    test_engine = create_async_engine(
        settings.DATABASE_URL,
        poolclass=NullPool,
        connect_args={"timeout": 1.0, "command_timeout": 1.0},
    )
    test_session_maker = async_sessionmaker(
        bind=test_engine, class_=AsyncSession, expire_on_commit=False
    )

    async def _get_test_db():
        async with test_session_maker() as session:
            try:
                yield session
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()

    app.dependency_overrides[get_db_session] = _get_test_db
    yield
    app.dependency_overrides.pop(get_db_session, None)
    await test_engine.dispose()
