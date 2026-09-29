from pydantic import BaseModel
from typing import Optional


class SystemSettingsOut(BaseModel):
    platform_designation: str = "TiyraSense NER Integrated Logistics Platform"
    jurisdiction: str = "NER — Assam, Meghalaya, Nagaland, Manipur, Tripura, Mizoram, Arunachal Pradesh, Sikkim"
    monsoon_season: str = "May – October (Peak Southwest Monsoon)"
    sync_frequency: str = "5 minutes"
    auto_escalate: bool = True
    caution_boundary: int = 30
    high_boundary: int = 70
    emergency_threshold: int = 85
    broadcast_to_drivers: bool = True
    audible_alarm: bool = True
    daily_digest: bool = False
    auto_clear_resolved: bool = True
    quorum_threshold: str = "2 Corroborating Reports"


class SystemSettingsUpdate(BaseModel):
    platform_designation: Optional[str] = None
    jurisdiction: Optional[str] = None
    monsoon_season: Optional[str] = None
    sync_frequency: Optional[str] = None
    auto_escalate: Optional[bool] = None
    caution_boundary: Optional[int] = None
    high_boundary: Optional[int] = None
    emergency_threshold: Optional[int] = None
    broadcast_to_drivers: Optional[bool] = None
    audible_alarm: Optional[bool] = None
    daily_digest: Optional[bool] = None
    auto_clear_resolved: Optional[bool] = None
    quorum_threshold: Optional[str] = None
