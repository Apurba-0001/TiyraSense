import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.app.main import app


@pytest_asyncio.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.mark.asyncio
async def test_journey_lifecycle_and_live_telemetry(async_client: AsyncClient):
    # 1. First evaluate a route to get a valid route_id
    eval_res = await async_client.post(
        "/api/v1/routes/evaluate",
        json={
            "origin": {"latitude": 26.1445, "longitude": 91.7362, "label": "Guwahati"},
            "destination": {"latitude": 25.5788, "longitude": 91.8933, "label": "Shillong"},
            "vehicle_class": "FOUR_WHEELER",
        },
    )
    assert eval_res.status_code == 200
    route_id = eval_res.json()["recommended_route_id"]

    # 2. Start a new journey
    start_res = await async_client.post(
        "/api/v1/journeys",
        json={"route_id": route_id},
    )
    assert start_res.status_code == 201
    journey_data = start_res.json()
    journey_id = journey_data["id"]
    assert journey_data["status"] == "ACTIVE"

    # 3. Stream live telemetry GPS breadcrumbs
    # Ping 1: At starting hub (Guwahati)
    tel_res1 = await async_client.post(
        f"/api/v1/journeys/{journey_id}/telemetry",
        json={"latitude": 26.1445, "longitude": 91.7362, "speed_kmh": 35.0, "heading_degrees": 140.0},
    )
    assert tel_res1.status_code == 200
    assert tel_res1.json()["status"] == "received"

    # Check tracking response after Ping 1
    track_res1 = await async_client.get(f"/api/v1/journeys/{journey_id}/tracking")
    assert track_res1.status_code == 200
    track_data1 = track_res1.json()
    assert track_data1["journey_id"] == journey_id
    assert track_data1["status"] == "ACTIVE"
    assert track_data1["current_location"]["latitude"] == 26.1445
    assert track_data1["current_location"]["longitude"] == 91.7362
    initial_remaining = track_data1["remaining_distance_km"]
    assert initial_remaining > 50.0  # Approx 65-100km to Shillong

    # Ping 2: Mid-journey near Nongpoh (closer to Shillong)
    tel_res2 = await async_client.post(
        f"/api/v1/journeys/{journey_id}/telemetry",
        json={"latitude": 25.9030, "longitude": 91.8780, "speed_kmh": 45.0, "heading_degrees": 160.0},
    )
    assert tel_res2.status_code == 200

    # Check tracking after Ping 2: remaining distance should decrease!
    track_res2 = await async_client.get(f"/api/v1/journeys/{journey_id}/tracking")
    assert track_res2.status_code == 200
    track_data2 = track_res2.json()
    assert track_data2["remaining_distance_km"] < initial_remaining
    assert track_data2["distance_covered_km"] > 0.0

    # 4. Check that this active journey appears in the active fleet listing
    active_res = await async_client.get("/api/v1/journeys/active")
    assert active_res.status_code == 200
    active_list = active_res.json()
    journey_ids = [j["journey_id"] for j in active_list]
    assert journey_id in journey_ids


@pytest.mark.asyncio
async def test_journey_not_found(async_client: AsyncClient):
    res = await async_client.get("/api/v1/journeys/00000000-0000-0000-0000-000000000000/tracking")
    assert res.status_code == 404
