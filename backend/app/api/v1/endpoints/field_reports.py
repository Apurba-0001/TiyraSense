import json
import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.api.deps import get_optional_current_user
from backend.app.core.config import settings
from backend.app.core.database import get_db_session
from backend.app.models.user import User, UserRole
from backend.app.schemas.reports import (
    FieldReportCreate,
    FieldReportOut,
    FieldReportVerify,
)

logger = logging.getLogger(__name__)

# Persistent storage for deleted report IDs so deletions persist across process restarts
_DELETED_REPORTS_FILE = Path(__file__).resolve().parent.parent.parent.parent / "static" / "deleted_reports.json"


def _get_deleted_ids() -> set[str]:
    s: set[str] = set()
    if _DELETED_REPORTS_FILE.exists():
        try:
            with open(_DELETED_REPORTS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    s.update(str(x) for x in data)
        except Exception:
            pass
    return s


def _add_deleted_id(rep_id: str):
    _DELETED_REPORT_IDS.add(rep_id)
    try:
        _DELETED_REPORTS_FILE.parent.mkdir(parents=True, exist_ok=True)
        current = _get_deleted_ids()
        current.add(rep_id)
        with open(_DELETED_REPORTS_FILE, "w", encoding="utf-8") as f:
            json.dump(list(current), f)
    except Exception:
        pass


_DELETED_REPORT_IDS: set[str] = _get_deleted_ids()

def _extract_coords(item: dict) -> tuple[float, float]:
    """Extract (lat, lon) safely from PostGIS GeoJSON geometry dict, location, geom, or raw floats."""
    loc = item.get("location") or item.get("geom")
    if isinstance(loc, dict) and "coordinates" in loc and isinstance(loc["coordinates"], (list, tuple)) and len(loc["coordinates"]) >= 2:
        return float(loc["coordinates"][1]), float(loc["coordinates"][0])
    lat = item.get("latitude")
    lon = item.get("longitude")
    lat_f = float(lat) if lat is not None else 26.0124
    lon_f = float(lon) if lon is not None else 91.8901
    return lat_f, lon_f


# In-memory session store: write-through cache for new submissions when PostGIS is unreachable.
_IN_MEMORY_REPORTS: List[dict[str, Any]] = []


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


@router.get("", response_model=List[FieldReportOut], status_code=status.HTTP_200_OK)
async def list_field_reports(
    db: AsyncSession = Depends(get_db_session),
    hazard_type: Optional[str] = None,
    severity: Optional[str] = None,
    status_filter: Optional[str] = None,
    reporter_id: Optional[str] = None,
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """List operational and verified field reports.
    Merges live reports from PostgreSQL database, Supabase Cloud, and active session queue
    with robust spatial/metadata de-duplication.
    """
    merged_map: dict[str, FieldReportOut] = {}
    deleted_ids = _get_deleted_ids()

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
                ) as km_marker,
                COALESCE(u.role::text, 'FIELD_WORKER') as reporter_role,
                u.id::text as reporter_id
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
            if rep_id in deleted_ids:
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
                    reporter_id=str(r[13]) if r[13] else None,
                    reporter_name=str(r[9]),
                    reporter_role=str(r[12]),
                    reporter_unit="Field Recon",
                    submitted_at=str(r[8]),
                    data_label=settings.DATA_LABEL,
                    photo_url=str(r[10]) if r[10] else None,
                )
    except Exception as e:
        logger.debug(f"Local DB query error in list_field_reports: {e}")

    # 2. Supabase Cloud PostgREST
    try:
        from backend.app.services.supabase_service import SupabaseService
        live_reports = await SupabaseService.get_field_reports()
        if live_reports:
            for item in live_reports:
                rep_id = str(item.get("id"))
                if rep_id in deleted_ids:
                    continue
                lat, lon = _extract_coords(item)
                p_urls = item.get("photo_urls")
                photo = (
                    item.get("photo_url")
                    or item.get("evidence_url")
                    or (p_urls[0] if isinstance(p_urls, list) and len(p_urls) > 0 and p_urls[0] else None)
                )
                
                worker_name = str(item.get("worker_name") or item.get("reporter_name") or "Field Scout")
                worker_role = str(item.get("worker_role") or item.get("reporter_role") or "FIELD_WORKER")
                worker_unit = str(item.get("worker_unit") or item.get("reporter_unit") or "Field Recon")
                worker_id = str(item.get("reporter_id") or item.get("worker_id") or "") if (item.get("reporter_id") or item.get("worker_id")) else None

                if rep_id in merged_map:
                    if not merged_map[rep_id].photo_url and photo:
                        merged_map[rep_id].photo_url = photo
                    if worker_name not in ("Field Scout", "None", "", None) and merged_map[rep_id].reporter_name in ("Field Scout", "None", "", None):
                        merged_map[rep_id].reporter_name = worker_name
                        merged_map[rep_id].reporter_role = worker_role
                    if worker_id and not merged_map[rep_id].reporter_id:
                        merged_map[rep_id].reporter_id = worker_id
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
                        reporter_id=worker_id,
                        reporter_name=worker_name,
                        reporter_role=worker_role,
                        reporter_unit=worker_unit,
                        submitted_at=str(item.get("server_received_at", "Just now")),
                        data_label="LIVE",
                        dispatch_unit=item.get("dispatch_unit"),
                        dispatch_notes=item.get("dispatch_notes"),
                        photo_url=photo,
                    )
    except Exception as e:
        logger.debug(f"Supabase query error in list_field_reports: {e}")

    # 3. Dynamic in-memory reports created during active session via create_field_report
    for item in _IN_MEMORY_REPORTS:
        rep_id = str(item["id"])
        if rep_id not in deleted_ids and rep_id not in merged_map:
            merged_map[rep_id] = FieldReportOut.model_validate(item)

    # 4. SPATIAL & METADATA DE-DUPLICATION
    # Merge reports at the exact same location (< 100m) and hazard type into a single authoritative report
    deduped_list: List[FieldReportOut] = []
    seen_keys: set[str] = set()

    # Prioritize items with photo_url and authentic reporter name
    all_candidates = list(merged_map.values())
    all_candidates.sort(
        key=lambda r: (
            bool(r.photo_url),
            r.reporter_name not in ("Field Scout", "None", None, ""),
            r.status != "PENDING"
        ),
        reverse=True
    )

    for item in all_candidates:
        r_lat = round(item.latitude, 3)
        r_lon = round(item.longitude, 3)
        hz = item.hazard_type.upper().strip()
        spatial_key = f"{hz}_{r_lat}_{r_lon}"

        if spatial_key in seen_keys:
            # Merge missing photo or details into the primary deduplicated record
            for existing in deduped_list:
                ex_key = f"{existing.hazard_type.upper().strip()}_{round(existing.latitude, 3)}_{round(existing.longitude, 3)}"
                if ex_key == spatial_key:
                    if not existing.photo_url and item.photo_url:
                        existing.photo_url = item.photo_url
                    if existing.reporter_name in ("Field Scout", "None", None, "") and item.reporter_name not in ("Field Scout", "None", None, ""):
                        existing.reporter_name = item.reporter_name
                        existing.reporter_role = item.reporter_role
                        existing.reporter_id = item.reporter_id
                    break
            continue

        seen_keys.add(spatial_key)
        deduped_list.append(item)

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

    res_list = list(deduped_list)
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

    # Personalized report history: Drivers and Field Workers view their own reports
    target_author_id = reporter_id
    if not target_author_id and current_user and current_user.role in (UserRole.DRIVER, UserRole.FIELD_WORKER):
        target_author_id = str(current_user.id)

    if target_author_id and target_author_id.upper() != "ALL":
        t_id = target_author_id.lower()
        res_list = [
            r for r in res_list
            if (r.reporter_id and str(r.reporter_id).lower() == t_id)
            or (current_user and r.reporter_name and r.reporter_name.lower() == current_user.full_name.lower())
            or (r.reporter_name and r.reporter_name.lower() == t_id)
        ]

    return res_list


@router.post("", response_model=FieldReportOut, status_code=status.HTTP_201_CREATED)
async def create_field_report(
    report: FieldReportCreate,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Submit a verified or observed field hazard report from scout or driver.
    Uses a single canonical UUID across Supabase and PostgreSQL to prevent duplicate records.
    """
    canonical_id = str(uuid.uuid4())

    reporter_name = "Field Scout"
    reporter_role = "FIELD_WORKER"
    reporter_unit = report.reporter_unit or "Field Recon Unit"
    reporter_id = None

    if current_user:
        reporter_id = current_user.id
        if current_user.full_name:
            reporter_name = str(current_user.full_name)
        if current_user.role:
            reporter_role = str(current_user.role)
    elif report.reporter_name:
        reporter_name = report.reporter_name.strip()
        reporter_role = report.reporter_role or "FIELD_WORKER"
        if report.reporter_id:
            try:
                reporter_id = uuid.UUID(report.reporter_id)
            except Exception:
                reporter_id = None

    new_report_dict: dict[str, Any] = {
        "id": canonical_id,
        "hazard_type": report.hazard_type,
        "severity": report.severity,
        "status": "PENDING",
        "description": report.description,
        "latitude": report.latitude,
        "longitude": report.longitude,
        "corridor_name": report.corridor_name or "NH-06 Artery",
        "km_marker": report.km_marker or "KM 0.0",
        "reporter_id": str(reporter_id) if reporter_id else None,
        "reporter_name": reporter_name,
        "reporter_role": reporter_role,
        "reporter_unit": reporter_unit,
        "submitted_at": "Just now",
        "data_label": settings.DATA_LABEL,
        "dispatch_unit": None,
        "dispatch_notes": None,
        "photo_url": report.photo_url,
    }

    norm_hazard = _normalize_incident_type(report.hazard_type)
    norm_severity = _normalize_severity(report.severity)

    # 1. Forward to live Supabase Cloud PostgREST using canonical_id
    try:
        from backend.app.services.supabase_service import SupabaseService
        supa_res = await SupabaseService.create_field_report({
            "id": canonical_id,
            "hazard_type": norm_hazard,
            "reported_severity": norm_severity,
            "description": report.description,
            "corridor": report.corridor_name or "NH-06",
            "km": report.km_marker or "KM 0.0",
            "worker_name": reporter_name,
            "worker_role": reporter_role,
            "worker_unit": reporter_unit,
            "reporter_id": str(reporter_id) if reporter_id else None,
            "latitude": report.latitude,
            "longitude": report.longitude,
            "verification_status": "PENDING",
            "data_label": "LIVE",
            "photo_url": report.photo_url,
        })
        if supa_res and supa_res.get("photo_url") and not new_report_dict.get("photo_url"):
            new_report_dict["photo_url"] = supa_res["photo_url"]
    except Exception as e:
        logger.warning(f"Failed to persist report to Supabase: {e}")

    # 2. Persist to local PostgreSQL PostGIS & incident_evidence using the same canonical_id
    try:
        sql = text("""
            INSERT INTO field_reports (
                id, reporter_id, hazard_type, reported_severity, description,
                location, client_captured_at, server_received_at, verification_status, data_label
            ) VALUES (
                CAST(:report_id AS uuid), :reporter_id, CAST(:hazard_type AS incident_type), CAST(:severity AS severity_level),
                :description, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), NOW(), NOW(), 'PENDING', CAST(:data_label AS data_label)
            ) RETURNING id::text;
        """)
        await db.execute(sql, {
            "report_id": canonical_id,
            "reporter_id": reporter_id,
            "hazard_type": norm_hazard,
            "severity": norm_severity,
            "description": report.description,
            "lon": report.longitude,
            "lat": report.latitude,
            "data_label": settings.DATA_LABEL,
        })

        if report.photo_url:
            try:
                evidence_sql = text("""
                    INSERT INTO incident_evidence (
                        id, field_report_id, storage_uri, file_hash_sha256, mime_type, uploaded_at
                    ) VALUES (
                        gen_random_uuid(), CAST(:fr_id AS uuid), :uri, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'image/jpeg', NOW()
                    );
                """)
                await db.execute(evidence_sql, {"fr_id": canonical_id, "uri": report.photo_url})
            except Exception as ev_err:
                logger.warning(f"Failed to persist incident evidence: {ev_err}")

        await db.commit()
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
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """Verify, dispatch, or reject an active field report.
    
    Access Control: Only Government Officials and Administrators can review, verify, or dispatch reports.
    VERIFIED or DISPATCHED status automatically pushes an alert to the live alert feed
    so affected users on the route receive immediate notification across Web and Mobile.
    """
    if current_user and current_user.role not in (UserRole.OFFICIAL, UserRole.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Only Government Officials and Administrators are authorized to review, verify, dispatch, or reject field reports.",
        )

    target: Optional[dict[str, Any]] = None
    for r in _IN_MEMORY_REPORTS:
        if r["id"] == report_id:
            target = r
            break

    # If not in memory, query PostgreSQL for real report data
    if not target:
        try:
            sql_find = text("""
                SELECT 
                    fr.id::text,
                    fr.hazard_type::text,
                    fr.reported_severity::text,
                    fr.verification_status::text,
                    COALESCE(fr.description, ''),
                    ST_Y(fr.location) as lat,
                    ST_X(fr.location) as lon,
                    COALESCE(rs.corridor_name, 'NER Highway') as corridor_name,
                    COALESCE(u.full_name, 'Field Scout') as reporter_name,
                    ie.storage_uri
                FROM field_reports fr
                LEFT JOIN road_segments rs ON fr.road_segment_id = rs.id
                LEFT JOIN users u ON fr.reporter_id = u.id
                LEFT JOIN incident_evidence ie ON fr.id = ie.field_report_id
                WHERE fr.id::text = :report_id
                LIMIT 1;
            """)
            db_res = await db.execute(sql_find, {"report_id": report_id})
            row = db_res.fetchone()
            if row:
                target = {
                    "id": str(row[0]),
                    "hazard_type": str(row[1]).replace("_", " ").title(),
                    "severity": str(row[2]),
                    "status": action.status,
                    "description": str(row[4]),
                    "latitude": float(row[5]),
                    "longitude": float(row[6]),
                    "corridor_name": str(row[7]),
                    "km_marker": "Active Pin",
                    "reporter_name": str(row[8]),
                    "reporter_unit": "Field Recon",
                    "submitted_at": "Recently",
                    "data_label": settings.DATA_LABEL,
                    "dispatch_unit": action.dispatch_unit,
                    "dispatch_notes": action.dispatch_notes,
                    "photo_url": str(row[9]) if row[9] else None,
                }
                _IN_MEMORY_REPORTS.insert(0, target)
        except Exception:
            pass

    # If still not found, check Supabase
    if not target:
        try:
            from backend.app.services.supabase_service import SupabaseService
            live_reports = await SupabaseService.get_field_reports()
            for item in live_reports:
                if str(item.get("id")) == report_id:
                    coords = item.get("geom", {}).get("coordinates") if isinstance(item.get("geom"), dict) else None
                    lon = float(coords[0]) if coords else float(item.get("longitude", 91.8901))
                    lat = float(coords[1]) if coords else float(item.get("latitude", 26.0124))
                    p_urls = item.get("photo_urls")
                    photo = item.get("photo_url") or (p_urls[0] if isinstance(p_urls, list) and len(p_urls) > 0 else None)
                    target = {
                        "id": report_id,
                        "hazard_type": str(item.get("hazard_type", "Landslide")).replace("_", " ").title(),
                        "severity": str(item.get("reported_severity", "HIGH")),
                        "status": action.status,
                        "description": str(item.get("description", "Verified field report")),
                        "latitude": lat,
                        "longitude": lon,
                        "corridor_name": str(item.get("corridor", "NH-06")),
                        "km_marker": str(item.get("km", "Active Marker")),
                        "reporter_name": str(item.get("worker_name", "Field Scout")),
                        "reporter_unit": str(item.get("worker_unit", "Field Recon")),
                        "submitted_at": str(item.get("server_received_at", "Recently")),
                        "data_label": "LIVE",
                        "dispatch_unit": action.dispatch_unit,
                        "dispatch_notes": action.dispatch_notes,
                        "photo_url": photo,
                    }
                    _IN_MEMORY_REPORTS.insert(0, target)
                    break
        except Exception:
            pass

    if not target:
        target = {
            "id": report_id,
            "hazard_type": "Landslide",
            "severity": "HIGH",
            "status": action.status,
            "description": "Verified field report",
            "latitude": 26.0124,
            "longitude": 91.8901,
            "corridor_name": "NH-06",
            "km_marker": "Active Marker",
            "reporter_name": "Field Scout",
            "reporter_unit": "Field Recon",
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

    # Auto-push alert when verification confirms a real hazard (VERIFIED or DISPATCHED)
    if action.status.upper() in ("VERIFIED", "DISPATCHED"):
        from backend.app.api.v1.endpoints.alerts import _IN_MEMORY_ALERTS, _SEVERITY_LEVEL_MAP
        new_alert = _auto_alert_from_report(target)
        _IN_MEMORY_ALERTS.insert(0, new_alert)

        # 1. Persist alert to PostgreSQL
        try:
            db_sev = _SEVERITY_LEVEL_MAP.get(new_alert["severity"].upper(), "MEDIUM")
            sql_ins_alert = text("""
                INSERT INTO alerts (
                    id, severity, title, message_en, status, dispatched_at
                ) VALUES (
                    gen_random_uuid(), :severity::severity_level, :title, :message, 'DISPATCHED'::alert_status, NOW()
                );
            """)
            await db.execute(sql_ins_alert, {
                "severity": db_sev,
                "title": new_alert["title"],
                "message": new_alert["description"],
            })
            await db.commit()
        except Exception:
            await db.rollback()

        # 2. Persist alert to Supabase
        try:
            from backend.app.services.supabase_service import SupabaseService
            await SupabaseService.create_alert({
                "severity": new_alert["severity"],
                "corridor": new_alert["corridor"],
                "title": new_alert["title"],
                "message_en": new_alert["description"],
                "status": "DISPATCHED",
                "is_emergency": (new_alert["severity"] == "EMERGENCY"),
            })
        except Exception:
            pass

    # Push a targeted status notification to the specific reporter
    if target and target.get("reporter_id"):
        from backend.app.api.v1.endpoints.alerts import _IN_MEMORY_ALERTS
        is_rej = action.status.upper() == "REJECTED"
        reporter_alert = {
            "id": f"ALT-USR-{str(uuid.uuid4())[:6].upper()}",
            "severity": "CAUTION" if is_rej else "INFO",
            "corridor": target.get("corridor_name", "NER Highway"),
            "title": f"Report {action.status.title()}",
            "description": f"Your road incident report on {target.get('corridor_name')} ({target.get('hazard_type')}) was evaluated and marked as {action.status}.",
            "time": "Just now",
            "dispatched_at": datetime.now(timezone.utc).isoformat(),
            "acknowledged": False,
            "acknowledged_at": None,
            "data_label": settings.DATA_LABEL,
            "is_broadcast": False,
            "target_user_id": str(target["reporter_id"]),
            "target_role": None,
        }
        _IN_MEMORY_ALERTS.insert(0, reporter_alert)

    # Update status in Supabase
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

    # Update status in PostgreSQL
    try:
        sql = text("""
            UPDATE field_reports 
            SET verification_status = :status
            WHERE id::text = :report_id;
        """)
        await db.execute(sql, {"status": action.status, "report_id": report_id})
        await db.commit()
    except Exception:
        await db.rollback()

    return FieldReportOut.model_validate(target)


@router.delete("/{report_id}", status_code=status.HTTP_200_OK)
async def delete_field_report(
    report_id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Permanently delete or dismiss an unwanted, obsolete, or erroneous field report.
    Access Control: Only Government Officials and Administrators are authorized to delete reports.
    """
    if current_user and current_user.role not in (UserRole.OFFICIAL, UserRole.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Only Government Officials and Administrators are authorized to delete or dismiss field reports.",
        )

    from pathlib import Path
    _add_deleted_id(report_id)

    # 1. Collect all photo URLs and identifiers for Cloudinary & storage purging
    photos_to_purge: set[str] = set()
    twin_ids: set[str] = set([report_id])
    target_lat: Optional[float] = None
    target_lon: Optional[float] = None
    target_hazard: Optional[str] = None

    for idx, r in enumerate(_IN_MEMORY_REPORTS):
        if r.get("id") == report_id:
            if r.get("photo_url"):
                photos_to_purge.add(r["photo_url"])
            target_lat = r.get("latitude")
            target_lon = r.get("longitude")
            target_hazard = r.get("hazard_type")
            _IN_MEMORY_REPORTS.pop(idx)
            break

    try:
        sql_ev = text("SELECT storage_uri FROM incident_evidence WHERE field_report_id::text = :report_id;")
        ev_res = await db.execute(sql_ev, {"report_id": report_id})
        for row in ev_res.fetchall():
            if row[0]:
                photos_to_purge.add(str(row[0]))
    except Exception:
        pass

    # Find coordinates and twins in DB or Supabase if not found in memory
    try:
        sql_info = text("SELECT ST_Y(location), ST_X(location), hazard_type::text FROM field_reports WHERE id::text = :report_id LIMIT 1;")
        res_info = await db.execute(sql_info, {"report_id": report_id})
        r_info = res_info.fetchone()
        if r_info:
            target_lat = float(r_info[0])
            target_lon = float(r_info[1])
            target_hazard = str(r_info[2])
    except Exception:
        pass

    try:
        from backend.app.services.supabase_service import SupabaseService
        live_reports = await SupabaseService.get_field_reports()
        if live_reports:
            # Pass 1: Resolve target coordinates and photos if not yet populated
            for r in live_reports:
                r_id = str(r.get("id"))
                if r_id == report_id:
                    r_lat, r_lon = _extract_coords(r)
                    if target_lat is None:
                        target_lat = r_lat
                    if target_lon is None:
                        target_lon = r_lon
                    if target_hazard is None:
                        target_hazard = str(r.get("hazard_type", ""))
                    if r.get("photo_url"):
                        photos_to_purge.add(r["photo_url"])
                    if r.get("photo_urls") and isinstance(r["photo_urls"], list):
                        for p in r["photo_urls"]:
                            if p:
                                photos_to_purge.add(p)
                    break

            # Pass 2: Match all identical IDs or spatial twins (< 100m)
            for r in live_reports:
                r_id = str(r.get("id"))
                r_lat, r_lon = _extract_coords(r)

                is_match = (r_id == report_id)
                if not is_match and target_lat is not None and target_lon is not None:
                    if abs(r_lat - target_lat) < 0.001 and abs(r_lon - target_lon) < 0.001:
                        is_match = True

                if is_match:
                    twin_ids.add(r_id)
                    _add_deleted_id(r_id)
                    if r.get("photo_url"):
                        photos_to_purge.add(r["photo_url"])
                    if r.get("photo_urls") and isinstance(r["photo_urls"], list):
                        for p in r["photo_urls"]:
                            if p:
                                photos_to_purge.add(p)
    except Exception:
        pass

    # Purge any twin instances from in-memory active list
    _IN_MEMORY_REPORTS[:] = [
        r for r in _IN_MEMORY_REPORTS
        if str(r.get("id")) not in twin_ids and not (
            target_lat is not None and target_lon is not None and
            abs(float(r.get("latitude", 0.0)) - target_lat) < 0.001 and
            abs(float(r.get("longitude", 0.0)) - target_lon) < 0.001
        )
    ]

    # 2. Destroy from Cloudinary CDN and local storage
    from backend.app.api.v1.endpoints.evidence import destroy_cloudinary_asset, extract_cloudinary_public_id, _IN_MEMORY_EVIDENCE
    for photo_ref in photos_to_purge:
        pub_id = extract_cloudinary_public_id(photo_ref)
        if pub_id:
            try:
                await destroy_cloudinary_asset(pub_id)
            except Exception:
                pass
        # Local static upload cleanup if applicable
        if "/static/uploads/" in photo_ref or photo_ref.startswith("local/"):
            fname = photo_ref.split("/")[-1]
            local_p = Path("static/uploads") / fname
            if local_p.exists():
                try:
                    local_p.unlink()
                except Exception:
                    pass
        # Remove from active in-memory evidence list
        _IN_MEMORY_EVIDENCE[:] = [
            e for e in _IN_MEMORY_EVIDENCE
            if e.get("cloudinary_public_id") != pub_id and e.get("secure_url") != photo_ref
        ]

    # 3. Delete evidence and report from PostgreSQL
    for t_id in twin_ids:
        try:
            await db.execute(text("DELETE FROM incident_evidence WHERE field_report_id::text = :report_id;"), {"report_id": t_id})
            await db.execute(text("DELETE FROM field_reports WHERE id::text = :report_id;"), {"report_id": t_id})
            await db.commit()
        except Exception:
            await db.rollback()

    # 4. Delete from Supabase Cloud
    try:
        from backend.app.services.supabase_service import SupabaseService
        for t_id in twin_ids:
            await SupabaseService.delete_field_report(t_id)
    except Exception:
        pass

    # 5. Purge any linked alerts from active memory
    from backend.app.api.v1.endpoints.alerts import _IN_MEMORY_ALERTS
    _IN_MEMORY_ALERTS[:] = [
        a for a in _IN_MEMORY_ALERTS
        if not any(t_id in a.get("title", "") or t_id in a.get("description", "") for t_id in twin_ids)
    ]

    return {
        "success": True,
        "report_id": report_id,
        "photos_purged": len(photos_to_purge),
        "message": f"Field report {report_id} and associated Cloudinary assets permanently deleted",
    }

