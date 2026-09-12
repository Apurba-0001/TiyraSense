from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field


class CloudinarySignatureRequest(BaseModel):
    folder: str = Field("tiyrasense/evidence", description="Target Cloudinary folder")
    tags: Optional[str] = Field(None, description="Comma-separated tags for the asset")


class CloudinarySignatureResponse(BaseModel):
    cloud_name: str
    api_key: str
    timestamp: int
    signature: str
    folder: str
    upload_url: str


class IncidentEvidenceCreate(BaseModel):
    field_report_id: Optional[UUID] = None
    incident_id: Optional[UUID] = None
    cloudinary_public_id: str
    secure_url: str
    thumbnail_url: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None
    bytes: Optional[int] = None
    format: Optional[str] = None
    camera_lat: Optional[float] = None
    camera_lng: Optional[float] = None


class IncidentEvidenceOut(BaseModel):
    id: UUID
    cloudinary_public_id: str
    secure_url: str
    thumbnail_url: Optional[str] = None
    camera_lat: Optional[float] = None
    camera_lng: Optional[float] = None
    captured_at: Optional[datetime] = None
    created_at: datetime


class EvidenceDeleteResponse(BaseModel):
    success: bool
    evidence_id: str
    cloudinary_public_id: Optional[str] = None
    cloudinary_destroyed: bool = False
    message: str


class EvidenceStatsOut(BaseModel):
    total_images: int
    total_bytes: int
    total_size_formatted: str
    avg_image_size_kb: float
    format_distribution: dict = Field(default_factory=dict)
    recent_images: list = Field(default_factory=list)

