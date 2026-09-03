from fastapi import APIRouter, Depends, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.core.config import settings
from backend.app.core.database import get_db_session

router = APIRouter()


@router.get("/health", status_code=status.HTTP_200_OK)
async def health_check(db: AsyncSession = Depends(get_db_session)):
    """System health verification: queries PostgreSQL and PostGIS extension status."""
    try:
        # Verify basic DB query execution
        await db.execute(text("SELECT 1"))
        
        # Verify PostGIS spatial extension availability
        postgis_result = await db.execute(text("SELECT PostGIS_Version()"))
        postgis_version = postgis_result.scalar()

        return {
            "status": "healthy",
            "app_name": settings.APP_NAME,
            "environment": settings.APP_ENV,
            "data_label": settings.DATA_LABEL,
            "database": "connected",
            "postgis_version": postgis_version,
        }
    except Exception as exc:
        return {
            "status": "unhealthy",
            "app_name": settings.APP_NAME,
            "environment": settings.APP_ENV,
            "data_label": settings.DATA_LABEL,
            "database": "disconnected",
            "error": str(exc),
        }
