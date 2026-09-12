from typing import List, Optional
from pydantic import BaseModel, Field
from backend.app.schemas.routes import Coordinates


class JourneyCreateRequest(BaseModel):
    route_id: str = Field(..., description="UUID of the selected evaluated route")
    vehicle_id: Optional[str] = Field(None, description="UUID of the assigned vehicle, if applicable")
    origin_coords: Optional[Coordinates] = None
    destination_coords: Optional[Coordinates] = None
    origin_name: Optional[str] = None
    destination_name: Optional[str] = None
    route_name: Optional[str] = None
    route_geometry: Optional[List[List[float]]] = Field(None, description="GeoJSON [lng, lat] coordinate array")


class JourneyResponse(BaseModel):
    id: str
    driver_id: Optional[str] = None
    vehicle_id: Optional[str] = None
    active_route_id: Optional[str] = None
    status: str
    started_at: str


class TelemetryPointRequest(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    speed_kmh: Optional[float] = Field(0.0, ge=0.0)
    heading_degrees: Optional[float] = Field(0.0, ge=0.0, le=360.0)
    client_timestamp: Optional[str] = None


class TelemetryResponse(BaseModel):
    status: str = "received"
    received_at: str
    current_latitude: float
    current_longitude: float


class UpcomingHazard(BaseModel):
    segment_code: str
    corridor_name: str
    hazard_state: str
    risk_score: float
    distance_ahead_km: float


class JourneyTrackingResponse(BaseModel):
    journey_id: str
    status: str
    current_location: Optional[Coordinates] = None
    speed_kmh: float = 0.0
    last_telemetry_at: Optional[str] = None
    distance_covered_km: float = 0.0
    remaining_distance_km: float = 0.0
    estimated_time_remaining_mins: float = 0.0
    upcoming_hazards: List[UpcomingHazard] = []


class ActiveJourneySummary(BaseModel):
    journey_id: str
    vehicle_name: Optional[str] = None
    vehicle_number: Optional[str] = None
    callsign: Optional[str] = None
    driver_name: str
    driver_phone: Optional[str] = None
    route_name: str
    current_location: Optional[Coordinates] = None
    speed_kmh: float = 0.0
    heading_degrees: float = 0.0
    origin_name: Optional[str] = None
    destination_name: Optional[str] = None
    origin_coords: Optional[Coordinates] = None
    destination_coords: Optional[Coordinates] = None
    route_geometry: Optional[List[List[float]]] = None
    status: str
    last_ping_mins_ago: int = 0
