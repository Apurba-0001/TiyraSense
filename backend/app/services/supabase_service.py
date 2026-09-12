"""
TiyraSense — Supabase Live Cloud Data Service
Direct asynchronous connector to live Supabase PostgREST API for instant,
zero-database-driver live data fetching across Web, Backend, and Mobile.
"""
from typing import Any, Dict, List, Optional
import httpx
from backend.app.core.config import settings

class SupabaseService:
    @classmethod
    def _headers(cls, use_service_role: bool = False) -> Dict[str, str]:
        if use_service_role and settings.SUPABASE_SERVICE_ROLE_KEY:
            key = settings.SUPABASE_SERVICE_ROLE_KEY
        else:
            key = settings.SUPABASE_KEY or settings.SUPABASE_ANON_KEY
        return {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    @classmethod
    def _client(cls) -> httpx.AsyncClient:
        url = settings.SUPABASE_URL.rstrip("/")
        return httpx.AsyncClient(
            base_url=f"{url}/rest/v1",
            headers=cls._headers(),
            timeout=8.0,
        )

    @classmethod
    async def get_road_segments(cls) -> List[Dict[str, Any]]:
        """Fetch all live road segments from Supabase."""
        async with cls._client() as client:
            res = await client.get("/road_segments?select=*&order=corridor_name.asc")
            if res.status_code == 200:
                return res.json()
            return []

    @classmethod
    async def get_field_reports(cls) -> List[Dict[str, Any]]:
        """Fetch all live field reports from Supabase."""
        async with cls._client() as client:
            res = await client.get("/field_reports?select=*&order=server_received_at.desc")
            if res.status_code == 200:
                reports = res.json()
                for rep in reports:
                    if not rep.get("photo_url") and rep.get("photo_urls") and isinstance(rep["photo_urls"], list) and len(rep["photo_urls"]) > 0:
                        rep["photo_url"] = rep["photo_urls"][0]
                return reports
            return []

    @classmethod
    async def create_field_report(cls, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Insert a live field report into Supabase with PostGIS geometry and photo array mapping."""
        clean = dict(payload)
        # 1. Map photo_url to photo_urls array for Supabase schema
        photo = clean.pop("photo_url", None)
        if photo:
            clean["photo_urls"] = [photo]
        elif "photo_urls" not in clean:
            clean["photo_urls"] = []

        # 2. Ensure PostGIS location geometry format
        lat = clean.get("latitude")
        lon = clean.get("longitude")
        if lat is not None and lon is not None and "location" not in clean:
            clean["location"] = f"POINT({lon} {lat})"

        # 3. Ensure client_captured_at is set (required NOT NULL)
        if "client_captured_at" not in clean:
            from datetime import datetime, timezone
            clean["client_captured_at"] = datetime.now(timezone.utc).isoformat()

        async with cls._client() as client:
            res = await client.post("/field_reports", json=clean)
            if res.status_code in (200, 201):
                data = res.json()
                ret = data[0] if isinstance(data, list) and data else clean
                if ret.get("photo_urls") and isinstance(ret["photo_urls"], list) and len(ret["photo_urls"]) > 0:
                    ret["photo_url"] = ret["photo_urls"][0]
                return ret
            return None

    @classmethod
    async def update_field_report(cls, report_id: str, payload: Dict[str, Any]) -> bool:
        """Update a field report in Supabase."""
        async with cls._client() as client:
            res = await client.patch(f"/field_reports?id=eq.{report_id}", json=payload)
            return res.status_code in (200, 204)

    @classmethod
    async def delete_field_report(cls, report_id: str) -> bool:
        """Delete a field report from Supabase."""
        async with cls._client() as client:
            res = await client.delete(f"/field_reports?id=eq.{report_id}")
            return res.status_code in (200, 204)

    @classmethod
    async def get_alerts(cls) -> List[Dict[str, Any]]:
        """Fetch all operational corridor alerts from Supabase."""
        async with cls._client() as client:
            res = await client.get("/alerts?select=*&order=dispatched_at.desc")
            if res.status_code == 200:
                return res.json()
            return []

    @classmethod
    async def create_alert(cls, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Insert an operational alert into Supabase."""
        async with cls._client() as client:
            res = await client.post("/alerts", json=payload)
            if res.status_code in (200, 201):
                data = res.json()
                return data[0] if isinstance(data, list) and data else payload
            return None

    @classmethod
    async def acknowledge_alert(cls, alert_id: str) -> bool:
        """Acknowledge an alert in Supabase."""
        async with cls._client() as client:
            from datetime import datetime, timezone
            now = datetime.now(timezone.utc).isoformat()
            res = await client.patch(
                f"/alerts?id=eq.{alert_id}",
                json={"acknowledged_at": now, "status": "ACKNOWLEDGED"},
            )
            return res.status_code in (200, 204)

    @classmethod
    async def acknowledge_all_alerts(cls) -> bool:
        """Acknowledge all pending alerts in Supabase."""
        async with cls._client() as client:
            from datetime import datetime, timezone
            now = datetime.now(timezone.utc).isoformat()
            res = await client.patch(
                "/alerts?status=neq.ACKNOWLEDGED",
                json={"acknowledged_at": now, "status": "ACKNOWLEDGED"},
            )
            return res.status_code in (200, 204)

    @classmethod
    async def get_vehicles(cls) -> List[Dict[str, Any]]:
        """Fetch all active fleet units from Supabase."""
        async with cls._client() as client:
            res = await client.get("/vehicles?select=*&order=name.asc")
            if res.status_code == 200:
                return res.json()
            return []

    @classmethod
    async def get_safe_havens(cls) -> List[Dict[str, Any]]:
        """Fetch all emergency relief safe havens from Supabase."""
        async with cls._client() as client:
            res = await client.get("/safe_havens?select=*&order=name.asc")
            if res.status_code == 200:
                return res.json()
            return []

    @classmethod
    async def update_user_profile(
        cls,
        user_id: str,
        email: str,
        full_name: str,
        phone_number: Optional[str] = None,
        organization: Optional[str] = None,
    ) -> bool:
        """Update user profile in Supabase profiles/users table."""
        try:
            async with cls._client() as client:
                body: Dict[str, Any] = {"full_name": full_name}
                if phone_number is not None:
                    body["phone_number"] = phone_number
                if organization is not None:
                    body["organization"] = organization

                res = await client.patch(
                    f"/users?email=eq.{email}",
                    json=body,
                )
                return res.status_code in (200, 204)
        except Exception:
            return False

