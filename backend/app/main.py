import sys
from pathlib import Path

# Ensure project root is in sys.path so 'backend.app' package resolves from any working directory
_ROOT_DIR = Path(__file__).resolve().parents[2]
if str(_ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(_ROOT_DIR))

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from backend.app.api.v1.router import api_router
from backend.app.core.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    description="AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)",
    version="0.1.0",
    # Disable interactive API docs outside development to reduce attack surface
    docs_url="/docs" if settings.APP_ENV == "development" else None,
    redoc_url="/redoc" if settings.APP_ENV == "development" else None,
)

# CORS Middleware: allowed origins are explicitly enumerated in settings.
# In production, CORS_ORIGINS must not include wildcard "*".
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "X-Requested-With"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    """Attach hardened security response headers to every API response.

    These headers defend against a class of browser-side attacks even for a
    JSON-only API, and are especially important if API responses are ever
    rendered or proxied through a web UI:

    - X-Content-Type-Options: prevents MIME-sniffing so browsers never
      interpret JSON as executable HTML/JavaScript.
    - X-Frame-Options: prevents the API from being embedded in an <iframe>
      (clickjacking).
    - Content-Security-Policy: instructs compliant browsers to refuse inline
      script execution and only allow same-origin frames.
    - Referrer-Policy: prevents sensitive URL paths from leaking in the
      Referer header to third-party servers.
    - X-TiyraSense-Data-Label: mandatory data provenance label per AGENTS.md.
    """
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    if request.url.path.startswith("/static/"):
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; img-src 'self' data: blob: https:; frame-ancestors 'none'"
        )
    elif request.url.path in ("/docs", "/redoc", "/openapi.json"):
        response.headers["Content-Security-Policy"] = (
            "default-src 'self' https://cdn.jsdelivr.net; "
            "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
            "img-src 'self' data: https://fastapi.tiangolo.com; "
            "frame-ancestors 'none'"
        )
    else:
        response.headers["Content-Security-Policy"] = (
            "default-src 'none'; frame-ancestors 'none'"
        )
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["X-TiyraSense-Data-Label"] = settings.DATA_LABEL
    return response


# Static files mount for uploaded evidence photos
from fastapi.staticfiles import StaticFiles

_UPLOADS_DIR = _ROOT_DIR / "backend" / "app" / "static" / "uploads"
_UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/static/uploads", StaticFiles(directory=str(_UPLOADS_DIR)), name="static_uploads")

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
