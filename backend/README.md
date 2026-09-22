# TiyraSense Backend Service

The backend tier of **TiyraSense** provides high-performance, asynchronous REST APIs, spatial graph routing, multi-factor risk computation, machine learning disruption prediction inference, evidence arbitration, and real-time alert dispatching for logistics operations across the North Eastern Region (NER).

---

## 1. Technology Stack

| Layer | Technology | Version | Purpose |
|---|---|:---:|---|
| **Language & Runtime** | Python | 3.12+ | Async backend execution |
| **API Framework** | FastAPI | 0.115+ | High-concurrency async REST gateway & OpenAPI generation |
| **ASGI Web Server** | Uvicorn | 0.34+ | Production-grade async HTTP/1.1 and WebSockets server |
| **Database ORM** | SQLAlchemy 2.0 + asyncpg | 2.0+ / 0.30+ | Non-blocking async PostgreSQL access with native connection pooling |
| **Geospatial Processing** | GeoAlchemy2 + Shapely | 0.17+ / 2.0+ | PostGIS geometry serialization, WKT/GeoJSON spatial manipulation |
| **Validation & Serialization** | Pydantic v2 | 2.10+ | Strict type validation, request/response schema parsing |
| **Authentication & RBAC** | Python-Jose + Passlib (bcrypt) | 3.3+ / 1.7+ | JWT issuance, password hashing, database-authoritative role verification |
| **Routing Engine** | OSRM (Open Source Routing Machine) | v5.24+ | Base navigation geometries, distance/time matrices via HTTP client |
| **Weather Telemetry** | Open-Meteo API Client | httpx async | Hourly precipitation, soil moisture, and atmospheric forecasts |
| **ML Inference** | scikit-learn + joblib | 1.6+ / 1.4+ | Sub-5ms forward Disruption Probability ($P_{\text{disrupt}}$) inference |
| **Advisory Generation** | Google Gemini API (google-genai SDK) | 0.1+ / Flash 2.0 | Natural-language multilingual incident warnings (strictly outside safety decisions) |
| **Cloud Storage** | Cloudinary REST Integration | httpx async | Secure storage and CDN delivery for geotagged field photos |
| **Testing & Quality** | pytest + pytest-asyncio + httpx | 8.3+ / 0.24+ | Comprehensive unit, security, integration, and E2E scenario testing |

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
│   │       │   ├── journeys.py       # Journey lifecycle, rerouting, & GPS telemetry pings
│   │       │   └── routes.py         # Multi-candidate route evaluation (Safest vs Fastest)
│   │       └── router.py             # Top-level API router mounting all endpoint groups
│   ├── core/
│   │   ├── config.py                 # Pydantic Settings management (env vars, secrets)
│   │   ├── database.py               # Async engine and async sessionmaker lifecycle
│   │   └── security.py               # Password hashing, JWT token creation/decoding
│   ├── models/                       # SQLAlchemy declarative models (18 PostGIS tables)
│   │   ├── alert.py                  # Emergency alerts and driver acknowledgments
│   │   ├── field_report.py           # Field incident reports and official verifications
│   │   ├── journey.py                # Journey tracking, telemetry logs, and active corridors
│   │   ├── route.py                  # Road segments, candidate routes, and hazard zones
│   │   └── user.py                   # User identity, roles (Driver, Field, Official, Admin)
│   ├── schemas/                      # Pydantic request/response validation schemas
│   │   ├── alert.py
│   │   ├── auth.py
│   │   ├── field_report.py
│   │   ├── journey.py
│   │   └── route.py
│   ├── services/                     # Core business logic and computational services
│   │   ├── conflict_resolver.py      # Multi-source evidence arbitration & reliability scoring
│   │   ├── explanation_service.py    # Multilingual advisory generation with Gemini + fallbacks
│   │   ├── geocoding_service.py      # Coordinate-to-hub and corridor lookup
│   │   ├── radar_service.py          # Real-time fleet telemetry radar and proximity search
│   │   ├── risk_engine.py            # Deterministic multi-factor road risk calculation
│   │   ├── routing_service.py        # OSRM interface, segment penalization, route comparator
│   │   └── weather_service.py        # Open-Meteo client with caching & fallback logic
│   └── main.py                       # FastAPI application entrypoint and middleware pipeline
├── migrations/
│   └── init.sql                      # Canonical PostGIS database schema (18 tables, RLS)
├── requirements.txt                  # Locked Python package dependencies
└── tests/                            # Pytest test suite (auth, routes, risk, reports, etc.)
```

---

## 3. Core Service Subsystems

### 3.1 Deterministic Risk Engine (`services/risk_engine.py`)
Computes an auditable, multi-factor risk score $R \in [0.0, 1.0]$ across road segments using four calibrated dimensions:
$$R = w_r \cdot S_{\text{rain}} + w_s \cdot S_{\text{slope}} + w_h \cdot S_{\text{hist}} + w_o \cdot S_{\text{obs}}$$
- $S_{\text{rain}}$: Dynamic rainfall intensity from Open-Meteo observations and 2-hour forecasts.
- $S_{\text{slope}}$: Digital elevation model gradient and Geological Survey of India landslide susceptibility.
- $S_{\text{hist}}$: Historical blockage frequency along known fault zones.
- $S_{\text{obs}}$: Verified field incident reports and active obstruction severities.

### 3.2 Routing & Corridor Optimizer (`services/routing_service.py`)
- Interfaces with OSRM to generate candidate multi-route geometries between logistics hubs (e.g. Guwahati Logistics Hub to Shillong Command Terminal).
- Evaluates candidate paths against PostGIS road segments and dynamic hazard buffers.
- Recommends the **Safest Viable** route based on composite segment risk while continuously displaying the **Fastest Available** route for dispatcher comparison.

### 3.3 Conflict Resolution Engine (`services/conflict_resolver.py`)
Arbitrates conflicting ground reports from drivers, field personnel, and automated sensors using source credibility ratings:
- Official / Disaster Authority: Weight 1.0
- Field Worker (with geotagged photo): Weight 0.85
- Commercial Driver: Weight 0.60
- Decays evidence influence smoothly over time to prevent stale road closures.

### 3.4 ML Disruption Predictor (`ml/predict.py`)
- Executes fast forward inference with calibrated probability output representing likelihood of transit disruption within 2 hours.
- Strictly isolated from route choice logic: serves as an informational feature and provenance-tagged probability value.

### 3.5 Advisory Explanation Generator (`services/explanation_service.py`)
- Generates localized natural-language advisories in English, Hindi, Assamese, and Bengali using the Google Gemini API.
- Implements deterministic rule-based template fallbacks if the network or API is unavailable.
- **Invariable Boundary**: The LLM never calculates risk scores, alters accessibility states, or changes route choices.

---

## 4. API Endpoints Map

All endpoints require standard HTTP Bearer JWT authentication (except public health probes and login/register):

| Method | Route | Access Role | Description |
|---|---|:---:|---|
| `GET` | `/api/v1/health` | Public | System liveness, database ping, and PostGIS extension probe |
| `POST` | `/api/v1/auth/register` | Public | Role-restricted registration (`DRIVER` & `FIELD_WORKER` only) |
| `POST` | `/api/v1/auth/login` | Public | Token issuance (email/password $\rightarrow$ JWT Bearer token) |
| `GET` | `/api/v1/auth/me` | Authenticated | Current user identity, role, and profile metadata |
| `POST` | `/api/v1/routes/evaluate` | Driver, Official | Evaluate candidate paths, returning Safest Viable vs Fastest Available |
| `POST` | `/api/v1/journeys` | Driver | Initiate tracked logistics journey along a selected route |
| `POST` | `/api/v1/journeys/{id}/telemetry` | Driver | Stream live GPS coordinates, heading, and speed pings |
| `POST` | `/api/v1/journeys/{id}/reroute` | Driver | Accept proactive diversion around newly reported hazards |
| `POST` | `/api/v1/reports` | Field, Driver | Submit ground incident report with geotagged photo metadata |
| `PATCH` | `/api/v1/reports/{id}/verify` | Official | Official verification and severity confirmation of field reports |
| `GET` | `/api/v1/alerts/active` | Authenticated | Retrieve active emergency warnings filtered by bounding box / route |
| `POST` | `/api/v1/evidence/upload` | Field, Driver | Direct upload or signed URL generation for incident photography |
| `GET` | `/api/v1/external/weather` | Authenticated | Query live Open-Meteo weather observations along corridors |

---

## 5. Security & Data Integrity

1. **Database-Authoritative RBAC**: User roles are verified against live database rows on every privileged request, preventing privilege escalation from stale or forged JWT claims.
2. **Input Sanitization**: Pydantic v2 schemas reject SQL injection patterns, control characters, and out-of-bounds geographic coordinates.
3. **Data Provenance Header**: Every response attaches `X-TiyraSense-Data-Label: LIVE | HISTORICAL | SIMULATED | TEST`.
4. **Security Headers**: Middleware enforces `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and restrictive Content Security Policies.

---

## 6. Setup & Execution

### Prerequisites
- Python 3.12+
- Running PostgreSQL 16 instance with PostGIS 3.4 (`localhost:5432`)

### Installation
```bash
# From workspace root
python -m venv .venv
# Activate environment (Windows PowerShell)
.venv\Scripts\Activate.ps1
# Activate environment (Linux/macOS)
source .venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt
```

### Database Initialization & Seeding
```bash
# Seed initial users (Driver, Field Worker, Official, Admin)
python scripts/seed_users.py

# Seed pilot road network (Guwahati-Shillong NH-06 & Damra Bypass)
python scripts/seed_road_network.py
```

### Running the API Server
```bash
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation is accessible at `http://localhost:8000/docs` in development mode.

### Running Tests
```bash
# Run all backend unit and integration tests
python -m pytest backend/tests -v

# Run the 20-step continuous selection scenario test
python -m pytest tests/test_e2e_demo_scenario.py -v
```
