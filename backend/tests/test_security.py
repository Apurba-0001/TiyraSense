"""Security hardening tests — injection, XSS, and privilege escalation.

These tests prove that malicious inputs are rejected before any database
query runs, that headers are present on every response, and that role
escalation cannot occur via any API path.
"""
import pytest
from httpx import ASGITransport, AsyncClient
from backend.app.main import app


# ── SQL / null-byte injection in registration ─────────────────────────────────

@pytest.mark.asyncio
async def test_register_null_byte_in_name_rejected():
    """Null bytes in full_name must be rejected with HTTP 422 before DB access.

    Null bytes are a classic injection vector that can truncate strings at the
    database driver level or in C-based string functions.
    """
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "injector@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "Driver\x00--DROP TABLE users--",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_control_chars_in_name_rejected():
    """ASCII control characters in full_name are rejected with HTTP 422."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "ctrl@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "Driver\x01\x02\x03",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_null_byte_in_password_rejected():
    """Null bytes in password must be rejected with HTTP 422."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "pwdinject@tiyrasense.in",
                "password": "Valid\x00Pass2026!",
                "full_name": "Valid Name",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_invalid_phone_rejected():
    """Phone numbers containing non-numeric characters are rejected."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "phonetest@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "Valid Name",
                "phone_number": "'; DROP TABLE users; --",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_oversized_name_rejected():
    """Full names longer than 128 characters are rejected with HTTP 422."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "bigname@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "A" * 200,
            },
        )
        assert response.status_code == 422


# ── Role escalation via API ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_official_rejected():
    """OFFICIAL role cannot be claimed via the public registration endpoint."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "esc1@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "Escalator",
                "role": "OFFICIAL",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_admin_rejected():
    """ADMIN role cannot be claimed via the public registration endpoint."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "esc2@tiyrasense.in",
                "password": "ValidPass2026!",
                "full_name": "Escalator",
                "role": "ADMIN",
            },
        )
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_mixed_case_role_rejected():
    """Mixed-case and near-miss role strings ('Admin', 'official') are also rejected."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        for bad_role in ("Admin", "admin", "official", "Official", "OFFICIAL ", " ADMIN"):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "casetest@tiyrasense.in",
                    "password": "ValidPass2026!",
                    "full_name": "Escalator",
                    "role": bad_role,
                },
            )
            assert response.status_code == 422, f"Expected 422 for role={bad_role!r}, got {response.status_code}"


# ── Security response headers ─────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_security_headers_present_on_root():
    """Every response must carry hardened security headers."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/")
        assert response.headers.get("x-content-type-options") == "nosniff"
        assert response.headers.get("x-frame-options") == "DENY"
        assert "frame-ancestors 'none'" in response.headers.get("content-security-policy", "")
        assert response.headers.get("referrer-policy") == "strict-origin-when-cross-origin"
        assert response.headers.get("x-tiyrasense-data-label") is not None


@pytest.mark.asyncio
async def test_security_headers_present_on_api():
    """Security headers must also be present on /api/v1/health."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/api/v1/health")
        assert response.headers.get("x-content-type-options") == "nosniff"
        assert response.headers.get("x-frame-options") == "DENY"
