"""
TiyraSense — Live Telemetry & Tracking Service
Handles active journey creation, driver GPS breadcrumbs, and forward hazard proximity detection.
"""
import math
import uuid
from datetime import datetime, timezone
from typing import Dict, List, Optional
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.schemas.journeys import (
    ActiveJourneySummary,
    JourneyTrackingResponse,
    TelemetryPointRequest,
    UpcomingHazard,
)
from backend.app.schemas.routes import Coordinates
from backend.app.services.routing_service import RoutingService


class TelemetryService:
    _IN_MEMORY_JOURNEYS: Dict[str, Dict] = {}

    @classmethod
    async def create_journey(
        cls,
        db: AsyncSession,
        route_id: str,
        driver_id: Optional[str] = None,
        vehicle_id: Optional[str] = None,
        origin_coords: Optional[Coordinates] = None,
        destination_coords: Optional[Coordinates] = None,
        origin_name: Optional[str] = None,
        destination_name: Optional[str] = None,
        route_name: Optional[str] = None,
        route_geometry: Optional[List[List[float]]] = None,
    ) -> str:
        """Initialize an active logistics journey."""
        journey_id = str(uuid.uuid4())
        # Cache in-memory for offline/dev fallback
        route_info = RoutingService._IN_MEMORY_ROUTES.get(route_id)
        total_dist = route_info.get("total_distance_km", 98.4) if route_info else 98.4
        
        orig_lat = origin_coords.latitude if origin_coords else (route_info.get("orig_lat", 26.1445) if route_info else 26.1445)
        orig_lon = origin_coords.longitude if origin_coords else (route_info.get("orig_lon", 91.7362) if route_info else 91.7362)
        dest_lat = destination_coords.latitude if destination_coords else (route_info.get("dest_lat", 25.5788) if route_info else 25.5788)
        dest_lon = destination_coords.longitude if destination_coords else (route_info.get("dest_lon", 91.8933) if route_info else 91.8933)
        orig_n = origin_name or (route_info.get("orig_name", "Guwahati") if route_info else "Guwahati")
        dest_n = destination_name or (route_info.get("dest_name", "Shillong") if route_info else "Shillong")
        r_name = route_name or (route_info.get("route_name", f"{orig_n} to {dest_n}") if route_info else f"{orig_n} to {dest_n}")
        
        geom_coords = route_geometry
        if not geom_coords and route_info and isinstance(route_info.get("geom"), dict):
            geom_coords = route_info["geom"].get("coordinates")

        cls._IN_MEMORY_JOURNEYS[journey_id] = {
            "id": journey_id,
            "route_id": route_id,
            "driver_id": driver_id,
            "vehicle_id": vehicle_id,
            "status": "ACTIVE",
            "cur_lat": orig_lat,
            "cur_lon": orig_lon,
            "speed_kmh": 0.0,
            "heading_degrees": 0.0,
            "last_telemetry_at": datetime.now(timezone.utc).isoformat(),
            "total_distance_km": total_dist,
            "orig_lat": orig_lat,
            "orig_lon": orig_lon,
            "dest_lat": dest_lat,
            "dest_lon": dest_lon,
            "origin_name": orig_n,
            "destination_name": dest_n,
            "route_name": r_name,
            "route_geometry": geom_coords,
        }

        try:
            sql = text("""
                INSERT INTO journeys (
                    id, driver_id, vehicle_id, active_route_id, status, started_at
                ) VALUES (
                    :id, :driver_id, :vehicle_id, :route_id, 'ACTIVE', NOW()
                )
                RETURNING id;
            """)
            await db.execute(
                sql,
                {
                    "id": journey_id,
                    "driver_id": driver_id,
                    "vehicle_id": vehicle_id,
                    "route_id": route_id,
                },
            )
            await db.commit()
        except Exception:
            await db.rollback()

        return journey_id

    @classmethod
    async def record_telemetry(
        cls,
        db: AsyncSession,
        journey_id: str,
        point: TelemetryPointRequest,
    ):
        """Record real-time driver GPS telemetry breadcrumb."""
        now_str = datetime.now(timezone.utc).isoformat()
        if journey_id in cls._IN_MEMORY_JOURNEYS:
            cls._IN_MEMORY_JOURNEYS[journey_id]["cur_lat"] = point.latitude
            cls._IN_MEMORY_JOURNEYS[journey_id]["cur_lon"] = point.longitude
            cls._IN_MEMORY_JOURNEYS[journey_id]["speed_kmh"] = point.speed_kmh or 0.0
            cls._IN_MEMORY_JOURNEYS[journey_id]["heading_degrees"] = point.heading_degrees or 0.0
            cls._IN_MEMORY_JOURNEYS[journey_id]["last_telemetry_at"] = now_str
        else:
            cls._IN_MEMORY_JOURNEYS[journey_id] = {
                "id": journey_id,
                "status": "ACTIVE",
                "cur_lat": point.latitude,
                "cur_lon": point.longitude,
                "orig_lat": point.latitude,
                "orig_lon": point.longitude,
                "dest_lat": 25.5788,
                "dest_lon": 91.8933,
                "origin_name": "Current Location",
                "destination_name": "Regional Hub",
                "route_name": "Live Tracked Corridor",
                "speed_kmh": point.speed_kmh or 0.0,
                "heading_degrees": point.heading_degrees or 0.0,
                "last_telemetry_at": now_str,
            }

        try:
            sql = text("""
                UPDATE journeys
                SET current_location = ST_SetSRID(ST_MakePoint(:lon, :lat), 4326),
                    last_telemetry_at = NOW()
                WHERE id = :journey_id;
            """)
            await db.execute(
                sql,
                {
                    "journey_id": journey_id,
                    "lon": point.longitude,
                    "lat": point.latitude,
                },
            )
            await db.commit()
        except Exception:
            await db.rollback()

    @classmethod
    async def get_journey_tracking(
        cls,
        db: AsyncSession,
        journey_id: str,
    ) -> Optional[JourneyTrackingResponse]:
        """Retrieve live tracking state, remaining distance, and forward hazards for an active journey."""
        try:
            sql = text("""
                SELECT 
                    j.id,
                    j.status,
                    ST_X(j.current_location) as cur_lon,
                    ST_Y(j.current_location) as cur_lat,
                    j.last_telemetry_at,
                    r.total_distance_km,
                    r.estimated_duration_mins,
                    ST_Distance(j.current_location::geography, r.destination_geom::geography) / 1000.0 as rem_dist_km
                FROM journeys j
                LEFT JOIN routes r ON j.active_route_id = r.id
                WHERE j.id = :journey_id;
            """)
            result = await db.execute(sql, {"journey_id": journey_id})
            row = result.fetchone()
            if row:
                status = str(row[1])
                cur_lon = row[2]
                cur_lat = row[3]
                last_ping = row[4].isoformat() if row[4] else None
                total_dist = float(row[5]) if row[5] is not None else 0.0
                total_dur = float(row[6]) if row[6] is not None else 0.0
                rem_dist = float(row[7]) if row[7] is not None else total_dist

                cur_coord = None
                if cur_lon is not None and cur_lat is not None:
                    cur_coord = Coordinates(latitude=cur_lat, longitude=cur_lon, label="Current GPS Location")

                covered_dist = max(0.0, total_dist - rem_dist) if total_dist > 0 else 0.0
                rem_time = (rem_dist / 40.0) * 60.0 if rem_dist > 0 else 0.0  # est based on 40 km/h

                # Query upcoming road hazards within 15 km forward buffer of current location
                upcoming_hazards: List[UpcomingHazard] = []
                if cur_lon is not None and cur_lat is not None:
                    hazard_sql = text("""
                        SELECT 
                            segment_code,
                            corridor_name,
                            current_accessibility,
                            current_risk_score,
                            ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000.0 as dist_km
                        FROM road_segments
                        WHERE current_accessibility != 'OPEN'
                          AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 15000)
                        ORDER BY dist_km ASC
                        LIMIT 5;
                    """)
                    haz_res = await db.execute(hazard_sql, {"lon": cur_lon, "lat": cur_lat})
                    for h in haz_res.fetchall():
                        upcoming_hazards.append(
                            UpcomingHazard(
                                segment_code=str(h[0]),
                                corridor_name=str(h[1]),
                                hazard_state=str(h[2]),
                                risk_score=float(h[3]),
                                distance_ahead_km=round(float(h[4]), 1),
                            )
                        )

                return JourneyTrackingResponse(
                    journey_id=str(row[0]),
                    status=status,
                    current_location=cur_coord,
                    speed_kmh=45.0,  # Telemetry default speed
                    last_telemetry_at=last_ping,
                    distance_covered_km=round(covered_dist, 1),
                    remaining_distance_km=round(rem_dist, 1),
                    estimated_time_remaining_mins=round(rem_time, 1),
                    upcoming_hazards=upcoming_hazards,
                )
        except Exception:
            pass

        # Fallback to in-memory store
        mem = cls._IN_MEMORY_JOURNEYS.get(journey_id)
        if not mem:
            return None

        cur_lat = mem.get("cur_lat")
        cur_lon = mem.get("cur_lon")
        cur_coord = None
        if cur_lat is not None and cur_lon is not None:
            cur_coord = Coordinates(latitude=cur_lat, longitude=cur_lon, label="Current GPS Location")

        total_dist = float(mem.get("total_distance_km", 98.4))
        dest_lat = float(mem.get("dest_lat", 25.5788))
        dest_lon = float(mem.get("dest_lon", 91.8933))

        if cur_lat is not None and cur_lon is not None:
            # Haversine distance to destination
            r_lat1, r_lon1 = math.radians(cur_lat), math.radians(cur_lon)
            r_lat2, r_lon2 = math.radians(dest_lat), math.radians(dest_lon)
            dlat = r_lat2 - r_lat1
            dlon = r_lon2 - r_lon1
            a = math.sin(dlat / 2) ** 2 + math.cos(r_lat1) * math.cos(r_lat2) * math.sin(dlon / 2) ** 2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
            crow_km = 6371.0 * c
            rem_dist = max(0.5, crow_km * 1.35)
        else:
            rem_dist = total_dist

        covered_dist = max(0.0, total_dist - rem_dist) if total_dist > rem_dist else 0.0
        rem_time = (rem_dist / 40.0) * 60.0

        return JourneyTrackingResponse(
            journey_id=journey_id,
            status=mem.get("status", "ACTIVE"),
            current_location=cur_coord,
            speed_kmh=45.0,
            last_telemetry_at=mem.get("last_telemetry_at"),
            distance_covered_km=round(covered_dist, 1),
            remaining_distance_km=round(rem_dist, 1),
            estimated_time_remaining_mins=round(rem_time, 1),
            upcoming_hazards=[],
        )

    @classmethod
    async def list_active_journeys(
        cls,
        db: AsyncSession,
    ) -> List[ActiveJourneySummary]:
        """List all active journeys for the official monitoring dashboard."""
        # 1. Collect real-time active journeys streaming from mobile units first
        live_list: List[ActiveJourneySummary] = []
        for j_id, mem in cls._IN_MEMORY_JOURNEYS.items():
            if mem.get("status") == "ACTIVE":
                c_lat = mem.get("cur_lat")
                c_lon = mem.get("cur_lon")
                c_coord = Coordinates(latitude=c_lat, longitude=c_lon) if c_lat is not None and c_lon is not None else None
                
                orig_lat = mem.get("orig_lat", 26.1445)
                orig_lon = mem.get("orig_lon", 91.7362)
                o_coord = Coordinates(latitude=orig_lat, longitude=orig_lon) if orig_lat is not None and orig_lon is not None else None
                
                dest_lat = mem.get("dest_lat", 25.5788)
                dest_lon = mem.get("dest_lon", 91.8933)
                d_coord = Coordinates(latitude=dest_lat, longitude=dest_lon) if dest_lat is not None and dest_lon is not None else None
                
                v_name = mem.get("vehicle_id") or mem.get("driver_name") or "Mobile Driver Unit"
                live_list.append(
                    ActiveJourneySummary(
                        journey_id=j_id,
                        driver_name=f"{v_name} (LIVE GPS)",
                        driver_phone="+91 94350-29184",
                        route_name=mem.get("route_name", "NH-06 Active Corridor"),
                        current_location=c_coord,
                        speed_kmh=float(mem.get("speed_kmh", 42.0)),
                        heading_degrees=float(mem.get("heading_degrees", 0.0)),
                        origin_name=mem.get("origin_name", "Guwahati"),
                        destination_name=mem.get("destination_name", "Shillong"),
                        origin_coords=o_coord,
                        destination_coords=d_coord,
                        route_geometry=mem.get("route_geometry"),
                        status="ACTIVE",
                        last_ping_mins_ago=0,
                    )
                )

        # 2. Fetch fleet vehicles from Supabase Cloud
        try:
            from backend.app.services.supabase_service import SupabaseService
            live_vehicles = await SupabaseService.get_vehicles()
            if live_vehicles:
                fleet_meta = {
                    "c1b2c3d4-e5f6-4a1b-8c2d-000000000021": {
                        "callsign": "TRK-01",
                        "driver_name": "Ramen Borah",
                        "driver_phone": "+91 98640-12345",
                        "model": "Tata Prima 2830.K",
                        "reg": "AS-01-GC-4921",
                    },
                    "c1b2c3d4-e5f6-4a1b-8c2d-000000000022": {
                        "callsign": "TRK-02",
                        "driver_name": "Bikramjit Gogoi",
                        "driver_phone": "+91 94350-29184",
                        "model": "BharatBenz 3528C",
                        "reg": "NL-07-A-8832",
                    },
                    "c1b2c3d4-e5f6-4a1b-8c2d-000000000023": {
                        "callsign": "MED-01",
                        "driver_name": "Dr. Sanborlang Lyngdoh",
                        "driver_phone": "+91 87940-54211",
                        "model": "Force Mobile Clinic",
                        "reg": "ML-05-EM-1102",
                    },
                    "c1b2c3d4-e5f6-4a1b-8c2d-000000000024": {
                        "callsign": "RECON-01",
                        "driver_name": "Dipankar Saikia",
                        "driver_phone": "+91 94350-54321",
                        "model": "Mahindra Bolero 4x4",
                        "reg": "AS-25-R-7741",
                    },
                }

                for idx, v in enumerate(live_vehicles):
                    if not isinstance(v, dict):
                        continue
                    v_id = str(v.get("id"))
                    if any(a.journey_id == v_id for a in live_list):
                        continue
                    raw_geom = v.get("geom")
                    coords = raw_geom.get("coordinates") if isinstance(raw_geom, dict) else None
                    coord = None
                    if coords and len(coords) >= 2:
                        coord = Coordinates(latitude=float(coords[1]), longitude=float(coords[0]))

                    meta = fleet_meta.get(v_id, {})
                    v_name = v.get("name") or meta.get("model") or "NER Fleet Unit"
                    reg_num = v.get("registration_number") or meta.get("reg") or f"AS-0{idx + 1}-NER"
                    d_name = meta.get("driver_name") or "Assigned Operator"
                    d_phone = meta.get("driver_phone") or "+91 94350-29184"
                    callsign = meta.get("callsign") or f"UNIT-0{idx + 1}"
                    cargo = v.get("cargo_type") or "General Logistics"

                    live_list.append(
                        ActiveJourneySummary(
                            journey_id=v_id,
                            vehicle_name=v_name,
                            vehicle_number=reg_num,
                            callsign=callsign,
                            driver_name=d_name,
                            driver_phone=d_phone,
                            route_name=f"{cargo} — {v.get('vehicle_class', 'TRUCK')}",
                            current_location=coord,
                            speed_kmh=float(v.get("current_speed_kmh") or 42.0),
                            heading_degrees=float(v.get("current_heading") or 0.0),
                            origin_name="Guwahati",
                            destination_name="Shillong",
                            origin_coords=Coordinates(latitude=26.1445, longitude=91.7362),
                            destination_coords=Coordinates(latitude=25.5788, longitude=91.8933),
                            status=str(v.get("current_status", "ACTIVE")),
                            last_ping_mins_ago=1,
                        )
                    )
                if live_list:
                    return live_list
        except Exception:
            if live_list:
                return live_list

        # 2. Local DB query fallback
        active_list: List[ActiveJourneySummary] = []
        try:
            sql = text("""
                SELECT 
                    j.id,
                    COALESCE(u.full_name, 'Driver Unit') as driver_name,
                    u.phone_number,
                    COALESCE(r.destination_name, 'Active Corridor') as route_name,
                    ST_X(j.current_location) as cur_lon,
                    ST_Y(j.current_location) as cur_lat,
                    j.status,
                    EXTRACT(EPOCH FROM (NOW() - j.last_telemetry_at)) / 60.0 as mins_ago
                FROM journeys j
                LEFT JOIN users u ON j.driver_id = u.id
                LEFT JOIN routes r ON j.active_route_id = r.id
                WHERE j.status = 'ACTIVE'
                ORDER BY j.started_at DESC
                LIMIT 20;
            """)
            result = await db.execute(sql)
            for r in result.fetchall():
                cur_lon = r[4]
                cur_lat = r[5]
                coord = None
                if cur_lon is not None and cur_lat is not None:
                    coord = Coordinates(latitude=cur_lat, longitude=cur_lon)

                mem = cls._IN_MEMORY_JOURNEYS.get(str(r[0]), {})
                active_list.append(
                    ActiveJourneySummary(
                        journey_id=str(r[0]),
                        driver_name=str(r[1]),
                        driver_phone=r[2],
                        route_name=str(r[3]),
                        current_location=coord,
                        speed_kmh=float(mem.get("speed_kmh", 0.0)),
                        heading_degrees=float(mem.get("heading_degrees", 0.0)),
                        origin_name=mem.get("origin_name"),
                        destination_name=mem.get("destination_name"),
                        origin_coords=Coordinates(latitude=mem["orig_lat"], longitude=mem["orig_lon"]) if mem.get("orig_lat") else None,
                        destination_coords=Coordinates(latitude=mem["dest_lat"], longitude=mem["dest_lon"]) if mem.get("dest_lat") else None,
                        route_geometry=mem.get("route_geometry"),
                        status=str(r[6]),
                        last_ping_mins_ago=int(r[7]) if r[7] is not None else 0,
                    )
                )
            if active_list:
                return active_list
        except Exception:
            pass

        # 3. In-memory fallback
        for j_id, mem in cls._IN_MEMORY_JOURNEYS.items():
            if mem.get("status") == "ACTIVE" and not any(a.journey_id == j_id for a in active_list):
                c_lat = mem.get("cur_lat")
                c_lon = mem.get("cur_lon")
                c_coord = Coordinates(latitude=c_lat, longitude=c_lon) if c_lat is not None and c_lon is not None else None
                
                orig_lat = mem.get("orig_lat")
                orig_lon = mem.get("orig_lon")
                o_coord = Coordinates(latitude=orig_lat, longitude=orig_lon) if orig_lat is not None and orig_lon is not None else None
                
                dest_lat = mem.get("dest_lat")
                dest_lon = mem.get("dest_lon")
                d_coord = Coordinates(latitude=dest_lat, longitude=dest_lon) if dest_lat is not None and dest_lon is not None else None

                active_list.append(
                    ActiveJourneySummary(
                        journey_id=j_id,
                        driver_name=mem.get("driver_name", "Driver Unit"),
                        driver_phone=None,
                        route_name=mem.get("route_name", "Active Corridor"),
                        current_location=c_coord,
                        speed_kmh=float(mem.get("speed_kmh", 0.0)),
                        heading_degrees=float(mem.get("heading_degrees", 0.0)),
                        origin_name=mem.get("origin_name"),
                        destination_name=mem.get("destination_name"),
                        origin_coords=o_coord,
                        destination_coords=d_coord,
                        route_geometry=mem.get("route_geometry"),
                        status="ACTIVE",
                        last_ping_mins_ago=0,
                    )
                )

        return active_list
