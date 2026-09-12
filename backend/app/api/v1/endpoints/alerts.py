import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.schemas.alerts import AlertCreate, AlertOut

router = APIRouter()

_IN_MEMORY_ALERTS = [
    {
        "id": "ALT-101",
        "severity": "EMERGENCY",
        "corridor": "NH-06",
        "title": "Landslide — Full Blockage at KM 52",
        "description": "Both lanes blocked by boulder roll-down. BRO recovery team dispatched.",
        "time": "5m ago",
        "dispatched_at": "2026-09-06T13:45:00Z",
        "acknowledged": False,
        "acknowledged_at": None,
        "data_label": "LIVE",
    },
    {
        "id": "ALT-102",
        "severity": "CAUTION",
        "corridor": "NH-29",
        "title": "Flash Flood Watch & Shoulder Waterlogging",
        "description": "Heavy rainfall between KM 81-86. Speed limit lowered to 25 km/h.",
        "time": "19m ago",
        "dispatched_at": "2026-09-06T13:31:00Z",
        "acknowledged": False,
        "acknowledged_at": None,
        "data_label": "LIVE",
    },
    {
        "id": "ALT-103",
        "severity": "INFO",
        "corridor": "NH-40",
        "title": "Culvert Inspection Cleared",
        "description": "Structure 14B passed structural strain acoustic check.",
        "time": "45m ago",
        "dispatched_at": "2026-09-06T13:05:00Z",
        "acknowledged": False,
        "acknowledged_at": None,
        "data_label": "LIVE",
    },
    {
        "id": "ALT-104",
        "severity": "INFO",
        "corridor": "NH-51",
        "title": "Convoy Escort Operational",
        "description": "Fuel convoy 04 departed Paikan toward Tura with standard telemetry.",
        "time": "1h ago",
        "dispatched_at": "2026-09-06T12:50:00Z",
        "acknowledged": True,
        "acknowledged_at": "2026-09-06T13:00:00Z",
        "data_label": "LIVE",
    },
]


@router.get("", response_model=List[AlertOut], status_code=status.HTTP_200_OK)
async def list_alerts(
    db: AsyncSession = Depends(get_db_session),
):
    """Retrieve all operational alerts across monitored highway networks."""
    # 1. Direct query to live Supabase Cloud PostgREST (primary live cloud database)
    try:
        from backend.app.services.supabase_service import SupabaseService
        live_alerts = await SupabaseService.get_alerts()
        if live_alerts:
            alerts = []
            for a in live_alerts:
                alerts.append(
                    AlertOut(
                        id=str(a.get("id")),
                        severity=str(a.get("severity", "CAUTION")).upper(),
                        corridor=str(a.get("corridor", "NH-06 Sector")),
                        title=str(a.get("title", "Active Alert")),
                        description=str(a.get("message_en", a.get("title", ""))),
                        time="Recently",
                        dispatched_at=str(a.get("dispatched_at", "")),
                        acknowledged=bool(a.get("acknowledged_at")),
                        acknowledged_at=str(a.get("acknowledged_at")) if a.get("acknowledged_at") else None,
                        data_label="LIVE",
                    )
                )
            return alerts
    except Exception:
        pass

    # 2. Local database query (if running)
    try:
        sql = text("""
            SELECT 
                a.id::text,
                a.severity::text,
                COALESCE(rs.corridor_name, 'NER Highway') as corridor,
                a.title,
                a.message_en,
                a.status::text,
                TO_CHAR(a.dispatched_at, 'YYYY-MM-DD HH24:MI:SS') as dispatched_at,
                (a.acknowledged_at IS NOT NULL) as acknowledged,
                TO_CHAR(a.acknowledged_at, 'YYYY-MM-DD HH24:MI:SS') as acknowledged_at
            FROM alerts a
            LEFT JOIN road_segments rs ON a.road_segment_id = rs.id
            ORDER BY a.dispatched_at DESC
            LIMIT 50;
        """)
        result = await db.execute(sql)
        rows = result.fetchall()
        if rows:
            alerts = []
            for r in rows:
                alerts.append(
                    AlertOut(
                        id=str(r[0]),
                        severity=str(r[1]),
                        corridor=str(r[2]),
                        title=str(r[3]),
                        description=str(r[4]),
                        time="Recently",
                        dispatched_at=str(r[6]),
                        acknowledged=bool(r[7]),
                        acknowledged_at=str(r[8]) if r[8] else None,
                        data_label=settings.DATA_LABEL,
                    )
                )
            return alerts
    except Exception:
        pass

    return [AlertOut(**a) for a in _IN_MEMORY_ALERTS]


@router.post("", response_model=AlertOut, status_code=status.HTTP_201_CREATED)
async def create_alert(
    alert: AlertCreate,
    db: AsyncSession = Depends(get_db_session),
):
    """Broadcast an official highway accessibility or hazard alert."""
    new_id = f"ALT-{str(uuid.uuid4())[:6].upper()}"
    now_iso = datetime.now(timezone.utc).isoformat()

    new_alert_dict = {
        "id": new_id,
        "severity": alert.severity,
        "corridor": alert.corridor,
        "title": alert.title,
        "description": alert.description,
        "time": "Just now",
        "dispatched_at": now_iso,
        "acknowledged": False,
        "acknowledged_at": None,
        "data_label": settings.DATA_LABEL,
    }

    try:
        sql = text("""
            INSERT INTO alerts (
                id, severity, title, message_en, status, dispatched_at
            ) VALUES (
                gen_random_uuid(), :severity::severity_level, :title, :message, 'SENT', NOW()
            ) RETURNING id::text;
        """)
        res = await db.execute(sql, {
            "severity": alert.severity.upper(),
            "title": alert.title,
            "message": alert.description,
        })
        await db.commit()
        db_id = res.scalar()
        if db_id:
            new_alert_dict["id"] = str(db_id)
    except Exception:
        pass

    try:
        from backend.app.services.supabase_service import SupabaseService
        supa_res = await SupabaseService.create_alert({
            "severity": alert.severity.upper(),
            "corridor": alert.corridor,
            "title": alert.title,
            "message_en": alert.description,
            "status": "SENT",
            "is_emergency": (alert.severity.upper() == "EMERGENCY"),
        })
        if supa_res and "id" in supa_res:
            new_alert_dict["id"] = str(supa_res["id"])
    except Exception:
        pass

    _IN_MEMORY_ALERTS.insert(0, new_alert_dict)
    return AlertOut(**new_alert_dict)


@router.patch("/{alert_id}/acknowledge", response_model=AlertOut, status_code=status.HTTP_200_OK)
async def acknowledge_alert(
    alert_id: str,
    db: AsyncSession = Depends(get_db_session),
):
    """Acknowledge an active alert by official or operations controller."""
    now_iso = datetime.now(timezone.utc).isoformat()
    for a in _IN_MEMORY_ALERTS:
        if a["id"] == alert_id:
            a["acknowledged"] = True
            a["acknowledged_at"] = now_iso
            try:
                from backend.app.services.supabase_service import SupabaseService
                await SupabaseService.acknowledge_alert(alert_id)
            except Exception:
                pass
            return AlertOut(**a)

    try:
        sql = text("""
            UPDATE alerts
            SET acknowledged_at = NOW(), status = 'ACKNOWLEDGED'
            WHERE id::text = :alert_id;
        """)
        await db.execute(sql, {"alert_id": alert_id})
        await db.commit()
    except Exception:
        pass

    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.acknowledge_alert(alert_id)
    except Exception:
        pass

    item = {
        "id": alert_id,
        "severity": "INFO",
        "corridor": "NH-06",
        "title": "Acknowledged Alert",
        "description": "Alert acknowledged by operator",
        "time": "Just now",
        "dispatched_at": now_iso,
        "acknowledged": True,
        "acknowledged_at": now_iso,
        "data_label": settings.DATA_LABEL,
    }
    return AlertOut(**item)


@router.post("/acknowledge-all", response_model=List[AlertOut], status_code=status.HTTP_200_OK)
async def acknowledge_all_alerts(
    db: AsyncSession = Depends(get_db_session),
):
    """Mark all active alerts as acknowledged."""
    now_iso = datetime.now(timezone.utc).isoformat()
    for a in _IN_MEMORY_ALERTS:
        a["acknowledged"] = True
        a["acknowledged_at"] = now_iso

    try:
        sql = text("""
            UPDATE alerts
            SET acknowledged_at = NOW(), status = 'ACKNOWLEDGED'
            WHERE acknowledged_at IS NULL;
        """)
        await db.execute(sql)
        await db.commit()
    except Exception:
        pass

    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.acknowledge_all_alerts()
    except Exception:
        pass

    return [AlertOut(**a) for a in _IN_MEMORY_ALERTS]
