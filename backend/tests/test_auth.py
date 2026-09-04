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


# ── Registration role restriction tests ──────────────────────────────────────

@pytest.mark.asyncio
async def test_register_driver_succeeds():
    """Public registration creates a DRIVER account when role is omitted."""
    import uuid
    unique_email = f"driver_{uuid.uuid4().hex[:8]}@tiyrasense.in"
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": unique_email,
                "password": "TestDriver2026!",
                "full_name": "Test Driver",
            },
        )
        assert response.status_code == 201
        assert response.json()["role"] == "DRIVER"


@pytest.mark.asyncio
async def test_register_field_worker_succeeds():
    """Public registration creates a FIELD_WORKER account when role is FIELD_WORKER."""
    import uuid
    unique_email = f"worker_{uuid.uuid4().hex[:8]}@tiyrasense.in"
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": unique_email,
                "password": "TestWorker2026!",
                "full_name": "Test Field Worker",
                "role": "FIELD_WORKER",
            },
        )
        assert response.status_code == 201
        assert response.json()["role"] == "FIELD_WORKER"


@pytest.mark.asyncio
async def test_register_official_rejected():
    """Attempting to self-register as OFFICIAL is rejected with HTTP 422 Unprocessable Entity.

    The restriction is enforced at the schema level (RegistrationRole enum) before
    any database logic runs.  OFFICIAL and ADMIN can only be assigned by a database
    administrator via a direct UPDATE on the users table.
    """
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "impostor@tiyrasense.in",
                "password": "Impostor2026!",
                "full_name": "Impostor Official",
                "role": "OFFICIAL",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_admin_rejected():
    """Attempting to self-register as ADMIN is rejected with HTTP 422 Unprocessable Entity."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "fakeadmin@tiyrasense.in",
                "password": "FakeAdmin2026!",
                "full_name": "Fake Admin",
                "role": "ADMIN",
            },
        )
        assert response.status_code == 422
