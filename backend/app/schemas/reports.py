from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field


class FieldReportCreate(BaseModel):
    hazard_type: str = Field(..., description="Hazard classification e.g. LANDSLIDE, FLASH_FLOOD, DEBRIS_FALL")
    severity: str = Field(..., description="Severity e.g. LOW, MODERATE, HIGH, CRITICAL")
    description: str = Field(..., max_length=1000)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    corridor_name: Optional[str] = Field(None, max_length=128)
    km_marker: Optional[str] = Field(None, max_length=32)
    photo_url: Optional[str] = Field(None, max_length=512)


class FieldReportVerify(BaseModel):
    status: str = Field(..., description="Target status: VERIFIED, DISPATCHED, or REJECTED")
    dispatch_unit: Optional[str] = Field(None, max_length=128)
    dispatch_notes: Optional[str] = Field(None, max_length=1000)


class FieldReportOut(BaseModel):
    id: str
    hazard_type: str
    severity: str
    status: str
    description: str
    latitude: float
    longitude: float
    corridor_name: Optional[str] = None
    km_marker: Optional[str] = None
    reporter_name: Optional[str] = None
    reporter_unit: Optional[str] = None
    submitted_at: str
    data_label: str = "LIVE"
    dispatch_unit: Optional[str] = None
    dispatch_notes: Optional[str] = None
    photo_url: Optional[str] = None
