from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.api.deps import get_optional_current_user
from backend.app.core.database import get_db_session
from backend.app.models.user import User
from backend.app.schemas.journeys import (
    ActiveJourneySummary,
    JourneyCreateRequest,
    JourneyResponse,
    JourneyTrackingResponse,
    TelemetryPointRequest,
    TelemetryResponse,
)
from backend.app.services.telemetry_service import TelemetryService

router = APIRouter()


@router.post("", response_model=JourneyResponse, status_code=status.HTTP_201_CREATED)
async def create_journey(
    request: JourneyCreateRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Start an active logistics journey for an evaluated route."""
    driver_id = str(current_user.id) if current_user else None
    journey_id = await TelemetryService.create_journey(
        db=db,
        route_id=request.route_id,
        driver_id=driver_id,
        vehicle_id=request.vehicle_id,
        origin_coords=request.origin_coords,
        destination_coords=request.destination_coords,
        origin_name=request.origin_name,
        destination_name=request.destination_name,
        route_name=request.route_name,
        route_geometry=request.route_geometry,
    )
    return JourneyResponse(
        id=journey_id,
        driver_id=driver_id,
        vehicle_id=request.vehicle_id,
        active_route_id=request.route_id,
        status="ACTIVE",
        started_at=datetime.now(timezone.utc).isoformat(),
    )


@router.post("/{journey_id}/telemetry", response_model=TelemetryResponse, status_code=status.HTTP_200_OK)
async def record_telemetry(
    journey_id: str,
    point: TelemetryPointRequest,
    db: AsyncSession = Depends(get_db_session),
):
    """Push live driver GPS telemetry breadcrumb."""
    await TelemetryService.record_telemetry(db=db, journey_id=journey_id, point=point)
    return TelemetryResponse(
        status="received",
        received_at=datetime.now(timezone.utc).isoformat(),
        current_latitude=point.latitude,
        current_longitude=point.longitude,
    )


@router.get("/{journey_id}/tracking", response_model=JourneyTrackingResponse, status_code=status.HTTP_200_OK)
async def get_journey_tracking(
    journey_id: str,
    db: AsyncSession = Depends(get_db_session),
):
    """Retrieve real-time GPS location, remaining distance, updated ETA, and forward hazards."""
    tracking = await TelemetryService.get_journey_tracking(db=db, journey_id=journey_id)
    if not tracking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Journey with ID '{journey_id}' not found.",
        )
    return tracking


@router.get("/active", response_model=List[ActiveJourneySummary], status_code=status.HTTP_200_OK)
async def list_active_journeys(
    db: AsyncSession = Depends(get_db_session),
):
    """List all active tracked vehicles across the North Eastern Region for the operational dashboard."""
    return await TelemetryService.list_active_journeys(db=db)
