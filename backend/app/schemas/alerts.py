from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class AlertCreate(BaseModel):
    corridor: str = Field(..., max_length=128)
    severity: str = Field(..., description="Severity e.g. EMERGENCY, CAUTION, INFO")
    title: str = Field(..., max_length=128)
    description: str = Field(..., max_length=1000)
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)


class AlertOut(BaseModel):
    id: str
    severity: str
    corridor: str
    title: str
    description: str
    time: str
    dispatched_at: str
    acknowledged: bool = False
    acknowledged_at: Optional[str] = None
    data_label: str = "LIVE"
