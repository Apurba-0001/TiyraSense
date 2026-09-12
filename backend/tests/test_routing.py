import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from backend.app.main import app
from backend.app.services.risk_engine import RiskEngine


@pytest_asyncio.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


class TestRiskEngine:
    def test_d015_formula_baseline(self):
        """Verify D-015 formula: 0.35*rain + 0.25*slope + 0.15*hist + 0.25*obstruct."""
        # 0 rain, 0 slope, 0.1 susceptibility, 0 hist, 0 obstruct
        # s_slope = 0.5*(0/45) + 0.5*0.1 = 0.05
        # r = 0.25 * 0.05 = 0.0125 -> 0.012 or 0.013
        risk = RiskEngine.calculate_segment_risk(
            precipitation_mm_hr=0.0,
            slope_degrees=0.0,
            landslide_susceptibility=0.10,
            historical_cuts=0,
            active_obstruction_severity=None,
            is_blocked=False,
        )
        assert 0.01 <= risk <= 0.02

    def test_d015_formula_heavy_monsoon(self):
        """Heavy rain (60mm/hr) with steep slope (45 deg) and high obstruction."""
        # s_rain = 1.0 -> 0.35
        # s_slope = 0.5*1.0 + 0.5*1.0 = 1.0 -> 0.25
        # s_hist = 1.0 -> 0.15
        # s_obstruct = 1.0 (CRITICAL) -> 0.25
        # Total = 1.0
        risk = RiskEngine.calculate_segment_risk(
            precipitation_mm_hr=60.0,
            slope_degrees=45.0,
            landslide_susceptibility=1.0,
            historical_cuts=10,
            active_obstruction_severity="CRITICAL",
        )
        assert risk == 1.000

    def test_blocked_critical_override(self):
        """Blocked road segment immediately overrides to 1.0 regardless of other factors."""
        risk = RiskEngine.calculate_segment_risk(
            precipitation_mm_hr=0.0,
            slope_degrees=0.0,
            landslide_susceptibility=0.0,
            is_blocked=True,
        )
        assert risk == 1.000

    def test_composite_route_risk_calculation(self):
        """Test composite route risk blending 70% distance-weighted average + 30% peak hazard."""
        segments = [
            {"length_meters": 10000.0, "risk_score": 0.20, "accessibility_state": "OPEN"},
            {"length_meters": 10000.0, "risk_score": 0.40, "accessibility_state": "CAUTION"},
        ]
        # base_risk = (10000*0.2 + 10000*0.4) / 20000 = 0.30
        # max_risk = 0.40
        # composite = 0.70*0.30 + 0.30*0.40 = 0.21 + 0.12 = 0.33
        result = RiskEngine.calculate_route_risk(segments)
        assert result["composite_risk_score"] == 0.330
        assert result["is_viable"] is True
        assert result["max_hazard_state"] == "CAUTION"


class TestRoutingEndpoints:
    @pytest.mark.asyncio
    async def test_evaluate_routes_arbitrary_coordinates(self, async_client: AsyncClient):
        """Test route evaluation between Guwahati and Shillong hubs."""
        payload = {
            "origin": {"latitude": 26.1445, "longitude": 91.7362, "label": "Guwahati Hub"},
            "destination": {"latitude": 25.5788, "longitude": 91.8933, "label": "Shillong Terminal"},
            "vehicle_class": "FOUR_WHEELER",
            "prefer_safety": True,
        }
        res = await async_client.post("/api/v1/routes/evaluate", json=payload)
        assert res.status_code == 200
        data = res.json()

        assert "recommended_route_id" in data
        assert len(data["routes"]) >= 2
        assert data["data_label"] in ("LIVE", "SIMULATED", "TEST")

        safest_count = sum(1 for r in data["routes"] if r["is_recommended_safest"])
        fastest_count = sum(1 for r in data["routes"] if r["is_fastest_available"])
        assert safest_count >= 1
        assert fastest_count >= 1

        for r in data["routes"]:
            assert r["total_distance_km"] > 0
            assert r["estimated_duration_mins"] > 0
            assert 0.0 <= r["composite_risk_score"] <= 1.0
            assert r["geometry_geojson"] is not None
            assert r["geometry_geojson"]["type"] == "LineString"
            assert len(r["geometry_geojson"]["coordinates"]) >= 10
            assert "steps" in r
            assert len(r["steps"]) >= 1
            assert r["steps"][0]["instruction"] != ""

    @pytest.mark.asyncio
    async def test_evaluate_routes_custom_coordinates(self, async_client: AsyncClient):
        """Test route evaluation between arbitrary non-preset coordinates (e.g. Guwahati to Tura)."""
        payload = {
            "origin": {"latitude": 26.1800, "longitude": 91.7500, "label": "Custom Start"},
            "destination": {"latitude": 25.5100, "longitude": 90.2200, "label": "Custom End Tura"},
            "vehicle_class": "FOUR_WHEELER",
            "prefer_safety": True,
        }
        res = await async_client.post("/api/v1/routes/evaluate", json=payload)
        assert res.status_code == 200
        data = res.json()
        assert len(data["routes"]) >= 1

    @pytest.mark.asyncio
    async def test_get_corridors_summary(self, async_client: AsyncClient):
        """Test GET /api/v1/routes/corridors returns populated corridor list."""
        res = await async_client.get("/api/v1/routes/corridors")
        assert res.status_code == 200
        data = res.json()
        assert len(data) >= 3
        corridor_names = [c["name"] for c in data]
        assert any("NH-06" in name for name in corridor_names)

    @pytest.mark.asyncio
    async def test_search_places_gazetteer(self, async_client: AsyncClient):
        """Test searching for towns across NER returns matches with real coordinates."""
        res = await async_client.get("/api/v1/routes/places/search?q=Shillong")
        assert res.status_code == 200
        data = res.json()
        assert len(data) >= 1
        assert any("Shillong" in p["name"] for p in data)
        assert data[0]["latitude"] > 20.0
        assert data[0]["longitude"] > 88.0

    @pytest.mark.asyncio
    async def test_search_places_coordinates(self, async_client: AsyncClient):
        """Test searching with raw GPS coordinates returns parsed coordinates."""
        res = await async_client.get("/api/v1/routes/places/search?q=26.1445, 91.7362")
        assert res.status_code == 200
        data = res.json()
        assert len(data) == 1
        assert data[0]["place_type"] == "coordinates"
        assert abs(data[0]["latitude"] - 26.1445) < 0.001
        assert abs(data[0]["longitude"] - 91.7362) < 0.001

    @pytest.mark.asyncio
    async def test_route_dynamic_classification_and_faster_integrity(self, async_client: AsyncClient):
        """Verify dynamic classification ensures slower routes are NEVER marked fastest."""
        payload = {
            "origin": {"latitude": 26.1445, "longitude": 91.7362, "label": "Guwahati Hub"},
            "destination": {"latitude": 25.5788, "longitude": 91.8933, "label": "Shillong Terminal"},
            "vehicle_class": "FOUR_WHEELER",
            "prefer_safety": True,
        }
        res = await async_client.post("/api/v1/routes/evaluate", json=payload)
        assert res.status_code == 200
        routes = res.json()["routes"]
        assert len(routes) >= 2

        valid_classifications = {"SAFEST_AND_FASTEST", "SAFEST_VIABLE", "FASTEST_AVAILABLE", "ALTERNATIVE_BYPASS"}
        for r in routes:
            assert r.get("classification") in valid_classifications

        durations = [r["estimated_duration_mins"] for r in routes]
        min_dur = min(durations)
        for r in routes:
            if r["estimated_duration_mins"] > min_dur + 0.5:
                assert r["is_fastest_available"] is False
                assert r["classification"] != "FASTEST_AVAILABLE"
                assert r["classification"] != "SAFEST_AND_FASTEST"


