from fastapi import APIRouter
from backend.app.api.v1.endpoints import auth, health

api_router = APIRouter()

api_router.include_router(health.router, tags=["System Health"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication & RBAC"])
