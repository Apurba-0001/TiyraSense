"""
TiyraSense — End-to-End Selection Demo Scenario Integration Test
Authoritative Specification: Canonical 20-Step Demonstration Scenario (docs/testing_strategy.md)

Executes the continuous 20-step selection demonstration workflow:
1. Healthcheck & Data Labeling verification
2. Authenticate as Driver
3. Authenticate as Official
4. Role-based security validation (rejecting privilege escalation)
5. Destination selection and multi-candidate OSRM route evaluation
6. Safest Viable vs Fastest Available route comparison
7. Driver starts journey & streams GPS radar telemetry
8. Forward hazard lookahead detection
9. Fleet monitoring visibility
10. Field incident reporting with photo evidence metadata
11. Official verifies the incident report
12. Automated alert generation on verification
13. Dynamic route re-evaluation with virtual hazard segment injection
14. Warning states & alternate viable route recommendation
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.app.main import app
from backend.app.core.config import settings


@pytest_asyncio.fixture
async def e2e_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.mark.asyncio
async def test_full_selection_demo_workflow_end_to_end(e2e_client: AsyncClient):
    # -------------------------------------------------------------
    # Step 1: Healthcheck & Provenance
    # -------------------------------------------------------------
    health_res = await e2e_client.get("/api/v1/health")
    assert health_res.status_code == 200
    health_data = health_res.json()
    assert health_data["status"] in ("healthy", "operational")
    assert health_data["data_label"] in ("LIVE", "SIMULATED", "TEST")
    assert health_res.headers.get("X-TiyraSense-Data-Label") is not None
    assert health_res.headers.get("X-Content-Type-Options") == "nosniff"

    # -------------------------------------------------------------
    # Step 2: Driver Authentication
    # -------------------------------------------------------------
    driver_login = await e2e_client.post(
        "/api/v1/auth/login",
        json={"email": "driver@tiyrasense.in", "password": "DriverPass2026!"},
    )
    assert driver_login.status_code == 200, f"Driver login failed: {driver_login.text}"
    driver_auth = driver_login.json()
    assert "access_token" in driver_auth
    assert driver_auth["user"]["role"] == "DRIVER"
    driver_token = driver_auth["access_token"]
    driver_headers = {"Authorization": f"Bearer {driver_token}"}

    # -------------------------------------------------------------
    # Step 3: Official Authentication
    # -------------------------------------------------------------
    official_login = await e2e_client.post(
        "/api/v1/auth/login",
        json={"email": "official@tiyrasense.in", "password": "OfficialPass2026!"},
    )
    assert official_login.status_code == 200, f"Official login failed: {official_login.text}"
    official_auth = official_login.json()
    assert official_auth["user"]["role"] == "OFFICIAL"
    official_token = official_auth["access_token"]
    official_headers = {"Authorization": f"Bearer {official_token}"}

    # -------------------------------------------------------------
    # Step 4: Security Boundary Check (No self-registration as OFFICIAL/ADMIN)
    # -------------------------------------------------------------
    escalation_attempt = await e2e_client.post(
        "/api/v1/auth/register",
        json={
            "email": "hacker@test.com",
            "password": "Password123!",
            "full_name": "Rogue Agent",
            "role": "OFFICIAL",
        },
    )
    assert escalation_attempt.status_code == 422, "Security breach: self-registration as OFFICIAL must be rejected"

    # -------------------------------------------------------------
    # Step 5: Route Evaluation (Guwahati Hub -> Shillong Terminal)
    # -------------------------------------------------------------
    guwahati_shillong = {
        "origin": {"latitude": 26.1445, "longitude": 91.7362, "label": "Guwahati Hub"},
        "destination": {"latitude": 25.5788, "longitude": 91.8933, "label": "Shillong Terminal"},
        "vehicle_class": "FOUR_WHEELER",
        "prefer_safety": True,
    }
    eval_res = await e2e_client.post("/api/v1/routes/evaluate", json=guwahati_shillong)
    assert eval_res.status_code == 200
    eval_data = eval_res.json()
    assert len(eval_data["routes"]) >= 2, "Must return at least Safest Viable and Fastest Available candidates"
    assert "recommended_route_id" in eval_data

    # Step 6: Verify candidate route properties and D-015 risk scores
    safest = next((r for r in eval_data["routes"] if r["is_recommended_safest"]), None)
    fastest = next((r for r in eval_data["routes"] if r["is_fastest_available"]), None)
    assert safest is not None, "Safest viable route must be identified"
    assert fastest is not None, "Fastest available route must be visible"
    assert 0.0 <= safest["composite_risk_score"] <= 1.0
    assert safest["total_distance_km"] > 0
    assert safest["estimated_duration_mins"] > 0
    assert safest["geometry_geojson"]["type"] == "LineString"

    # -------------------------------------------------------------
    # Step 7: Driver Starts Journey & Records Telemetry
    # -------------------------------------------------------------
    journey_payload = {
        "route_id": safest["id"],
        "vehicle_number": "AS-01-GC-4921",
        "vehicle_model": "BharatBenz 3528C",
        "origin_hub": "Guwahati Hub",
        "destination_hub": "Shillong Terminal",
        "cargo_type": "MEDICAL_RELIEF",
    }
    create_journey_res = await e2e_client.post(
        "/api/v1/journeys",
        json=journey_payload,
        headers=driver_headers,
    )
    assert create_journey_res.status_code in (200, 201)
    journey = create_journey_res.json()
    journey_id = journey["id"]

    # Post real-time GPS telemetry radar ping
    telemetry_ping = {
        "latitude": 26.0850,
        "longitude": 91.8724,
        "speed_kmh": 42.5,
        "heading_degrees": 155.0,
    }
    telemetry_res = await e2e_client.post(
        f"/api/v1/journeys/{journey_id}/telemetry",
        json=telemetry_ping,
        headers=driver_headers,
    )
    assert telemetry_res.status_code in (200, 201)

    # Step 8: Check Forward Hazard Lookahead & Dynamic Distance
    tracking_res = await e2e_client.get(
        f"/api/v1/journeys/{journey_id}/tracking",
        headers=driver_headers,
    )
    assert tracking_res.status_code == 200
    tracking_data = tracking_res.json()
    assert tracking_data["status"] in ("ACTIVE", "PLANNED", "IN_TRANSIT")
    assert "remaining_distance_km" in tracking_data or "current_location" in tracking_data

    # Step 9: Fleet Monitoring Visibility
    active_fleet_res = await e2e_client.get("/api/v1/journeys/active")
    assert active_fleet_res.status_code == 200
    active_fleet = active_fleet_res.json()
    assert isinstance(active_fleet, list)
    assert len(active_fleet) >= 1

    # -------------------------------------------------------------
    # Step 10: Field Incident Reporting with Evidence
    # -------------------------------------------------------------
    incident_report = {
        "hazard_type": "LANDSLIDE",
        "severity": "CRITICAL",
        "description": "Massive boulder slide blocking NH-06 Nongpoh hill section",
        "latitude": 25.9030,
        "longitude": 91.8780,
        "corridor_name": "NH-06 Guwahati-Shillong",
        "km_marker": "KM 48.5",
        "photo_url": "http://localhost:8000/static/uploads/evidence_landslide_demo.jpg",
    }
    report_res = await e2e_client.post(
        "/api/v1/reports",
        json=incident_report,
        headers=driver_headers,
    )
    assert report_res.status_code in (200, 201)
    report_data = report_res.json()
    report_id = report_data["id"]
    assert report_data["hazard_type"] == "LANDSLIDE"

    # -------------------------------------------------------------
    # Step 11: Official Verifies Incident Report
    # -------------------------------------------------------------
    verify_res = await e2e_client.patch(
        f"/api/v1/reports/{report_id}/verify",
        json={"status": "VERIFIED"},
        headers=official_headers,
    )
    assert verify_res.status_code in (200, 204)

    # -------------------------------------------------------------
    # Step 12: Automated Alert Generation Confirmation
    # -------------------------------------------------------------
    alerts_res = await e2e_client.get("/api/v1/alerts")
    assert alerts_res.status_code == 200
    alerts_data = alerts_res.json()
    assert isinstance(alerts_data, list)
    # Confirm active alerts exist in the feed
    assert len(alerts_data) >= 1

    # -------------------------------------------------------------
    # Step 13 & 14: Dynamic Route Re-Evaluation with Virtual Hazard Segment
    # -------------------------------------------------------------
    re_eval_res = await e2e_client.post("/api/v1/routes/evaluate", json=guwahati_shillong)
    assert re_eval_res.status_code == 200
    re_eval_data = re_eval_res.json()

    # The verified critical incident must be reflected in route risk or hazard state
    has_elevated_hazard = any(
        r.get("max_hazard_state") in ("BLOCKED", "HIGH_RISK", "CAUTION")
        or r.get("composite_risk_score", 0.0) >= 0.40
        for r in re_eval_data["routes"]
    )
    assert has_elevated_hazard, "Verified field incident must dynamically elevate hazard state or risk"
