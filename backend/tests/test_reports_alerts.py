import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.main import app


@pytest.mark.anyio
async def test_list_field_reports():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/reports")
        assert response.status_code == 200
        reports = response.json()
        assert isinstance(reports, list)
        assert len(reports) >= 1
        assert "hazard_type" in reports[0]
        assert "severity" in reports[0]
        assert "latitude" in reports[0]
        assert "longitude" in reports[0]


@pytest.mark.anyio
async def test_create_and_verify_field_report():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        payload = {
            "hazard_type": "Landslide",
            "severity": "HIGH",
            "description": "Test boulder slide on NH-06",
            "latitude": 26.0124,
            "longitude": 91.8901,
            "corridor_name": "NH-06",
            "km_marker": "KM 52.3",
        }
        res = await client.post("/api/v1/reports", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data["status"] == "PENDING"
        report_id = data["id"]

        # Verify report
        verify_res = await client.patch(
            f"/api/v1/reports/{report_id}/verify",
            json={
                "status": "VERIFIED",
                "dispatch_unit": "Field Unit 4",
                "dispatch_notes": "Heavy earthmover dispatched",
            },
        )
        assert verify_res.status_code == 200
        verified_data = verify_res.json()
        assert verified_data["status"] == "VERIFIED"
        assert verified_data["dispatch_unit"] == "Field Unit 4"


@pytest.mark.anyio
async def test_list_and_acknowledge_alerts():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/alerts")
        assert res.status_code == 200
        alerts = res.json()
        assert isinstance(alerts, list)
        assert len(alerts) >= 1

        alert_id = alerts[0]["id"]
        ack_res = await client.patch(f"/api/v1/alerts/{alert_id}/acknowledge")
        assert ack_res.status_code == 200
        ack_data = ack_res.json()
        assert ack_data["acknowledged"] is True


@pytest.mark.anyio
async def test_delete_field_report():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create a report to delete
        payload = {
            "hazard_type": "Tree Fall",
            "severity": "LOW",
            "description": "Obsolete temporary test report",
            "latitude": 26.1111,
            "longitude": 91.7777,
            "corridor_name": "NH-06",
            "km_marker": "KM 12.0",
        }
        res = await client.post("/api/v1/reports", json=payload)
        assert res.status_code == 201
        report_id = res.json()["id"]

        # Delete report
        del_res = await client.delete(f"/api/v1/reports/{report_id}")
        assert del_res.status_code == 200
        del_data = del_res.json()
        assert del_data["success"] is True
        assert del_data["report_id"] == report_id


@pytest.mark.anyio
async def test_evidence_admin_stats_and_delete():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Fetch admin storage stats
        stats_res = await client.get("/api/v1/evidence/admin/stats")
        assert stats_res.status_code == 200
        stats = stats_res.json()
        assert "total_images" in stats
        assert "total_size_formatted" in stats
        assert stats["total_images"] >= 1
        assert "format_distribution" in stats

        # 2. Register a new test evidence photo
        reg_res = await client.post(
            "/api/v1/evidence",
            json={
                "cloudinary_public_id": "tiyrasense/evidence/test_delete_img",
                "secure_url": "https://res.cloudinary.com/tsjmggus/image/upload/test_delete.jpg",
                "bytes": 245000,
                "format": "jpeg",
                "camera_lat": 26.0,
                "camera_lng": 91.8,
            },
        )
        assert reg_res.status_code == 201
        evidence_id = reg_res.json()["id"]

        # 3. Delete evidence photo
        del_res = await client.delete(f"/api/v1/evidence/{evidence_id}")
        assert del_res.status_code == 200
        del_data = del_res.json()
        assert del_data["success"] is True
        assert del_data["evidence_id"] == evidence_id


@pytest.mark.anyio
async def test_upload_photo_and_create_report_with_photo():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Upload mock photo
        dummy_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
        files = {"file": ("test_slide.png", dummy_png, "image/png")}
        up_res = await client.post("/api/v1/evidence/upload", files=files)
        assert up_res.status_code == 201
        up_data = up_res.json()
        assert "url" in up_data
        photo_url = up_data["url"]
        assert photo_url.startswith("/static/uploads/") or photo_url.startswith("https://")

        # 2. Create field report with the uploaded photo URL
        payload = {
            "hazard_type": "Rockfall",
            "severity": "HIGH",
            "description": "Evidence photo attached from field reconnaissance.",
            "latitude": 25.9,
            "longitude": 91.8,
            "corridor_name": "NH-06",
            "km_marker": "KM 44.2",
            "photo_url": photo_url,
        }
        res = await client.post("/api/v1/reports", json=payload)
        assert res.status_code == 201
        report = res.json()
        assert report["photo_url"] == photo_url
        assert report["hazard_type"] == "Rockfall"

