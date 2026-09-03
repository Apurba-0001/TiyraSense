import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.main import app


@pytest.mark.asyncio
async def test_root_status():
    """Verify root endpoint responds with project metadata and operational status."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["project"] == "TiyraSense"
        assert data["status"] == "operational"
        assert response.headers.get("X-TiyraSense-Data-Label") == "LIVE"


@pytest.mark.asyncio
async def test_healthcheck_live_database():
    """Verify live PostgreSQL connectivity and PostGIS spatial extension availability."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["database"] == "connected"
        assert "3." in data["postgis_version"] or "PostGIS" in data["postgis_version"]
        assert response.headers.get("X-TiyraSense-Data-Label") == "LIVE"
