"""
TiyraSense — External Live Data & Weather Tests
Validates real-time Open-Meteo quantitative weather telemetry and regional corridors.
"""
import pytest
from httpx import ASGITransport, AsyncClient

from backend.app.main import app


@pytest.mark.asyncio
async def test_get_regional_weather_live():
    """Verify live regional weather endpoint returns valid atmospheric telemetry labeled LIVE."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/api/v1/external/weather")
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        item = data[0]
        assert "hub" in item
        assert "temperature_c" in item
        assert "precipitation_mm" in item
        assert "weather_penalty_factor" in item
        assert item["data_label"] == "LIVE"


@pytest.mark.asyncio
async def test_get_point_weather_live():
    """Verify point coordinate weather lookup returns real-time observations."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/api/v1/external/weather/point?latitude=26.1445&longitude=91.7362")
        assert res.status_code == 200
        data = res.json()
        assert "temperature_c" in data
        assert "condition" in data
        assert data["data_label"] == "LIVE"
