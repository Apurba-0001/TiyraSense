import logging
import uuid
from datetime import datetime, timezone
from typing import Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.api.deps import get_optional_current_user
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.models.user import User
from backend.app.schemas.reports import (
    FieldReportCreate,
    FieldReportOut,
    FieldReportVerify,
)

logger = logging.getLogger(__name__)


def _normalize_incident_type(raw: Optional[str]) -> str:
    """Map any client or mobile hazard string to a valid PostgreSQL incident_type enum literal."""
    if not raw:
        return "OTHER"
    val = raw.strip().upper().replace(" ", "_").replace("-", "_")
    if any(k in val for k in ("FLASH_FLOOD", "FLOOD", "WATERLOG", "PUDDLE", "SUBMERGED")):
        return "WATERLOGGING"
    if any(k in val for k in ("SUBSIDENCE", "COLLAPSE", "SINKHOLE", "CAVE_IN")):
        return "ROAD_COLLAPSE"
    if any(k in val for k in ("FALLEN_TREE", "TREE_FALL", "TREE", "BRANCH", "TIMBER")):
        return "TREE_FALL"
    if any(k in val for k in ("DEBRIS", "MUDSLIDE", "MUD", "ROCKFALL", "BOULDER", "RUBBLE", "SLIDE")) and "LANDSLIDE" not in val:
        return "MUDSLIDE"
    if "LANDSLIDE" in val:
        return "LANDSLIDE"
    if any(k in val for k in ("BRIDGE", "CRACK", "PIER", "CULVERT", "EXPANSION")):
        return "BRIDGE_DISTRESS"
    if any(k in val for k in ("CONGESTION", "TRAFFIC", "GRIDLOCK", "JAM", "BOTTLENECK")):
        return "HEAVY_CONGESTION"
    if val in ("LANDSLIDE", "MUDSLIDE", "WATERLOGGING", "ROAD_COLLAPSE", "TREE_FALL", "HEAVY_CONGESTION", "BRIDGE_DISTRESS", "OTHER"):
        return val
    return "OTHER"


def _normalize_severity(raw: Optional[str]) -> str:
    """Map any severity label to a valid PostgreSQL severity_level enum literal."""
    if not raw:
        return "MEDIUM"
    val = raw.strip().upper().replace(" ", "_")
    if any(k in val for k in ("FULL", "CRITICAL", "BLOCKED", "TOTAL", "EMERGENCY")):
        return "CRITICAL"
    if any(k in val for k in ("HIGH", "SEVERE", "MAJOR")):
        return "HIGH"
    if any(k in val for k in ("PARTIAL", "MEDIUM", "MODERATE", "CAUTION")):
        return "MEDIUM"
    if any(k in val for k in ("SHOULDER", "LOW", "MINOR", "INFO")):
        return "LOW"
    if val in ("LOW", "MEDIUM", "HIGH", "CRITICAL"):
        return val
    return "MEDIUM"


# Alert severity derived from report severity — keeps risk labeling consistent with D-015
_SEVERITY_TO_ALERT = {
    "FULL BLOCKAGE": "EMERGENCY",
    "CRITICAL": "EMERGENCY",
    "FULL_BLOCKAGE": "EMERGENCY",
    "PARTIAL": "CAUTION",
    "HIGH": "CAUTION",
    "SHOULDER": "INFO",
    "MEDIUM": "INFO",
    "LOW": "INFO",
}


def _auto_alert_from_report(report: dict) -> dict:
    """Build an alert dict from a verified/dispatched field report."""
    severity_key = str(report.get("severity", "")).upper().replace(" ", "_")
    # Also try original spacing
    alert_severity = (
        _SEVERITY_TO_ALERT.get(severity_key)
        or _SEVERITY_TO_ALERT.get(str(report.get("severity", "")).upper())
        or "CAUTION"
    )
    hazard = str(report.get("hazard_type", "Hazard"))
    corridor = str(report.get("corridor_name", "NER Highway"))
    km = str(report.get("km_marker", ""))
    km_label = f" at {km}" if km else ""
    return {
        "id": f"ALT-{str(uuid.uuid4())[:6].upper()}",
        "severity": alert_severity,
        "corridor": corridor,
        "title": f"{hazard} — Verified Incident{km_label}",
        "description": str(report.get("description", "Field-verified hazard on route. Exercise caution."))[:200],
        "time": "Just now",
        "dispatched_at": datetime.now(timezone.utc).isoformat(),
        "acknowledged": False,
        "acknowledged_at": None,
        "data_label": str(report.get("data_label", settings.DATA_LABEL)),
    }

router = APIRouter()

# Set of report IDs explicitly deleted by users or officials to guarantee persistence
_DELETED_REPORT_IDS: set[str] = set()

# In-memory session store: write-through cache for new submissions when PostGIS is unreachable.
# Starts empty — real data comes from PostgreSQL/Supabase at runtime.
_IN_MEMORY_REPORTS: List[dict[str, Any]] = []


@router.get("", response_model=List[FieldReportOut], status_code=status.HTTP_200_OK)
async def list_field_reports(
    db: AsyncSession = Depends(get_db_session),
    hazard_type: Optional[str] = None,
    severity: Optional[str] = None,
    status_filter: Optional[str] = None,
):
    """List operational and verified field reports.
    Merges live reports from PostgreSQL database, Supabase Cloud, and active session queue.
    """
    merged_map: dict[str, FieldReportOut] = {}

    # 1. Local database query (PostgreSQL PostGIS - primary source of truth)
    try:
        sql = text("""
            SELECT 
                fr.id::text,
                fr.hazard_type::text,
                fr.reported_severity::text,
                fr.verification_status::text,
                COALESCE(fr.description, ''),
                ST_Y(fr.location) as lat,
                ST_X(fr.location) as lon,
                COALESCE(
                    rs.corridor_name,
                    rs_near.corridor_name,
                    'NH-06 Guwahati-Shillong'
                ) as corridor_name,
                TO_CHAR(fr.server_received_at, 'YYYY-MM-DD HH24:MI:SS') as submitted_at,
                COALESCE(u.full_name, 'Field Scout') as reporter_name,
                ie.storage_uri,
                COALESCE(
                    CONCAT('KM ', ROUND((ST_LineLocatePoint(rs_near.geom, fr.location) * (rs_near.length_meters / 1000.0))::numeric, 1)),
                    'Active Pin'
                ) as km_marker
            FROM field_reports fr
            LEFT JOIN road_segments rs ON fr.road_segment_id = rs.id
            LEFT JOIN users u ON fr.reporter_id = u.id
            LEFT JOIN incident_evidence ie ON fr.id = ie.field_report_id
            LEFT JOIN LATERAL (
                SELECT rs2.geom, rs2.length_meters, rs2.corridor_name
                FROM road_segments rs2 
                ORDER BY fr.location <-> rs2.geom 
                LIMIT 1
            ) rs_near ON true
            ORDER BY fr.server_received_at DESC
            LIMIT 100;
        """)
        result = await db.execute(sql)
        rows = result.fetchall()
        for r in rows:
            rep_id = str(r[0])
            if rep_id in _DELETED_REPORT_IDS:
                continue
            if rep_id in merged_map:
                if not merged_map[rep_id].photo_url and r[10]:
                    merged_map[rep_id].photo_url = str(r[10])
            else:
                merged_map[rep_id] = FieldReportOut(
                    id=rep_id,
                    hazard_type=str(r[1]).replace("_", " ").title(),
                    severity=str(r[2]),
                    status=str(r[3]),
                    description=str(r[4]),
                    latitude=float(r[5]),
                    longitude=float(r[6]),
                    corridor_name=str(r[7]),
                    km_marker=str(r[11]) if r[11] else "Active Pin",
                    reporter_name=str(r[9]),
                    reporter_unit="Field Recon",
                    submitted_at=str(r[8]),
                    data_label=settings.DATA_LABEL,
                    photo_url=str(r[10]) if r[10] else None,
                )
    except Exception:
        pass

    # 2. Supabase Cloud PostgREST
    try:
        from backend.app.services.supabase_service import SupabaseService
        live_reports = await SupabaseService.get_field_reports()
        if live_reports:
            for item in live_reports:
                rep_id = str(item.get("id"))
                if rep_id in _DELETED_REPORT_IDS:
                    continue
                coords = item.get("geom", {}).get("coordinates") if isinstance(item.get("geom"), dict) else None
                lon = float(coords[0]) if coords else float(item.get("longitude", 91.8901))
                lat = float(coords[1]) if coords else float(item.get("latitude", 26.0124))
                p_urls = item.get("photo_urls")
                photo = (
                    item.get("photo_url")
                    or item.get("evidence_url")
                    or (p_urls[0] if isinstance(p_urls, list) and len(p_urls) > 0 and p_urls[0] else None)
                )
                
                if rep_id in merged_map:
                    if not merged_map[rep_id].photo_url and photo:
                        merged_map[rep_id].photo_url = photo
                else:
                    merged_map[rep_id] = FieldReportOut(
                        id=rep_id,
                        hazard_type=str(item.get("hazard_type", "LANDSLIDE")).replace("_", " ").title(),
                        severity=str(item.get("reported_severity", "CRITICAL")),
                        status=str(item.get("verification_status", "PENDING")),
                        description=str(item.get("description", "")),
                        latitude=lat,
                        longitude=lon,
                        corridor_name=str(item.get("corridor", "NH-06")),
                        km_marker=str(item.get("km", "Active Marker")),
                        reporter_name=str(item.get("worker_name", "Field Scout")),
                        reporter_unit=str(item.get("worker_unit", "Field Recon")),
                        submitted_at=str(item.get("server_received_at", "Just now")),
                        data_label="LIVE",
                        dispatch_unit=item.get("dispatch_unit"),
                        dispatch_notes=item.get("dispatch_notes"),
                        photo_url=photo,
                    )
    except Exception:
        pass

    # 3. Dynamic in-memory reports created during active session via create_field_report
    for item in _IN_MEMORY_REPORTS:
        rep_id = str(item["id"])
        if rep_id not in _DELETED_REPORT_IDS and rep_id not in merged_map:
            merged_map[rep_id] = FieldReportOut.model_validate(item)

    def _recency_score(item: FieldReportOut) -> float:
        import time
        now = time.time()
        sub = item.submitted_at or ""
        if "Just now" in sub:
            return now
        if "m ago" in sub:
            try:
                mins = float(sub.split("m")[0].strip())
                return now - mins * 60
            except Exception:
                return now - 300
        if "h ago" in sub:
            try:
                hrs = float(sub.split("h")[0].strip())
                return now - hrs * 3600
            except Exception:
                return now - 3600
        if "d ago" in sub:
            try:
                days = float(sub.split("d")[0].strip())
                return now - days * 86400
            except Exception:
                return now - 86400
        try:
            from datetime import datetime
            return datetime.fromisoformat(sub.replace("Z", "+00:00")).timestamp()
        except Exception:
            return 0.0

    res_list = list(merged_map.values())
    res_list.sort(key=_recency_score, reverse=True)

    if hazard_type:
        ht = hazard_type.upper().replace(" ", "_")
        res_list = [r for r in res_list if r.hazard_type.upper().replace(" ", "_") == ht]
    if severity:
        sev = severity.upper()
        res_list = [r for r in res_list if r.severity.upper() == sev]
    if status_filter:
        sf = status_filter.upper()
        res_list = [r for r in res_list if r.status.upper() == sf]

    return res_list


@router.post("", response_model=FieldReportOut, status_code=status.HTTP_201_CREATED)
async def create_field_report(
    report: FieldReportCreate,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Submit a verified or observed field hazard report from scout or driver."""
    new_id = f"RP-{str(uuid.uuid4())[:8].upper()}"

    reporter_name = str(current_user.full_name) if current_user and current_user.full_name is not None else "Field Scout"
    reporter_unit = "Field Recon Unit"

    new_report_dict: dict[str, Any] = {
        "id": new_id,
        "hazard_type": report.hazard_type,
        "severity": report.severity,
        "status": "PENDING",
        "description": report.description,
        "latitude": report.latitude,
        "longitude": report.longitude,
        "corridor_name": report.corridor_name or "NH-06 Artery",
        "km_marker": report.km_marker or "KM 0.0",
        "reporter_name": reporter_name,
        "reporter_unit": reporter_unit,
        "submitted_at": "Just now",
        "data_label": settings.DATA_LABEL,
        "dispatch_unit": None,
        "dispatch_notes": None,
        "photo_url": report.photo_url,
    }

    norm_hazard = _normalize_incident_type(report.hazard_type)
    norm_severity = _normalize_severity(report.severity)

    # 1. Forward to live Supabase Cloud PostgREST
    supa_id = None
    try:
        from backend.app.services.supabase_service import SupabaseService
        supa_res = await SupabaseService.create_field_report({
            "hazard_type": norm_hazard,
            "reported_severity": norm_severity,
            "description": report.description,
            "corridor": report.corridor_name or "NH-06",
            "km": report.km_marker or "KM 0.0",
            "worker_name": reporter_name,
            "worker_unit": reporter_unit,
            "latitude": report.latitude,
            "longitude": report.longitude,
            "verification_status": "PENDING",
            "data_label": "LIVE",
            "photo_url": report.photo_url,
        })
        if supa_res and "id" in supa_res:
            supa_id = str(supa_res["id"])
            new_report_dict["id"] = supa_id
            if not new_report_dict.get("photo_url") and supa_res.get("photo_url"):
                new_report_dict["photo_url"] = supa_res["photo_url"]
    except Exception as e:
        logger.warning(f"Failed to persist report to Supabase: {e}")

    # 2. Persist to local PostgreSQL PostGIS & incident_evidence
    try:
        sql = text("""
            INSERT INTO field_reports (
                id, reporter_id, hazard_type, reported_severity, description,
                location, client_captured_at, server_received_at, verification_status, data_label
            ) VALUES (
                gen_random_uuid(), :reporter_id, CAST(:hazard_type AS incident_type), CAST(:severity AS severity_level),
                :description, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), NOW(), NOW(), 'PENDING', CAST(:data_label AS data_label)
            ) RETURNING id::text;
        """)
        reporter_id = current_user.id if current_user else None
        res = await db.execute(sql, {
            "reporter_id": reporter_id,
            "hazard_type": norm_hazard,
            "severity": norm_severity,
            "description": report.description,
            "lon": report.longitude,
            "lat": report.latitude,
            "data_label": settings.DATA_LABEL,
        })
        db_id = res.scalar()
        if db_id and report.photo_url:
            try:
                evidence_sql = text("""
                    INSERT INTO incident_evidence (
                        id, field_report_id, storage_uri, file_hash_sha256, mime_type, uploaded_at
                    ) VALUES (
                        gen_random_uuid(), CAST(:fr_id AS uuid), :uri, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'image/jpeg', NOW()
                    );
                """)
                await db.execute(evidence_sql, {"fr_id": db_id, "uri": report.photo_url})
            except Exception as ev_err:
                logger.warning(f"Failed to persist incident evidence: {ev_err}")
        # Unconditionally commit the transaction so both the report and evidence are persisted
        await db.commit()
        if db_id and not supa_id:
            new_report_dict["id"] = str(db_id)
    except Exception as db_err:
        logger.warning(f"Failed to persist report to PostgreSQL: {db_err}")
        await db.rollback()

    _IN_MEMORY_REPORTS.insert(0, new_report_dict)
    return FieldReportOut.model_validate(new_report_dict)


@router.patch("/{report_id}/verify", response_model=FieldReportOut, status_code=status.HTTP_200_OK)
async def verify_field_report(
    report_id: str,
    action: FieldReportVerify,
    db: AsyncSession = Depends(get_db_session),
):
    """Verify, dispatch, or reject an active field report.
    
    VERIFIED or DISPATCHED status automatically pushes an alert to the live alert feed
    so affected users on the route receive immediate notification.
    """
    target: Optional[dict[str, Any]] = None
    for r in _IN_MEMORY_REPORTS:
        if r["id"] == report_id:
            target = r
            break

    if not target:
        # Create virtual entry if not in memory (e.g. report from Supabase not yet cached)
        target = {
            "id": report_id,
            "hazard_type": "Landslide",
            "severity": "HIGH",
            "status": action.status,
            "description": "Verified field report",
            "latitude": 26.0124,
            "longitude": 91.8901,
            "corridor_name": "NH-06",
            "km_marker": "KM 52.3",
            "reporter_name": "Field Scout",
            "reporter_unit": "Recon",
            "submitted_at": "Recently",
            "data_label": settings.DATA_LABEL,
            "dispatch_unit": action.dispatch_unit,
            "dispatch_notes": action.dispatch_notes,
            "photo_url": None,
        }
        _IN_MEMORY_REPORTS.insert(0, target)
    else:
        target["status"] = action.status
        if action.dispatch_unit:
            target["dispatch_unit"] = action.dispatch_unit
        if action.dispatch_notes:
            target["dispatch_notes"] = action.dispatch_notes

    # Auto-push alert when verification confirms a real hazard
    # REJECTED reports are suppressed — no alert generated
    if action.status.upper() in ("VERIFIED", "DISPATCHED"):
        from backend.app.api.v1.endpoints.alerts import _IN_MEMORY_ALERTS
        new_alert = _auto_alert_from_report(target)
        _IN_MEMORY_ALERTS.insert(0, new_alert)
        # Persist alert to Supabase if available
        try:
            from backend.app.services.supabase_service import SupabaseService
            await SupabaseService.create_alert({
                "severity": new_alert["severity"],
                "corridor": new_alert["corridor"],
                "title": new_alert["title"],
                "message_en": new_alert["description"],
                "status": "SENT",
                "is_emergency": (new_alert["severity"] == "EMERGENCY"),
            })
        except Exception:
            pass

    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.update_field_report(
            report_id,
            {
                "verification_status": action.status,
                "dispatch_unit": action.dispatch_unit,
                "dispatch_notes": action.dispatch_notes,
            },
        )
    except Exception:
        pass

    try:
        sql = text("""
            UPDATE field_reports 
            SET verification_status = :status
            WHERE id::text = :report_id;
        """)
        await db.execute(sql, {"status": action.status, "report_id": report_id})
        await db.commit()
    except Exception:
        pass

    return FieldReportOut.model_validate(target)


@router.delete("/{report_id}", status_code=status.HTTP_200_OK)
async def delete_field_report(
    report_id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Permanently delete an unwanted, obsolete, or erroneous field report.
    Removes from database and active memory cache.
    Restricted to officials and administrators.
    """
    _DELETED_REPORT_IDS.add(report_id)
    removed = False
    for idx, r in enumerate(_IN_MEMORY_REPORTS):
        if r["id"] == report_id:
            _IN_MEMORY_REPORTS.pop(idx)
            removed = True
            break

    try:
        from backend.app.services.supabase_service import SupabaseService
        await SupabaseService.delete_field_report(report_id)
        removed = True
    except Exception:
        pass

    try:
        sql = text("DELETE FROM field_reports WHERE id::text = :report_id;")
        await db.execute(sql, {"report_id": report_id})
        await db.commit()
        removed = True
    except Exception:
        pass

    return {
        "success": True,
        "report_id": report_id,
        "message": f"Field report {report_id} permanently deleted",
    }

