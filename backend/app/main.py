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
    response.headers["Content-Security-Policy"] = (
        "default-src 'none'; frame-ancestors 'none'"
    )
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
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
