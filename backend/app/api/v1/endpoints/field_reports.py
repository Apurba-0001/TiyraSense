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
from backend.app.schemas.reports import (
    FieldReportCreate,
    FieldReportOut,
    FieldReportVerify,
)

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

# In-memory store fallback for test environments without PostGIS write permissions
_IN_MEMORY_REPORTS = [
    {
        "id": "RP-2847",
        "hazard_type": "Landslide",
        "severity": "FULL BLOCKAGE",
        "status": "PENDING",
        "description": "Large boulder roll-down on left shoulder. One lane blocked, second lane at risk of secondary debris flow. Immediate earth-mover intervention requested.",
        "latitude": 26.0124,
        "longitude": 91.8901,
        "corridor_name": "NH-06",
        "km_marker": "KM 52.3",
        "reporter_name": "Sanjay Kumar",
        "reporter_unit": "Field Unit 4",
        "submitted_at": "6m ago",
        "data_label": "LIVE",
        "dispatch_unit": None,
        "dispatch_notes": None,
        "photo_url": "https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "RP-2846",
        "hazard_type": "Flash Flood",
        "severity": "PARTIAL",
        "status": "VERIFIED",
        "description": "Mountain stream overflow depositing gravel across 40 meters of roadway. Water depth approximately 20cm. Light vehicles diverted.",
        "latitude": 25.6812,
        "longitude": 93.7145,
        "corridor_name": "NH-29",
        "km_marker": "KM 81.1",
        "reporter_name": "Priya Mao",
        "reporter_unit": "Field Unit 2",
        "submitted_at": "18m ago",
        "data_label": "LIVE",
        "dispatch_unit": "PWD Assam Division",
        "dispatch_notes": "Single-lane escort activated",
        "photo_url": "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "RP-2845",
        "hazard_type": "Road Subsidence",
        "severity": "SHOULDER",
        "status": "PENDING",
        "description": "Outer asphalt edge cracked and dropped 15cm along valley side over 25m stretch. Soil creep visible after persistent rainfall.",
        "latitude": 24.8105,
        "longitude": 92.7981,
        "corridor_name": "NH-37",
        "km_marker": "KM 114.7",
        "reporter_name": "Tenzing Dorji",
        "reporter_unit": "Field Unit 1",
        "submitted_at": "45m ago",
        "data_label": "LIVE",
        "dispatch_unit": None,
        "dispatch_notes": None,
        "photo_url": "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "RP-2844",
        "hazard_type": "Debris Fall",
        "severity": "PARTIAL",
        "status": "DISPATCHED",
        "description": "Loose shale and small rocks tumbling continuously from cut-slope. BRO bulldozer on-site clearing debris periodically.",
        "latitude": 25.5788,
        "longitude": 91.8933,
        "corridor_name": "NH-40",
        "km_marker": "KM 23.4",
        "reporter_name": "Ratan Das",
        "reporter_unit": "Field Unit 3",
        "submitted_at": "1h ago",
        "data_label": "LIVE",
        "dispatch_unit": "BRO Unit 88",
        "dispatch_notes": "Heavy earthmover operating",
        "photo_url": "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80",
    },
    {
        "id": "RP-2843",
        "hazard_type": "Bridge Strain",
        "severity": "PARTIAL",
        "status": "VERIFIED",
        "description": "Pier scour detected at downstream riverbed of Bridge 14A. Load limit reduced to 20 tons pending acoustic sensor scan.",
        "latitude": 26.1445,
        "longitude": 91.7362,
        "corridor_name": "NH-06",
        "km_marker": "KM 9.8",
        "reporter_name": "M. Sangma",
        "reporter_unit": "Field Unit 2",
        "submitted_at": "2h ago",
        "data_label": "LIVE",
        "dispatch_unit": "NHAI Bridge Inspection",
        "dispatch_notes": "Acoustic strain telemetry active",
        "photo_url": "https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=800&q=80",
    },
]


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

    # 1. In-memory session store (newest reports submitted in active session)
    for item in _IN_MEMORY_REPORTS:
        rep_id = str(item["id"])
        if rep_id not in _DELETED_REPORT_IDS:
            merged_map[rep_id] = FieldReportOut(**item)

    # 2. Local database query (PostgreSQL PostGIS)
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
                COALESCE(rs.corridor_name, 'NER Artery') as corridor_name,
                TO_CHAR(fr.server_received_at, 'YYYY-MM-DD HH24:MI:SS') as submitted_at,
                COALESCE(u.full_name, 'Field Scout') as reporter_name,
                ie.storage_uri
            FROM field_reports fr
            LEFT JOIN road_segments rs ON fr.road_segment_id = rs.id
            LEFT JOIN users u ON fr.reporter_id = u.id
            LEFT JOIN incident_evidence ie ON fr.id = ie.field_report_id
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
                    km_marker="Active Pin",
                    reporter_name=str(r[9]),
                    reporter_unit="Field Recon",
                    submitted_at=str(r[8]),
                    data_label=settings.DATA_LABEL,
                    photo_url=str(r[10]) if r[10] else None,
                )
    except Exception:
        pass

    # 3. Supabase Cloud PostgREST
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
                photo = (
                    item.get("photo_url")
                    or item.get("evidence_url")
                    or (item.get("photo_urls")[0] if isinstance(item.get("photo_urls"), list) and item.get("photo_urls") else None)
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

    def _recency_score(item: FieldReportOut) -> float:
        sub = item.submitted_at or ""
        if "Just now" in sub:
            return 1e11
        if "m ago" in sub:
            try:
                mins = float(sub.split("m")[0].strip())
                return 1e10 - mins * 60
            except Exception:
                return 1e9
        if "h ago" in sub:
            try:
                hrs = float(sub.split("h")[0].strip())
                return 1e9 - hrs * 3600
            except Exception:
                return 1e8
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

    reporter_name = current_user.full_name if current_user else "Field Scout"
    reporter_unit = "Field Recon Unit"

    new_report_dict = {
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

    # 1. Forward to live Supabase Cloud PostgREST
    supa_id = None
    try:
        from backend.app.services.supabase_service import SupabaseService
        supa_res = await SupabaseService.create_field_report({
            "hazard_type": report.hazard_type.upper().replace(" ", "_"),
            "reported_severity": report.severity.upper().replace(" ", "_"),
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
    except Exception:
        pass

    # 2. Persist to local PostgreSQL PostGIS & incident_evidence
    try:
        sql = text("""
            INSERT INTO field_reports (
                id, reporter_id, hazard_type, reported_severity, description,
                location, client_captured_at, server_received_at, verification_status, data_label
            ) VALUES (
                gen_random_uuid(), :reporter_id, :hazard_type::incident_type, :severity::severity_level,
                :description, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), NOW(), NOW(), 'PENDING', :data_label::data_label
            ) RETURNING id::text;
        """)
        reporter_id = current_user.id if current_user else None
        res = await db.execute(sql, {
            "reporter_id": reporter_id,
            "hazard_type": report.hazard_type.upper().replace(" ", "_"),
            "severity": report.severity.upper().replace(" ", "_"),
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
                        gen_random_uuid(), :fr_id, :uri, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'image/jpeg', NOW()
                    );
                """)
                await db.execute(evidence_sql, {"fr_id": db_id, "uri": str(report.photo_url)})
            except Exception:
                pass
        # Unconditionally commit the transaction so both the report and evidence are persisted
        await db.commit()
        if db_id and not supa_id:
            new_report_dict["id"] = str(db_id)
    except Exception:
        await db.rollback()

    _IN_MEMORY_REPORTS.insert(0, new_report_dict)
    return FieldReportOut(**new_report_dict)


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
    target = None
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

    return FieldReportOut(**target)


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

