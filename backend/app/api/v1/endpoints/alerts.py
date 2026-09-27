import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.api.deps import get_optional_current_user
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.models.user import User
from backend.app.schemas.alerts import AlertCreate, AlertOut

router = APIRouter()

_IN_MEMORY_ALERTS: List[dict] = []

_SEVERITY_LEVEL_MAP = {
    "EMERGENCY": "CRITICAL",
    "CRITICAL": "CRITICAL",
    "HIGH RISK": "HIGH",
    "HIGH": "HIGH",
    "CAUTION": "MEDIUM",
    "MEDIUM": "MEDIUM",
    "INFO": "LOW",
    "LOW": "LOW",
}


def _can_user_receive_alert(a: dict, user: Optional[User]) -> bool:
    """Determine if alert should be delivered to the caller.
    Broadcast alerts are delivered to all users. Targeted alerts are only delivered
    to the specific user ID or role specified.
    """
    is_broadcast = a.get("is_broadcast", True)
    target_user_id = str(a.get("target_user_id") or "")
    target_role = str(a.get("target_role") or "")

    if is_broadcast and not target_user_id and not target_role:
        return True

    if not user:
        return is_broadcast and not target_user_id

    u_id = str(user.id)
    u_role = user.role.value if hasattr(user.role, "value") else str(user.role)

    if target_user_id and (target_user_id.lower() == u_id.lower() or target_user_id.upper() == "ALL"):
        return True
    if target_role and target_role.upper() == u_role.upper():
        return True

    return is_broadcast and not target_user_id


@router.get("", response_model=List[AlertOut], status_code=status.HTTP_200_OK)
async def list_alerts(
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Retrieve operational alerts filtered for the authenticated caller.
    Broadcast alerts reach all devices; user-specific details reach only the intended recipient.
    """
    raw_alerts: List[dict] = []

    # 1. Direct query to live Supabase Cloud PostgREST (primary live cloud database)
    try:
        from backend.app.services.supabase_service import SupabaseService
        live_alerts = await SupabaseService.get_alerts()
        if live_alerts is not None and len(live_alerts) > 0:
            for a in live_alerts:
                raw_alerts.append({
                    "id": str(a.get("id")),
                    "severity": str(a.get("severity", "CAUTION")).upper(),
                    "corridor": str(a.get("corridor", "NH-06 Sector")),
                    "title": str(a.get("title", "Active Alert")),
                    "description": str(a.get("message_en", a.get("title", ""))),
                    "time": "Recently",
                    "dispatched_at": str(a.get("dispatched_at", "")),
                    "acknowledged": bool(a.get("acknowledged_at")),
                    "acknowledged_at": str(a.get("acknowledged_at")) if a.get("acknowledged_at") else None,
                    "data_label": "LIVE",
                    "is_broadcast": bool(a.get("is_broadcast", True)),
                    "target_user_id": a.get("target_user_id"),
                    "target_role": a.get("target_role"),
                })
    except Exception:
        pass

    # 2. Local database query (if running and no supabase alerts)
    if not raw_alerts:
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
                for r in rows:
                    sev_raw = str(r[1]).upper()
                    sev_out = "EMERGENCY" if sev_raw == "CRITICAL" else ("CAUTION" if sev_raw == "MEDIUM" else ("INFO" if sev_raw == "LOW" else "HIGH RISK"))
                    raw_alerts.append({
                        "id": str(r[0]),
                        "severity": sev_out,
                        "corridor": str(r[2]),
                        "title": str(r[3]),
                        "description": str(r[4]),
                        "time": "Recently",
                        "dispatched_at": str(r[6]),
                        "acknowledged": bool(r[7]),
                        "acknowledged_at": str(r[8]) if r[8] else None,
                        "data_label": settings.DATA_LABEL,
                        "is_broadcast": True,
                        "target_user_id": None,
                        "target_role": None,
                    })
        except Exception:
            pass

    # Merge active in-memory alerts
    existing_ids = {a["id"] for a in raw_alerts}
    for mem_a in _IN_MEMORY_ALERTS:
        if mem_a["id"] not in existing_ids:
            raw_alerts.insert(0, mem_a)

    # Filter alerts targeted to this user / role or broadcast
    filtered = [
        AlertOut(**a) for a in raw_alerts
        if _can_user_receive_alert(a, current_user)
    ]
    return filtered


@router.post("", response_model=AlertOut, status_code=status.HTTP_201_CREATED)
async def create_alert(
    alert: AlertCreate,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Broadcast an official highway accessibility alert or send a targeted notification."""
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
        "is_broadcast": alert.is_broadcast,
        "target_user_id": alert.target_user_id,
        "target_role": alert.target_role,
    }

    db_sev = _SEVERITY_LEVEL_MAP.get(alert.severity.upper(), "MEDIUM")

    try:
        sql = text("""
            INSERT INTO alerts (
                id, severity, title, message_en, status, dispatched_at
            ) VALUES (
                gen_random_uuid(), :severity::severity_level, :title, :message, 'DISPATCHED'::alert_status, NOW()
            ) RETURNING id::text;
        """)
        res = await db.execute(sql, {
            "severity": db_sev,
            "title": alert.title,
            "message": alert.description,
        })
        await db.commit()
        db_id = res.scalar()
        if db_id:
            new_alert_dict["id"] = str(db_id)
    except Exception:
        await db.rollback()

    try:
        from backend.app.services.supabase_service import SupabaseService
        supa_res = await SupabaseService.create_alert({
            "severity": alert.severity.upper(),
            "corridor": alert.corridor,
            "title": alert.title,
            "message_en": alert.description,
            "status": "DISPATCHED",
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

    return [AlertOut(**a) for a in _IN_MEMORY_ALERTS]


@router.delete("/{alert_id}", status_code=status.HTTP_200_OK)
async def delete_alert(
    alert_id: str,
    db: AsyncSession = Depends(get_db_session),
):
    """Permanently delete an alert from database, Supabase, and active memory."""
    global _IN_MEMORY_ALERTS
    _IN_MEMORY_ALERTS = [a for a in _IN_MEMORY_ALERTS if a["id"] != alert_id]

    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.delete_alert(alert_id)
    except Exception:
        pass

    try:
        sql = text("DELETE FROM alerts WHERE id::text = :alert_id;")
        await db.execute(sql, {"alert_id": alert_id})
        await db.commit()
    except Exception:
        await db.rollback()

    return {"success": True, "alert_id": alert_id, "message": f"Alert {alert_id} permanently deleted"}


import asyncio
import json
from fastapi.responses import StreamingResponse

@router.get("/stream")
async def stream_alerts():
    """Real-time Server-Sent Events (SSE) stream for live highway alerts.
    
    Connected clients (Web Operations Console and Mobile App) receive live
    alert updates over a single persistent HTTP connection.
    """
    async def event_generator():
        # Send initial connection ping and current alerts
        initial_payload = {
            "type": "INIT_ALERTS",
            "count": len(_IN_MEMORY_ALERTS),
            "alerts": _IN_MEMORY_ALERTS[:10],
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        yield f"event: message\ndata: {json.dumps(initial_payload)}\n\n"

        # Stream periodic heartbeat or updates
        last_count = len(_IN_MEMORY_ALERTS)
        while True:
            await asyncio.sleep(5)
            current_count = len(_IN_MEMORY_ALERTS)
            if current_count != last_count:
                last_count = current_count
                update_payload = {
                    "type": "ALERTS_UPDATED",
                    "count": current_count,
                    "latest": _IN_MEMORY_ALERTS[0] if _IN_MEMORY_ALERTS else None,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
                yield f"event: alert\ndata: {json.dumps(update_payload)}\n\n"
            else:
                heartbeat = {"type": "HEARTBEAT", "timestamp": datetime.now(timezone.utc).isoformat()}
                yield f"event: ping\ndata: {json.dumps(heartbeat)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )

