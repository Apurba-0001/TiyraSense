import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.main import app


@pytest.mark.asyncio
async def test_login_driver_success():
    """Verify Driver can successfully authenticate and receive a valid JWT token."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "driver@tiyrasense.in", "password": "DriverPass2026!"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["user"]["email"] == "driver@tiyrasense.in"
        assert data["user"]["role"] == "DRIVER"


@pytest.mark.asyncio
async def test_login_official_success():
    """Verify Disaster Official can successfully authenticate with role OFFICIAL."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "official@tiyrasense.in", "password": "OfficialPass2026!"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["user"]["role"] == "OFFICIAL"


@pytest.mark.asyncio
async def test_login_invalid_credentials():
    """Verify invalid password returns HTTP 401 Unauthorized."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "driver@tiyrasense.in", "password": "WrongPassword!"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_endpoint():
    """Verify /me returns the current user profile when authenticated."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # First login
        login_res = await client.post(
            "/api/v1/auth/login",
            json={"email": "worker@tiyrasense.in", "password": "WorkerPass2026!"},
        )
        token = login_res.json()["access_token"]

        # Call /me with Bearer token
        me_res = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert me_res.status_code == 200
        assert me_res.json()["email"] == "worker@tiyrasense.in"
        assert me_res.json()["role"] == "FIELD_WORKER"


@pytest.mark.asyncio
async def test_unauthenticated_access_rejected():
    """Verify protected endpoints reject requests without a token."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_rbac_driver_forbidden_from_official_endpoint():
    """Verify server-side RBAC returns HTTP 403 when Driver attempts Official action."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Login as Driver
        login_res = await client.post(
            "/api/v1/auth/login",
            json={"email": "driver@tiyrasense.in", "password": "DriverPass2026!"},
        )
        driver_token = login_res.json()["access_token"]

        # Attempt to access official endpoint
        res = await client.get(
            "/api/v1/auth/official-access",
            headers={"Authorization": f"Bearer {driver_token}"},
        )
        assert res.status_code == 403
        assert "Access forbidden" in res.json()["detail"]


@pytest.mark.asyncio
async def test_rbac_official_allowed_on_official_endpoint():
    """Verify Official user is granted access to Official operations."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        login_res = await client.post(
            "/api/v1/auth/login",
            json={"email": "official@tiyrasense.in", "password": "OfficialPass2026!"},
        )
        official_token = login_res.json()["access_token"]

        res = await client.get(
            "/api/v1/auth/official-access",
            headers={"Authorization": f"Bearer {official_token}"},
        )
        assert res.status_code == 200
        assert res.json()["access"] == "granted"
