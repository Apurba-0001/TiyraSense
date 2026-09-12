"""
Seed script to populate road_segments in PostGIS with realistic North Eastern Region logistics corridors.
Idempotent: can be run repeatedly.
"""
import asyncio
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from sqlalchemy import text
from backend.app.core.database import async_session_maker

CORRIDOR_SEGMENTS = [
    # NH-06: Guwahati -> Jorabat -> Nongpoh -> Mawlai -> Shillong
    {
        "segment_code": "NH06-GW-JB",
        "corridor_name": "NH-06 Guwahati-Shillong",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1001,
        "end_node_id": 1002,
        "coords": [(91.7362, 26.1445), (91.8012, 26.1120), (91.8724, 26.0850)],
        "length_meters": 18500.0,
        "average_slope_degrees": 6.5,
        "landslide_susceptibility": 0.22,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.180,
    },
    {
        "segment_code": "NH06-JB-NP",
        "corridor_name": "NH-06 Guwahati-Shillong",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1002,
        "end_node_id": 1003,
        "coords": [(91.8724, 26.0850), (91.8850, 25.9820), (91.8780, 25.9030)],
        "length_meters": 32000.0,
        "average_slope_degrees": 18.2,
        "landslide_susceptibility": 0.65,
        "current_accessibility": "CAUTION",
        "current_risk_score": 0.420,
    },
    {
        "segment_code": "NH06-NP-UM",
        "corridor_name": "NH-06 Guwahati-Shillong",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1003,
        "end_node_id": 1004,
        "coords": [(91.8780, 25.9030), (91.9010, 25.7500), (91.9200, 25.6600)],
        "length_meters": 28400.0,
        "average_slope_degrees": 22.5,
        "landslide_susceptibility": 0.78,
        "current_accessibility": "CAUTION",
        "current_risk_score": 0.485,
    },
    {
        "segment_code": "NH06-UM-SH",
        "corridor_name": "NH-06 Guwahati-Shillong",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1004,
        "end_node_id": 1005,
        "coords": [(91.9200, 25.6600), (91.8950, 25.6100), (91.8933, 25.5788)],
        "length_meters": 19500.0,
        "average_slope_degrees": 14.0,
        "landslide_susceptibility": 0.35,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.210,
    },

    # NH-06 Secondary Hill Bypass: Guwahati -> Rani -> Damra -> Mawkyrwat -> Shillong
    {
        "segment_code": "BYP-GW-DM",
        "corridor_name": "Guwahati-Damra Secondary Bypass",
        "road_class": "STATE_HIGHWAY",
        "start_node_id": 1001,
        "end_node_id": 1010,
        "coords": [(91.7362, 26.1445), (91.6050, 25.9800), (91.4500, 25.8200)],
        "length_meters": 64000.0,
        "average_slope_degrees": 8.5,
        "landslide_susceptibility": 0.25,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.225,
    },
    {
        "segment_code": "BYP-DM-SH",
        "corridor_name": "Guwahati-Damra Secondary Bypass",
        "road_class": "STATE_HIGHWAY",
        "start_node_id": 1010,
        "end_node_id": 1005,
        "coords": [(91.4500, 25.8200), (91.6800, 25.6500), (91.8933, 25.5788)],
        "length_meters": 78000.0,
        "average_slope_degrees": 12.0,
        "landslide_susceptibility": 0.30,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.260,
    },

    # NH-27 / NH-29: Guwahati -> Nagaon -> Dabaka -> Silchar
    {
        "segment_code": "NH27-GW-NG",
        "corridor_name": "NH-29 Guwahati-Silchar",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1001,
        "end_node_id": 1020,
        "coords": [(91.7362, 26.1445), (92.1200, 26.1800), (92.6840, 26.3470)],
        "length_meters": 122000.0,
        "average_slope_degrees": 4.2,
        "landslide_susceptibility": 0.15,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.150,
    },
    {
        "segment_code": "NH27-NG-DB",
        "corridor_name": "NH-29 Guwahati-Silchar",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1020,
        "end_node_id": 1021,
        "coords": [(92.6840, 26.3470), (92.8500, 26.1200), (92.9800, 25.9500)],
        "length_meters": 68000.0,
        "average_slope_degrees": 7.8,
        "landslide_susceptibility": 0.28,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.210,
    },
    {
        "segment_code": "NH29-DB-SC",
        "corridor_name": "NH-29 Guwahati-Silchar",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1021,
        "end_node_id": 1022,
        "coords": [(92.9800, 25.9500), (92.9500, 25.4500), (92.7926, 24.8333)],
        "length_meters": 136000.0,
        "average_slope_degrees": 24.6,
        "landslide_susceptibility": 0.82,
        "current_accessibility": "HIGH_RISK",
        "current_risk_score": 0.680,
    },

    # NH-37: Numaligarh -> Kaziranga -> Jorhat
    {
        "segment_code": "NH37-NM-KZ",
        "corridor_name": "NH-37 Numaligarh-Jorhat",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1030,
        "end_node_id": 1031,
        "coords": [(93.7400, 26.6200), (93.4200, 26.5800), (93.1800, 26.6000)],
        "length_meters": 65000.0,
        "average_slope_degrees": 3.1,
        "landslide_susceptibility": 0.45,
        "current_accessibility": "RESTRICTED",
        "current_risk_score": 0.520,
    },
    {
        "segment_code": "NH37-KZ-JH",
        "corridor_name": "NH-37 Numaligarh-Jorhat",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1031,
        "end_node_id": 1032,
        "coords": [(93.7400, 26.6200), (94.0200, 26.7100), (94.2167, 26.7500)],
        "length_meters": 54000.0,
        "average_slope_degrees": 2.8,
        "landslide_susceptibility": 0.20,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.180,
    },

    # NH-102: Imphal -> Thoubal -> Pallel -> Moreh
    {
        "segment_code": "NH102-IM-TB",
        "corridor_name": "NH-102 Imphal-Moreh",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1040,
        "end_node_id": 1041,
        "coords": [(93.9368, 24.8170), (93.9800, 24.6400), (94.0100, 24.5200)],
        "length_meters": 35000.0,
        "average_slope_degrees": 5.0,
        "landslide_susceptibility": 0.30,
        "current_accessibility": "OPEN",
        "current_risk_score": 0.220,
    },
    {
        "segment_code": "NH102-TB-PL",
        "corridor_name": "NH-102 Imphal-Moreh",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1041,
        "end_node_id": 1042,
        "coords": [(94.0100, 24.5200), (94.0800, 24.4200), (94.1500, 24.3100)],
        "length_meters": 32000.0,
        "average_slope_degrees": 21.0,
        "landslide_susceptibility": 0.75,
        "current_accessibility": "CAUTION",
        "current_risk_score": 0.490,
    },
    {
        "segment_code": "NH102-PL-MR",
        "corridor_name": "NH-102 Imphal-Moreh",
        "road_class": "NATIONAL_HIGHWAY",
        "start_node_id": 1042,
        "end_node_id": 1043,
        "coords": [(94.1500, 24.3100), (94.2200, 24.2800), (94.3000, 24.2400)],
        "length_meters": 43000.0,
        "average_slope_degrees": 27.5,
        "landslide_susceptibility": 0.90,
        "current_accessibility": "BLOCKED",
        "current_risk_score": 0.940,
    },
]


async def seed_road_network():
    print("Connecting to PostGIS and seeding road network segments...")
    async with async_session_maker() as session:
        for seg in CORRIDOR_SEGMENTS:
            wkt_points = ", ".join(f"{lon} {lat}" for lon, lat in seg["coords"])
            wkt_linestring = f"LINESTRING({wkt_points})"

            sql = text("""
                INSERT INTO road_segments (
                    segment_code, corridor_name, road_class, start_node_id, end_node_id,
                    geom, length_meters, average_slope_degrees, landslide_susceptibility,
                    current_accessibility, current_risk_score, last_assessed_at, data_label
                ) VALUES (
                    :segment_code, :corridor_name, :road_class, :start_node_id, :end_node_id,
                    ST_GeomFromText(:wkt, 4326), :length_meters, :average_slope_degrees, :landslide_susceptibility,
                    CAST(:current_accessibility AS accessibility_state), :current_risk_score, NOW(), 'LIVE'
                )
                ON CONFLICT (segment_code) DO UPDATE SET
                    corridor_name = EXCLUDED.corridor_name,
                    geom = EXCLUDED.geom,
                    length_meters = EXCLUDED.length_meters,
                    average_slope_degrees = EXCLUDED.average_slope_degrees,
                    landslide_susceptibility = EXCLUDED.landslide_susceptibility,
                    current_accessibility = EXCLUDED.current_accessibility,
                    current_risk_score = EXCLUDED.current_risk_score,
                    last_assessed_at = NOW();
            """)
            await session.execute(
                sql,
                {
                    "segment_code": seg["segment_code"],
                    "corridor_name": seg["corridor_name"],
                    "road_class": seg["road_class"],
                    "start_node_id": seg["start_node_id"],
                    "end_node_id": seg["end_node_id"],
                    "wkt": wkt_linestring,
                    "length_meters": seg["length_meters"],
                    "average_slope_degrees": seg["average_slope_degrees"],
                    "landslide_susceptibility": seg["landslide_susceptibility"],
                    "current_accessibility": seg["current_accessibility"],
                    "current_risk_score": seg["current_risk_score"],
                },
            )
            print(f"  [OK] Seeded segment '{seg['segment_code']}' ({seg['corridor_name']})")

        await session.commit()
    print("Road network seeding completed successfully!")


if __name__ == "__main__":
    asyncio.run(seed_road_network())
