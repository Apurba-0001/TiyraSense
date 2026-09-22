from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class Coordinates(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude in decimal degrees")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude in decimal degrees")
    label: Optional[str] = Field(default=None, description="Human readable landmark or hub name")


class RouteEvaluationRequest(BaseModel):
    origin: Coordinates
    destination: Coordinates
    vehicle_class: str = Field("FOUR_WHEELER", description="Vehicle classification (FOUR_WHEELER, HEAVY_TRUCK, etc.)")
    cargo_type: Optional[str] = Field("STANDARD", description="Cargo priority or hazard category")
    prefer_safety: bool = Field(True, description="Prioritize lowest risk score over fastest speed")


class SegmentsSummary(BaseModel):
    total_segments: int = 0
    open_count: int = 0
    caution_count: int = 0
    restricted_count: int = 0
    blocked_count: int = 0


class NavigationStepOut(BaseModel):
    instruction: str
    sub_instruction: str = ""
    distance_meters: float
    duration_seconds: float = 0.0
    maneuver_type: str = "straight"
    road_name: str = ""
    is_hazard: bool = False
    hazard_alert: Optional[str] = None


class RouteOptionOut(BaseModel):
    id: str
    name: str
    total_distance_km: float
    estimated_duration_mins: float
    composite_risk_score: float
    is_recommended_safest: bool
    is_fastest_available: bool
    is_viable: bool
    max_hazard_state: str
    classification: Optional[str] = None
    geometry_geojson: Optional[Dict[str, Any]] = None
    segments_summary: Optional[SegmentsSummary] = None
    steps: List[NavigationStepOut] = Field(default_factory=list)


class RouteEvaluationResponse(BaseModel):
    evaluated_at: str
    data_label: str = "LIVE"
    recommended_route_id: str
    routes: List[RouteOptionOut]


class CorridorSummaryOut(BaseModel):
    id: str
    name: str
    route_id: str
    status: str
    risk_score: int
    disruption_prob: int
    last_report: str
    segment_count: int


class PlaceSearchResult(BaseModel):
    name: str
    latitude: float
    longitude: float
    state: Optional[str] = None
    place_type: str = "place"

