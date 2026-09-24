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

import time
from collections import defaultdict

app = FastAPI(
    title=settings.APP_NAME,
    description="AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)",
    version="0.1.0",
    # Disable interactive API docs outside development to reduce attack surface
    docs_url="/docs" if settings.APP_ENV == "development" else None,
    redoc_url="/redoc" if settings.APP_ENV == "development" else None,
)

# In-memory sliding window rate limiter for abuse defense
_RATE_LIMIT_STORE = defaultdict(list)

# CORS Middleware: allowed origins are explicitly enumerated in settings.
# In development, private IP ranges are permitted for local emulator / device testing.
_cors_regex = (
    r"http://(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+)(:\d+)?"
    if settings.APP_ENV == "development"
    else r"^https://.*\.(onrender\.com|pages\.dev|vercel\.app)$"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=_cors_regex,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "X-Requested-With"],
)


@app.middleware("http")
async def rate_limiting_middleware(request: Request, call_next):
    """In-memory rate limiting to defend auth endpoints against brute-force attacks."""
    if settings.APP_ENV in ("development", "test", "testing") or not request.client or request.client.host in ("testclient", "unknown", "127.0.0.1", "localhost"):
        return await call_next(request)

    client_ip = request.client.host
    path = request.url.path
    now = time.time()



    # Determine rate limit per endpoint type
    limit = settings.RATE_LIMIT_API_PER_MINUTE
    if path == "/api/v1/auth/login":
        limit = settings.RATE_LIMIT_LOGIN_PER_MINUTE
    elif path == "/api/v1/auth/register":
        limit = settings.RATE_LIMIT_REGISTER_PER_MINUTE

    key = f"{client_ip}:{path}"
    # Prune timestamps older than 60 seconds
    timestamps = [t for t in _RATE_LIMIT_STORE[key] if now - t < 60]
    if len(timestamps) >= limit:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Rate limit exceeded. Please wait a moment before trying again."},
            headers={"Retry-After": "60"},
        )

    timestamps.append(now)
    _RATE_LIMIT_STORE[key] = timestamps

    return await call_next(request)



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


@app.get("/ping", tags=["Monitoring"])
async def ping():
    """Ultra-lightweight keep-alive ping endpoint for external cron/monitors (e.g. UptimeRobot)."""
    return {
        "status": "OK",
        "message": "tiyrasense-api",
    }


@app.get("/", tags=["Root"])
async def root_status():
    """Root entrypoint reporting system metadata and operational status."""
    return {
        "status": "operational",
        "message": "tiyrasense-api",
        "project": settings.APP_NAME,
        "identity": "SIH 2026 Problem Statement 26002",
        "data_label": settings.DATA_LABEL,
    }
