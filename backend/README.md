# TiyraSense Backend Service

The backend tier of **TiyraSense** provides high-performance, asynchronous REST APIs, spatial graph routing, multi-factor risk computation, machine learning disruption prediction inference, real-time telemetry tracking, evidence arbitration, and real-time alert dispatching for logistics operations across the North Eastern Region (NER).

---

## 1. Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|:---:|---|
| **Language & Runtime** | Python | 3.12+ | Async backend execution |
| **API Framework** | FastAPI | 0.110+ | High-concurrency async REST gateway & OpenAPI generation |
| **ASGI Web Server** | Uvicorn | 0.28+ | Production-grade async HTTP/1.1 server |
| **Database ORM** | SQLAlchemy 2.0 + asyncpg | 2.0+ / 0.29+ | Non-blocking async PostgreSQL access with native connection pooling |
| **Geospatial Processing** | GeoAlchemy2 | 0.14+ | PostGIS geometry serialization, WKT/GeoJSON spatial manipulation |
| **Validation & Serialization** | Pydantic v2 | 2.6+ | Strict type validation, request/response schema parsing |
| **Authentication & RBAC** | Python-Jose + Passlib (bcrypt) | 3.3+ / 1.7+ | JWT issuance, password hashing, database-authoritative role verification |
| **Cloud Database Sync** | Supabase (PostgREST) | httpx async | Dual-write cloud PostgreSQL/PostGIS synchronization |
| **Routing Engine** | OSRM (Open Source Routing Machine) | v5.24+ | Base navigation geometries, distance/time matrices via HTTP client |
| **Weather Telemetry** | Open-Meteo API Client | httpx async | Hourly precipitation, soil moisture, and atmospheric forecasts |
| **ML Inference** | scikit-learn + joblib | 1.6+ / 1.4+ | Sub-5ms forward Disruption Probability ($P_{\text{disrupt}}$) inference |
| **Cloud Storage** | Cloudinary REST Integration | httpx async | Secure storage and CDN delivery for geotagged field photos |
| **Testing & Quality** | pytest + pytest-asyncio + httpx | 8.1+ / 0.23+ | Comprehensive unit, security, integration, and E2E scenario testing |

---

## 2. Directory Structure

```text
backend/
├── app/
│   ├── api/
│   │   ├── deps.py                  # Auth, DB session, and RBAC dependency injection
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   ├── alerts.py         # Dynamic emergency alerts & affected driver queries
│   │       │   ├── auth.py           # Registration, login, profile, and role verification
│   │       │   ├── evidence.py       # Geotagged photo upload and metadata mapping
│   │       │   ├── external.py       # Weather data and external telemetry proxies
│   │       │   ├── field_reports.py  # Crowdsourced hazard submission & official verification
│   │       │   ├── health.py         # Liveness/readiness probes & PostGIS extension check
│   │       │   ├── journeys.py       # Journey lifecycle & GPS telemetry pings
│   │       │   ├── routes.py         # Multi-candidate route evaluation (Safest vs Fastest)
│   │       │   └── settings.py       # System settings & governance configuration
│   │       └── router.py             # Top-level API router mounting all endpoint groups
│   ├── core/
│   │   ├── config.py                 # Pydantic Settings management (env vars, secrets)
│   │   ├── database.py               # Async engine and async sessionmaker lifecycle
│   │   └── security.py               # Password hashing, JWT token creation/decoding
│   ├── models/
│   │   └── user.py                   # SQLAlchemy User model (Driver, Field Worker, Official, Admin)
│   ├── schemas/                      # Pydantic request/response validation schemas
│   │   ├── alerts.py
│   │   ├── auth.py
│   │   ├── evidence.py
│   │   ├── journeys.py
│   │   ├── reports.py
│   │   ├── routes.py
│   │   └── settings.py
│   ├── services/                     # Core business logic and computational services
│   │   ├── external_ingestion_service.py # Open-Meteo weather data ingestion pipeline
│   │   ├── geocoding_service.py          # Coordinate-to-hub and corridor lookup
│   │   ├── risk_engine.py                # Deterministic multi-factor road risk calculation
│   │   ├── routing_service.py            # OSRM interface, segment penalization, route comparator
│   │   ├── supabase_service.py           # Supabase Cloud dual-write sync service
│   │   └── telemetry_service.py          # Real-time fleet GPS tracking and hazard lookahead
│   ├── static/                       # Uploaded evidence photos (static/uploads/) & system_settings.json
│   └── main.py                       # FastAPI entrypoint, CORS, rate limiting & security middleware
├── migrations/
│   └── init.sql                      # Canonical PostGIS database schema (tables, spatial indexes, RLS)
├── tests/                            # Pytest test suite (48 tests, 100% passing)
│   ├── conftest.py                   # Shared test fixtures and async client setup
│   ├── test_auth.py                  # Authentication, registration, and RBAC tests
│   ├── test_external.py              # External weather API proxy tests
│   ├── test_health.py                # Health probe and system status tests
│   ├── test_journeys.py              # Journey lifecycle and telemetry tests
│   ├── test_ml.py                    # ML dataset, training, and inference regression tests
│   ├── test_reports_alerts.py        # Field reports submission and alert generation tests
│   ├── test_routing.py               # Route evaluation and risk scoring tests
│   └── test_security.py              # Security hardening, injection defense, and header tests
├── Dockerfile                        # Production Docker image (Python 3.12-slim, non-root user)
├── requirements.txt                  # Python package dependencies
└── README.md                         # This file
```

---

## 3. Core Service Subsystems

### 3.1 Deterministic Risk Engine (`services/risk_engine.py`)
Computes an auditable, multi-factor risk score $R \in [0.0, 1.0]$ across road segments using four calibrated dimensions:
$$R = w_r \cdot S_{\text{rain}} + w_s \cdot S_{\text{slope}} + w_h \cdot S_{\text{hist}} + w_o \cdot S_{\text{obs}}$$
- $S_{\text{rain}}$ ($w_r = 0.35$): Dynamic rainfall intensity from Open-Meteo observations and 2-hour forecasts.
- $S_{\text{slope}}$ ($w_s = 0.25$): Digital elevation model gradient and Geological Survey of India landslide susceptibility.
- $S_{\text{hist}}$ ($w_h = 0.15$): Historical blockage frequency along known fault zones.
- $S_{\text{obs}}$ ($w_o = 0.25$): Verified field incident reports and active obstruction severities.
- **Critical State Override:** Confirmed blockages set $R = 1.0$ immediately.
- **Route Composite Formula:** 70% distance-weighted average + 30% bottleneck peak risk.

### 3.2 Routing & Corridor Optimizer (`services/routing_service.py`)
- Interfaces with OSRM to generate candidate multi-route geometries between logistics hubs.
- Evaluates candidate paths against PostGIS road segments and dynamic hazard buffers.
- Recommends the **Safest Viable** route based on composite segment risk while continuously displaying the **Fastest Available** route for dispatcher comparison.
- Injects virtual hazard segments into OSRM bounding boxes when critical incidents are verified.

### 3.3 Real-Time Telemetry & Hazard Radar (`services/telemetry_service.py`)
- Ingests GPS breadcrumbs (latitude, longitude, speed, heading, altitude) streamed from driver devices.
- Computes dynamic remaining distance and ETA to destination.
- Performs a forward hazard radar lookahead alerting in-transit drivers to verified blockages up to 25 km ahead along their active path.

### 3.4 Supabase Cloud Sync (`services/supabase_service.py`)
- Dual-writes all field reports, alerts, journeys, and user mutations to both local PostgreSQL/PostGIS and Supabase Cloud for redundancy and real-time cross-platform access.

### 3.5 External Ingestion (`services/external_ingestion_service.py`)
- Connects to Open-Meteo API to fetch live hourly precipitation, soil moisture, surface pressure, and 2-hour forecasts across 8 primary NER hub coordinates.

### 3.6 Geocoding Service (`services/geocoding_service.py`)
- Maps coordinate pairs to named hub locations and monitored NH corridors.
- Used by routes, journeys, and alerts endpoints for human-readable location labels.

---

## 4. API Endpoints Map

All endpoints require HTTP Bearer JWT authentication except public health probes, login, and registration:

| Method | Route | Access Role | Description |
|---|---|:---:|---|
| `GET` | `/ping` | Public | Ultra-lightweight keep-alive ping (for UptimeRobot / Render free tier) |
| `GET` | `/` | Public | Root status metadata and system identity |
| `GET` | `/api/v1/health` | Public | System liveness, database ping, and PostGIS extension probe |
| `POST` | `/api/v1/auth/register` | Public | Role-restricted registration (`DRIVER` & `FIELD_WORKER` only) |
| `POST` | `/api/v1/auth/login` | Public | Token issuance (email/password → JWT Bearer token) |
| `GET` | `/api/v1/auth/me` | Authenticated | Current user identity, role, and profile metadata |
| `GET` | `/api/v1/auth/users` | Official, Admin | List all registered users |
| `POST` | `/api/v1/auth/users/invite` | Admin | Invite new user (any role, including Official/Admin) |
| `PUT` | `/api/v1/auth/users/{id}` | Admin | Update user profile or role |
| `DELETE` | `/api/v1/auth/users/{id}` | Admin | Delete user account |
| `GET` | `/api/v1/routes/corridors` | Authenticated | List monitored NH corridors with live accessibility states |
| `POST` | `/api/v1/routes/evaluate` | Driver, Official | Evaluate candidate paths: Safest Viable vs Fastest Available |
| `POST` | `/api/v1/journeys` | Driver | Initiate tracked logistics journey along a selected route |
| `POST` | `/api/v1/journeys/{id}/telemetry` | Driver | Stream live GPS coordinates, heading, and speed pings |
| `GET` | `/api/v1/journeys/{id}/tracking` | Official, Admin | Inspect live journey position and telemetry breadcrumbs |
| `GET` | `/api/v1/journeys/active` | Official, Admin | List all currently active fleet journeys |
| `GET` | `/api/v1/reports` | Authenticated | List field incident reports |
| `POST` | `/api/v1/reports` | Field Worker, Driver | Submit ground incident report with geotagged photo metadata |
| `PATCH` | `/api/v1/reports/{id}/verify` | Official | Official verification and severity confirmation of field reports |
| `DELETE` | `/api/v1/reports/{id}` | Official, Admin | Delete a field report |
| `GET` | `/api/v1/alerts/active` | Authenticated | Retrieve active emergency warnings |
| `POST` | `/api/v1/alerts` | Official, Admin | Broadcast new emergency alert |
| `PATCH` | `/api/v1/alerts/{id}/acknowledge` | Authenticated | Acknowledge a received alert |
| `DELETE` | `/api/v1/alerts/{id}` | Official, Admin | Delete an alert |
| `GET` | `/api/v1/alerts/stream` | Authenticated | Server-Sent Events (SSE) live alert stream |
| `POST` | `/api/v1/evidence/upload` | Field Worker, Driver | Direct upload or signed URL generation for incident photography |
| `GET` | `/api/v1/external/weather` | Authenticated | Query live Open-Meteo weather observations along corridors |
| `GET` | `/api/v1/settings` | Official, Admin | Retrieve current system settings and governance configuration |
| `PUT` | `/api/v1/settings` | Admin | Update system settings (risk thresholds, alert rules, jurisdiction) |

---

## 5. Security & Data Integrity

1. **Database-Authoritative RBAC:** User roles are verified against live database rows on every privileged request, preventing privilege escalation from stale or forged JWT claims.
2. **Sliding-Window Rate Limiting:** In-memory rate limiter defends auth endpoints (20 login/min, 10 register/min, 120 general API/min) from brute-force attacks.
3. **Input Sanitization:** Pydantic v2 schemas reject SQL injection patterns, control characters, null bytes, and out-of-bounds geographic coordinates.
4. **Data Provenance Header:** Every response attaches `X-TiyraSense-Data-Label: LIVE | HISTORICAL | SIMULATED | TEST`.
5. **Security Headers Middleware:** Every response enforces `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and restrictive Content Security Policies.
6. **No Secrets in Source Control:** `AUTH_SECRET_KEY` is required from environment variable in production; auto-generated ephemerally in development/test if absent.

---

## 6. Setup & Execution

### Prerequisites
- Python 3.12+
- Running PostgreSQL 16 instance with PostGIS 3.4, **or** a configured Supabase project

### Installation
```bash
# From workspace root
python -m venv .venv

# Activate environment (Windows PowerShell)
.venv\Scripts\Activate.ps1

# Activate environment (Linux/macOS)
source .venv/bin/activate

# Install backend and ML dependencies
pip install -r backend/requirements.txt
pip install -r ml/requirements.txt
```

### Environment Configuration
```bash
cp .env.example .env
# Edit .env with your DATABASE_URL, AUTH_SECRET_KEY, SUPABASE_*, CLOUDINARY_* values
```

### Database Initialization & Seeding
```bash
# Start PostGIS via Docker Compose
docker compose up db -d

# Seed initial users (Driver, Field Worker, Official, Admin)
python scripts/seed_users.py

# Seed pilot road network (NH-06, Damra Bypass, NH-27, NH-37, NH-102)
python scripts/seed_road_network.py
```

### Running the API Server
```bash
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation is accessible at `http://localhost:8000/docs` in development mode.

### Running Tests
```bash
# Run all 48 backend unit, security, ML, and integration tests
python -m pytest backend/tests -v

# Run the 20-step continuous selection E2E scenario test
python -m pytest tests/test_e2e_demo_scenario.py -v
```

### Docker (Production)
```bash
# Build and run via Docker Compose (PostGIS + API)
docker compose up --build

# Or build the backend image alone
docker build -f backend/Dockerfile -t tiyrasense-api .
```
