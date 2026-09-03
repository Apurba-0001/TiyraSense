from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from backend.app.api.v1.router import api_router
from backend.app.core.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    description="AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)",
    version="0.1.0",
    docs_url="/docs" if settings.APP_ENV == "development" else None,
    redoc_url="/redoc" if settings.APP_ENV == "development" else None,
)

# CORS Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def attach_data_provenance_header(request: Request, call_next):
    """Ensure every API response explicitly carries the required data labeling provenance header."""
    response = await call_next(request)
    response.headers["X-TiyraSense-Data-Label"] = settings.DATA_LABEL
    return response


# Register API v1 routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/", tags=["Root"])
async def root_status():
    """Root entrypoint reporting system metadata and status."""
    return {
        "project": settings.APP_NAME,
        "identity": "SIH 2026 Problem Statement 26002",
        "description": "Smart Logistics & Accessibility Intelligence for NER",
        "status": "operational",
        "data_label": settings.DATA_LABEL,
        "api_v1": "/api/v1",
        "health": "/api/v1/health",
    }
