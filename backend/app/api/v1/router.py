from fastapi import APIRouter
from backend.app.api.v1.endpoints import alerts, auth, evidence, external, field_reports, health, journeys, routes

api_router = APIRouter()

api_router.include_router(health.router, tags=["System Health"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication & RBAC"])
api_router.include_router(routes.router, prefix="/routes", tags=["Routes & Corridors"])
api_router.include_router(journeys.router, prefix="/journeys", tags=["Journeys & Telemetry"])
api_router.include_router(field_reports.router, prefix="/reports", tags=["Field Reports"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["Alerts"])
api_router.include_router(evidence.router, prefix="/evidence", tags=["Incident Evidence & Photos"])
api_router.include_router(external.router, prefix="/external", tags=["External Telemetry & Weather"])


