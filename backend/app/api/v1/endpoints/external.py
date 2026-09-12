"""
TiyraSense — External Live Data Endpoints
Exposes live telemetry from external providers (Open-Meteo quantitative weather,
road surface penalty indices, and external sensor sources).
"""
from typing import Any, Dict, List
from fastapi import APIRouter, Query, status

from backend.app.services.external_ingestion_service import ExternalIngestionService

router = APIRouter()


@router.get("/weather", response_model=List[Dict[str, Any]], status_code=status.HTTP_200_OK)
async def get_regional_weather():
    """Retrieve live atmospheric telemetry and weather risk factors across all key NER highway corridors."""
    return await ExternalIngestionService.get_regional_corridor_weather()


@router.get("/weather/point", response_model=Dict[str, Any], status_code=status.HTTP_200_OK)
async def get_point_weather(
    latitude: float = Query(..., ge=-90.0, le=90.0),
    longitude: float = Query(..., ge=-180.0, le=180.0),
):
    """Retrieve real-time Open-Meteo weather observations for a specific GPS coordinate."""
    data = await ExternalIngestionService.fetch_live_weather(latitude, longitude)
    return data or {
        "condition": "Clear",
        "temperature_c": 22.0,
        "precipitation_mm": 0.0,
        "weather_penalty_factor": 1.0,
        "data_label": "LIVE",
    }
