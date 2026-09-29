import json
import logging
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.api.deps import get_current_user, require_role
from backend.app.core.database import get_db_session
from backend.app.models.user import User, UserRole
from backend.app.schemas.settings import SystemSettingsOut, SystemSettingsUpdate

logger = logging.getLogger(__name__)

router = APIRouter()

_SETTINGS_FILE = Path(__file__).resolve().parents[3] / "static" / "system_settings.json"

_DEFAULT_SETTINGS = {
    "platform_designation": "TiyraSense NER Integrated Logistics Platform",
    "jurisdiction": "NER — Assam, Meghalaya, Nagaland, Manipur, Tripura, Mizoram, Arunachal Pradesh, Sikkim",
    "monsoon_season": "May – October (Peak Southwest Monsoon)",
    "sync_frequency": "5 minutes",
    "auto_escalate": True,
    "caution_boundary": 30,
    "high_boundary": 70,
    "emergency_threshold": 85,
    "broadcast_to_drivers": True,
    "audible_alarm": True,
    "daily_digest": False,
    "auto_clear_resolved": True,
    "quorum_threshold": "2 Corroborating Reports",
}


def _load_settings_from_disk() -> dict:
    if _SETTINGS_FILE.exists():
        try:
            with open(_SETTINGS_FILE, "r", encoding="utf-8") as f:
                saved = json.load(f)
                if isinstance(saved, dict):
                    merged = dict(_DEFAULT_SETTINGS)
                    merged.update(saved)
                    return merged
        except Exception as e:
            logger.warning(f"Error loading system settings from disk: {e}")
    return dict(_DEFAULT_SETTINGS)


def _save_settings_to_disk(data: dict):
    try:
        _SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(_SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        logger.warning(f"Error saving system settings to disk: {e}")


_CURRENT_SETTINGS = _load_settings_from_disk()


@router.get("", response_model=SystemSettingsOut, status_code=status.HTTP_200_OK)
async def get_system_settings(
    current_user: User = Depends(get_current_user),
):
    """Retrieve operational system settings, thresholds, and governance policies.
    
    Access Control: Any authenticated user may read settings. Write access requires OFFICIAL or ADMIN role.
    """
    global _CURRENT_SETTINGS
    _CURRENT_SETTINGS = _load_settings_from_disk()
    return SystemSettingsOut(**_CURRENT_SETTINGS)


@router.put("", response_model=SystemSettingsOut, status_code=status.HTTP_200_OK)
@router.patch("", response_model=SystemSettingsOut, status_code=status.HTTP_200_OK)
async def update_system_settings(
    settings_in: SystemSettingsUpdate,
    current_user: User = Depends(require_role([UserRole.OFFICIAL, UserRole.ADMIN])),
):
    """Update system settings, risk thresholds, and alert rules.
    
    Access Control: Only Officials and Admins are permitted to update platform configuration.
    """
    global _CURRENT_SETTINGS
    update_dict = settings_in.model_dump(exclude_unset=True)
    _CURRENT_SETTINGS.update(update_dict)
    _save_settings_to_disk(_CURRENT_SETTINGS)
    return SystemSettingsOut(**_CURRENT_SETTINGS)
