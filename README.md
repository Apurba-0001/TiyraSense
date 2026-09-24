<p align="center">
  <img src="Images/TiyraSense_horizontal.png" alt="TiyraSense Banner" width="460" />
</p>

<h1 align="center">TiyraSense</h1>

<p align="center">
  <strong>SIH 2026 · Problem Statement 26002</strong><br>
  <em>AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.12+-3776AB?style=flat&logo=python&logoColor=white" alt="Python 3.12+" />
  <img src="https://img.shields.io/badge/FastAPI-0.115+-009688?style=flat&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/React-18.2+-61DAFB?style=flat&logo=react&logoColor=black" alt="React 18" />
  <img src="https://img.shields.io/badge/TypeScript-5.4+-3178C6?style=flat&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/PostgreSQL_16-PostGIS_3.4-336791?style=flat&logo=postgresql&logoColor=white" alt="PostGIS" />
  <img src="https://img.shields.io/badge/scikit--learn-1.6+-F7931E?style=flat&logo=scikit-learn&logoColor=white" alt="scikit-learn" />
  <img src="https://img.shields.io/badge/Tests-129%20Passing%20(100%25)-brightgreen?style=flat" alt="Tests" />
  <img src="https://img.shields.io/badge/Analysis-0%20Issues-brightgreen?style=flat" alt="Analysis" />
</p>

---

## Executive Overview

**TiyraSense** is a risk-aware decision-support platform engineered specifically for the extreme geographic, meteorological, and connectivity vulnerabilities of Northeast India. It unifies high-resolution numerical weather forecasts, PostGIS geospatial terrain profiles, historical road cut frequencies, physical geological susceptibility indices, and real-time crowdsourced field evidence to:

1. **Assess Current Physical Road Accessibility** across critical hill supply lines.
2. **Predict Disruption Probability ($P_{\text{disrupt}}$)** over a 2-hour forward horizon using calibrated machine learning.
3. **Quantify Multi-Factor Composite Segment Risk** through deterministic, auditable weighting formulas.
4. **Recommend the Safest Viable Route** while keeping the **Fastest Available Route** visible for operator comparison.
5. **Proactively Alert Approaching Logistics Carriers** and dispatchers before and during mountain transit.
6. **Function Offline-First** with hardware-backed encryption and autonomous synchronization when entering and leaving cellular dead zones.

> [!IMPORTANT]
> **TiyraSense is a risk-aware decision-support platform, not a generic consumer navigation app or a safety guarantee.**  
> Three core concepts remain distinct, traceable, and uncollapsed:
> - **Current Accessibility:** Observed physical operational state (`OPEN`, `CAUTION`, `RESTRICTED`, `HIGH_RISK`, `BLOCKED`, `UNKNOWN`).
> - **Disruption Probability ($P_{\text{disrupt}}$):** Time-bounded machine learning inference with explicit model provenance and physics fallback.
> - **Route Risk ($R_{\text{composite}}$):** Composite score combining segment accessibility, predicted rainfall, terrain slope, lithology, and active obstructions.

---


## 1. High-Level Architecture & Information Flow

```
[EXTERNAL DATA SOURCES] ───► Open-Meteo Weather, OSM Corridors, GSI Lithology, Cloudinary
          │
          ▼
[ML PREDICTION SERVICE] ───► Calibrated P_disrupt (2-Hour Forward Horizon, ROC-AUC: 0.8557)
          │
          ▼
[DETERMINISTIC RISK ENGINE] ──► Multi-Factor Segment Score (Rain 35%, Slope 25%, History 15%, Obs 25%)
          │
          ▼
[ROUTING & OPTIMIZER] ────► OSRM Base Paths + PostGIS Hazard Penalization (Safest vs Fastest)
          │
          ▼
[GEOFENCED RADAR SERVICE] ──► In-Transit GPS Telemetry Ingestion & Forward Lookahead Radar (25 km)
          │
          ▼
[EVIDENCE CONFLICT RESOLVER] ◄─ Ground Incident Reports (Disaster Authority 1.0, Field 0.85, Driver 0.60)
          │
          ▼
[MULTILINGUAL ADVISORY] ───► Google Gemini API (Assamese, Bengali, Hindi, English Driver Bulletins)
```

> [!CAUTION]
> **Strict Architectural Boundary:** The LLM (Google Gemini API) is restricted strictly to explanation, summarization, and multilingual translation. It **never** calculates risk scores, alters road accessibility states, or selects route recommendations. Deterministic risk, routing, and optimization layers make all safety-critical recommendations.

---

## 2. Core Platform Capabilities

### 2.1 Multi-Factor Deterministic Risk Engine
Computes an auditable, transparent risk score $R \in [0.0, 1.0]$ across discrete road segments using four calibrated dimensions:
$$R = w_r \cdot S_{\text{rain}} + w_s \cdot S_{\text{slope}} + w_h \cdot S_{\text{hist}} + w_o \cdot S_{\text{obs}}$$
- **$S_{\text{rain}}$ ($w_r = 0.35$):** Dynamic rainfall intensity from Open-Meteo observations and 2-hour forecasts.
- **$S_{\text{slope}}$ ($w_s = 0.25$):** Digital elevation model gradient and Geological Survey of India (GSI) landslide susceptibility.
- **$S_{\text{hist}}$ ($w_h = 0.15$):** Historical blockage frequency along known tectonic fault and cut zones.
- **$S_{\text{obs}}$ ($w_o = 0.25$):** Verified field incident reports and active obstruction severities.
- **Critical State Override:** Confirmed blockages immediately escalate segment risk to $R = 1.0$. Route composite risk blends a 70% distance-weighted average with a 30% bottleneck peak penalty.

### 2.2 Machine Learning Disruption Predictor ($P_{\text{disrupt}}$)
- **Objective:** Predicts the probability that a specific mountain corridor segment will experience transit disruption within a **2-hour prediction horizon**.
- **Features:** 8 physical, meteorological, and crowd features (`precip_1h_mm`, `precip_forecast_2h_mm`, `soil_moisture_pct`, `slope_degrees`, `landslide_susceptibility`, `historical_cuts_count`, `road_class_encoded`, `recent_unverified_reports`).
- **Strict Anti-Leakage Temporal Splitting:** Strict chronological cutoffs prevent monsoon autocorrelation leakage (Train: Monsoon 2023–2024, Val: June 2025, Test: Peak Monsoon July–August 2025).
- **Calibrated Classifier:** `HistGradientBoostingClassifier` with sigmoid probability calibration (`CalibratedClassifierCV`).
- **Verified Benchmark:** **ROC-AUC: 0.8557** ($\ge 0.85$ target met), **PR-AUC: 0.7749** ($\ge 0.72$ target met), with sub-5ms forward inference latency (`ml/predict.py`).

### 2.3 Dual-Route Logistics Optimization
- Generates candidate multi-route geometries between hubs (e.g., Guwahati Logistics Hub $\rightarrow$ Shillong Command Terminal) via OSRM.
- Evaluates candidate paths against PostGIS road segments and dynamic hazard buffers.
- Recommends the **Safest Viable Route** based on composite segment risk while continuously displaying the **Fastest Available Route** for dispatcher comparison.
- When critical incidents block a primary corridor (such as NH-06), virtual hazard segments inject safety penalties into OSRM bounding boxes, immediately diverting transit onto viable bypasses (such as the Damra-Mawkyrwat State Highway).

### 2.4 Real-Time GPS Telemetry Radar & Hazard Lookahead
- Ingests driver GPS telemetry breadcrumbs (latitude, longitude, speed, heading, altitude).
- Computes dynamic remaining distance and ETA to destination.
- Runs a forward hazard radar lookahead alerting in-transit drivers to verified blockages and impending high-risk zones up to 25 km ahead along their active path.

### 2.5 Offline-First Mobile Client & Autonomous Background Sync
- **Encrypted Session Persistence:** Stores JWT tokens and user models in hardware-backed secure storage (`flutter_secure_storage` backed by Android Keystore AES-GCM, iOS Keychain, and Windows DPAPI). Cold boots in remote dead zones without cellular reception retain login state.
- **Offline Incident Queueing:** Ground reports captured in connectivity dead zones are persisted in `OfflineStorageService` with status `PENDING_SYNC`.
- **Autonomous Sync Daemon:** Proactive background auto-sync loops (running every 8 seconds) and app resume listeners (`WidgetsBindingObserver`) detect network restoration and automatically push queued reports and photo evidence.
- **Direct Cloud CDN Upload:** Physical mobile devices upload evidence photos directly to Cloudinary CDN via HTTPS, eliminating port forwarding and local loopback bottlenecks.
- **Flexible Network Configuration:** Built-in `ServerConnectionSheet` modal supports 1-tap switching between USB ADB reverse (`adb reverse tcp:8000 tcp:8000`), local Wi-Fi LAN (`10.x`, `192.168.x`), and Android emulator loopbacks (`10.0.2.2`).

### 2.6 Command & Control Operations Console
- **Interactive Leaflet GIS Map:** Displays real Web Mercator spatial tiles, monitored corridors (NH-06, Damra Bypass, NH-27, NH-37, NH-102), real-time accessibility colors, and Google Maps styled layer switches (Default, Satellite, Terrain).
- **Fleet Telemetry Inspector:** Tracks active vehicles with driver names, vehicle registration numbers, speed, heading, and live corridor status.
- **Field Incident Verification Workbench:** Disaster officials inspect incoming reports, check GPS accuracy, view full-resolution photo evidence in an interactive modal lightbox, and execute 1-click verification (`PATCH /api/v1/reports/{id}/verify`).
- **Emergency Alert Feed:** Broadcasts urgent corridor warnings, tracks driver acknowledgments, and notifies dispatchers in real time.

### 2.7 Evidence Conflict Resolution & Ground Truth Arbitration
- Weights incoming reports by reporter credibility:
  - Disaster Authority / Government Official: **Weight 1.0**
  - Field Worker (with geotagged photographic evidence): **Weight 0.85**
  - Commercial Logistics Driver: **Weight 0.60**
- Applies smooth temporal decay to prevent stale road closures from lingering once conditions improve.

---

## 3. Technology Stack

| Layer | Technologies Used | Key Packages & Libraries | Role in TiyraSense |
|---|---|---|---|
| **Mobile Client** | Flutter 3.x, Dart 3.x | `flutter_secure_storage`, `geolocator`, `image_picker`, `image`, `flutter_local_notifications`, `http` | Offline-first driver and field-worker client with hardware encryption, GPS radar telemetry, offline queueing, and Cloudinary photo evidence. |
| **Web Console** | React 18, TypeScript 5.4, Vite | `leaflet`, `lucide-react`, `react-router-dom`, `vitest`, `@testing-library/react` | Command & control operations dashboard for disaster officials and dispatchers with live GIS maps, fleet tracking, and incident verification. |
| **Backend API** | Python 3.12+, FastAPI, Uvicorn | `SQLAlchemy` (asyncio), `asyncpg`, `GeoAlchemy2`, `Pydantic v2`, `python-jose`, `passlib` (bcrypt), `httpx` | Asynchronous REST gateway, deterministic risk scoring, corridor routing optimizer, multi-source evidence arbitration, and role-based access control. |
| **Machine Learning** | Python 3.12+, scikit-learn | `HistGradientBoostingClassifier`, `CalibratedClassifierCV`, `joblib`, `numpy`, `scipy` | Sub-5ms forward Disruption Probability model trained on 8 physical features with strict anti-leakage temporal splitting (ROC-AUC: 0.8557, PR-AUC: 0.7749). |
| **Spatial Database** | PostgreSQL 16 + PostGIS 3.4 | PostGIS extension, spatial R-Tree indexing, Row-Level Security (RLS) | 18 normalized tables managing road segments, dynamic hazard polygons, fleet telemetry breadcrumbs, field reports, and audit logs. |
| **GIS & Routing** | OpenStreetMap, Leaflet, OSRM | OSRM v5.24 HTTP client, EPSG:4326 PostGIS geometry | Free, open-source cartography and routing engine with dynamic risk-penalized alternative route calculation. |
| **Weather Telemetry** | Open-Meteo API | REST API / ECMWF IFS high-resolution model | Automated hourly rainfall, soil moisture, surface pressure, and 2-hour forecasts along North Eastern corridors. |
| **Multilingual AI** | Google Gemini API (Flash 2.0 / 1.5) | `google-genai` Python SDK | Natural-language incident translation and localized driver safety advisories backed by deterministic template fallbacks. |
| **Cloud Storage** | Cloudinary | Direct REST upload integration | Secure media storage and CDN delivery for geotagged field incident photographs. |

---

## 4. User Personas & RBAC Matrix

| Role | Client Interface | Primary Capabilities | Registration Mechanism |
|---|---|---|---|
| **Driver** | Flutter Mobile | Plan journeys, evaluate Safest Viable vs Fastest Available routes, stream GPS telemetry, receive lookahead hazard radar alerts, report obstructions, navigate offline. | Public self-service registration (`POST /api/v1/auth/register`). |
| **Field Worker** | Flutter Mobile | Submit ground-truth incident reports with high-accuracy GPS coordinates and compressed camera evidence photos; work completely offline in dead zones. | Public self-service registration (`POST /api/v1/auth/register`). |
| **Official** | React Web Console | Monitor regional corridors and active fleet telemetry, review and verify field reports, trigger emergency alerts, inspect ML disruption forecasts. | Database-authoritative administrative provisioning only. |
| **Admin** | React Web Console | Configure algorithm risk weights, manage monitored geographic zones, provision personnel, review immutable system audit logs. | Database-authoritative administrative provisioning only. |

> [!NOTE]
> **Privilege Escalation Defense:** Public registration rejects any request attempting to create `OFFICIAL` or `ADMIN` accounts with HTTP 422 Unprocessable Entity. Privileged roles can only be granted by database administrators in PostgreSQL.

---

## 5. Repository Structure

```text
TiyraSense/
├── Images/                           # Visual assets, branding logos, and UI screenshots
│   ├── TiyraSense.png                # Primary project logo mark
│   ├── TiyraSense_horizontal.png     # Horizontal brand banner
│   ├── app.webp                      # Mobile navigation UI screenshot
│   ├── mapview.webp                  # Web GIS command console screenshot
│   ├── login.webp                    # Mobile authentication UI screenshot
│   └── signup.webp                   # Mobile self-registration UI screenshot
├── backend/                          # FastAPI REST services, risk engine, and PostGIS models
│   ├── app/                          # Core application package
│   │   ├── api/                      # REST endpoints (auth, routes, journeys, reports, alerts, evidence)
│   │   ├── core/                     # Settings, async database session engine, security utils
│   │   ├── models/                   # SQLAlchemy declarative models (18 PostGIS spatial tables)
│   │   ├── schemas/                  # Pydantic v2 request/response schemas
│   │   ├── services/                 # Risk engine, routing optimizer, weather, conflict resolver, radar
│   │   └── main.py                   # FastAPI entrypoint, CORS configuration, and security middleware
│   ├── migrations/init.sql           # PostGIS schema definition (18 tables, spatial indexes, RLS)
│   ├── tests/                        # Backend unit, security, and integration test suite
│   ├── requirements.txt              # Locked Python package dependencies
│   └── README.md                     # Backend-specific architecture and developer guide
├── web/                              # React 18 + TypeScript + Vite operations dashboard
│   ├── src/                          # Application source code
│   │   ├── components/               # Modular UI (VectorGisMap, JourneyPlanningModal, Header, Sidebar)
│   │   ├── layouts/                  # Authenticated master dashboard layout
│   │   ├── pages/                    # Views (Dashboard, FieldReports, CorridorMonitor, AlertFeed, Settings)
│   │   ├── routes/RoleGuard.tsx      # Client-side RBAC protection enforcing Official & Admin access
│   │   ├── services/api.ts           # Typed API client with automatic Bearer token handling
│   │   ├── state/AuthContext.tsx     # React authentication context and profile state
│   │   └── types/                    # TypeScript interfaces for data models and API envelopes
│   ├── test/                         # Vitest component and integration tests
│   ├── package.json                  # Web dependencies and scripts
│   ├── vite.config.ts                # Vite configuration with backend proxying
│   └── README.md                     # Web console architecture and developer guide
├── mobile/                           # Flutter offline-first mobile application
│   ├── lib/                          # Application source code
│   │   ├── models/                   # Dart domain models (UserModel, ReportItem)
│   │   ├── screens/                  # Views (DriverHome, FieldWorkerHome, MapScreen, Reports, Profile)
│   │   ├── services/                 # ApiService, LocationService, OfflineStorageService, ReportService
│   │   ├── state/auth_provider.dart  # Hardware-backed encrypted session management
│   │   ├── theme/app_theme.dart      # High-visibility dark theme optimized for in-cab operation
│   │   └── widgets/                  # Modular widgets (ServerConnectionSheet, StatusPillBadge, Sheets)
│   ├── test/                         # Flutter widget and unit test suite
│   ├── pubspec.yaml                  # Mobile dependencies and asset declarations
│   └── README.md                     # Mobile architecture and developer guide
├── ml/                               # Machine Learning disruption prediction pipeline
│   ├── models/                       # Serialized model artifacts (joblib) and metadata (json)
│   ├── dataset.py                    # Anti-leakage temporal dataset generator & feature engineer
│   ├── train.py                      # Model training, probability calibration, and export script
│   ├── predict.py                    # Sub-5ms forward inference service with physics fallback
│   ├── requirements.txt              # Locked ML dependencies (scikit-learn, joblib, numpy, scipy)
│   └── README.md                     # ML pipeline and feature engineering guide
├── docs/                             # Comprehensive system specifications
│   ├── architecture.md               # High-level architecture, module boundaries, external integrations
│   ├── api_specification.md          # REST API contracts, endpoints, and response envelopes
│   ├── data_model.md                 # 18-table PostGIS spatial schema and entity relationships
│   ├── data_sources_and_pipelines.md # External data ingestion (Open-Meteo, OSM, Cloudinary)
│   ├── ml_specification.md           # Machine learning model design & validation protocols
│   ├── risk_and_conflict_resolution.md # Multi-factor risk math and evidence arbitration rules
│   ├── alert_and_emergency.md        # Alert generation, priority levels, and escalation
│   ├── offline_and_sync.md           # Mobile offline queueing, conflict handling, and retry logic
│   ├── user_roles_and_flows.md       # Persona user journeys and RBAC permission matrix
│   ├── testing_strategy.md           # Testing pyramid, verification gates, and CI checks
│   ├── deployment.md                 # Docker Compose local evaluation & production setup
│   └── CLOUDINARY_SETUP_GUIDE.md     # Cloudinary media storage configuration
├── scripts/                          # Seeding and utility tools
│   ├── seed_users.py                 # Seeds test users across Driver, Field, Official, Admin roles
│   └── seed_road_network.py          # Seeds NH-06, Damra bypass, and regional corridors in PostGIS
├── tests/                            # Cross-stack integration and end-to-end tests
│   └── test_e2e_demo_scenario.py     # Continuous 20-step canonical selection demonstration scenario
├── AGENTS.md                         # Authoritative rules of engagement for developers and AI agents
├── BUILD_GUIDE.md                    # Canonical 11-phase development roadmap and exit criteria
├── DECISIONS.md                      # Architectural decision records (D-001 through D-018)
├── PROJECT_CONTEXT.md                # Permanent product knowledge, core promise, operating principles
├── SECURITY.md                       # Authoritative security policy, RBAC gates, vulnerability checklist
├── SESSION.md                        # Active session state and verified handoff history
├── LOG.md                            # Forensic chronological development log
├── TODO.md                           # Master phase status board (all 11 phases COMPLETE)
└── docker-compose.yml                # Multi-container orchestration (PostGIS database)
```

---

## 6. Monitored Corridors & Seed Data

The platform comes pre-seeded with primary North Eastern Region supply corridors and default test accounts:

### 6.1 Monitored Supply Corridors
- **NH-06 (Guwahati $\rightarrow$ Shillong):** Primary economic lifeline carrying medical supplies, fuel, and food into Meghalaya, Mizoram, Tripura, and the Barak Valley. Critical choke points modeled: Jorabat, Nongpoh, Umling.
- **Guwahati–Damra–Mawkyrwat Bypass:** Secondary state highway safety alternative utilized when NH-06 experiences critical blockage or high landslide risk.
- **NH-27 / NH-29 (Guwahati $\rightarrow$ Silchar):** Arterial long-haul corridor connecting the Brahmaputra Valley to the Barak Valley.
- **NH-37 (Numaligarh $\rightarrow$ Jorhat):** Upper Assam logistics corridor traversing flood-prone riverine tracts.
- **NH-102 (Imphal $\rightarrow$ Moreh):** Cross-border logistics route with high tectonic slope vulnerability.

### 6.2 Demonstration Accounts (Sample Credentials)

| Role | Demo Email | Demo Password | Persona | Department / Organization |
|---|---|---|---|---|
| **Driver** | `demo-driver@tiyrasense.in` | `Demo@2026` | Commercial Freight Driver | Regional Highway Logistics Fleet |
| **Field Worker** | `demo-worker@tiyrasense.in` | `Demo@2026` | Field Incident Scout | Emergency Ground Survey Cell |
| **Official** | `demo-official@tiyrasense.in` | `Demo@2026` | Disaster Operations Officer | State Disaster Management Authority |
| **Admin** | `demo-admin@tiyrasense.in` | `Demo@2026` | Platform Administrator | NER Logistics Command Center |

---

## 7. Quickstart & Execution Guide

### 7.1 Start the PostGIS Spatial Database
```bash
docker compose up db -d
```
*Starts PostgreSQL 16 + PostGIS 3.4 on `localhost:5432` with automatic schema initialization from `backend/migrations/init.sql`.*

### 7.2 Initialize and Run the Backend API
```bash
# 1. Setup and activate Python 3.12+ virtual environment
python -m venv .venv
.venv\Scripts\Activate.ps1    # On Windows PowerShell
source .venv/bin/activate      # On Linux/macOS

# 2. Install dependencies
pip install -r backend/requirements.txt
pip install -r ml/requirements.txt

# 3. Seed users and road network in PostGIS
python scripts/seed_users.py
python scripts/seed_road_network.py

# 4. Start FastAPI server
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```
- Interactive Swagger OpenAPI documentation: `http://localhost:8000/docs`
- Health probe: `http://localhost:8000/api/v1/health`

### 7.3 Run the React Operations Console
```bash
cd web
npm install
npm run dev
```
- Console will be available at: `http://localhost:5173`
- Log in with your Official or Admin credentials (e.g. `demo-official@tiyrasense.in` or `demo-admin@tiyrasense.in`) to access command features.

### 7.4 Run the Flutter Mobile Client
```bash
cd mobile
flutter pub get

# Run on Chrome for local web preview
flutter run -d chrome

# Run on physical Android device (via USB)
adb reverse tcp:8000 tcp:8000
flutter run -d <device_id>
```
*On physical devices, open the connection chip on the login screen to toggle between USB ADB (`127.0.0.1:8000`), Laptop Wi-Fi LAN (`http://<laptop_ip>:8000/api/v1`), or Cloudflare/Ngrok tunnels.*

### 7.5 Retrain ML Disruption Model (Optional)
```bash
python ml/train.py
```
*Generates the temporally split dataset, trains and calibrates the `HistGradientBoostingClassifier`, benchmarks ROC-AUC / PR-AUC, and writes serialized artifacts to `ml/models/`.*

---

## 8. Verification & Comprehensive Automated Testing

The entire platform is protected by strict automated test suites across all tiers. Currently, **129 out of 129 automated tests pass with 100% success**:

```bash
# 1. Backend Unit, Security, ML & 20-Step Continuous Scenario Tests (49/49 Passing)
python -m pytest backend/tests tests/test_e2e_demo_scenario.py -v

# 2. Web Frontend Component, Tracking & Integration Tests (26/26 Passing)
cd web && npm test -- --run

# 3. Web Production Build Compilation (Clean Build, 0 Errors)
cd web && npm run build

# 4. Mobile Unit & Widget Tests (54/54 Passing)
cd mobile && flutter test

# 5. Mobile Static Analysis (0 Errors, 0 Warnings, 0 Hints)
cd mobile && flutter analyze

# 6. Backend Static Type Analysis (0 Errors, 0 Warnings)
npx pyright backend/app
```

---

## 9. Security & Provenance Standards

1. **Database-Authoritative RBAC:** User roles are verified against live database records on every privileged request, preventing privilege escalation from stale or forged JWT claims.
2. **Mandatory Provenance Tagging:** Every API response attaches `X-TiyraSense-Data-Label: LIVE | HISTORICAL | SIMULATED | TEST`. Simulated data is never conflated with live ground data.
3. **OS-Level Encrypted Mobile Sessions:** Mobile JWT tokens and user profiles are stored using hardware-backed encryption (Android Keystore AES-GCM / iOS Keychain) per OWASP Mobile Top 10 standards.
4. **Input Sanitization & Injection Defense:** Pydantic v2 schemas reject SQL injection patterns, control characters, null bytes, and out-of-bounds coordinate payloads at API boundaries before business logic execution.
5. **HTTP Security Headers:** Responses enforce `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and restrictive Content Security Policies.

---

## 10. Documentation Index

### Core Working Agreements & Governance
- [AGENTS.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/AGENTS.md) — Authoritative agent instructions, reading order, code conciseness rules, and Definition of Done.
- [SECURITY.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/SECURITY.md) — Authoritative security policy, RBAC verification, credential handling, and threat checklist.
- [DECISIONS.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/DECISIONS.md) — Binding architectural decision records (D-001 through D-018).
- [PROJECT_CONTEXT.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/PROJECT_CONTEXT.md) — Permanent product context, core promise, operating principles, and target personas.
- [BUILD_GUIDE.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/BUILD_GUIDE.md) — Canonical 11-phase development roadmap and exit criteria.
- [SESSION.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/SESSION.md) — Active session state, verification evidence, and handoff history.
- [LOG.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/LOG.md) — Forensic chronological development log of every completed task.
- [TODO.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/TODO.md) — Current work board and phase completion status.

### Module Technical Guides
- [backend/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/README.md) — FastAPI services, risk engine, database models, and API map.
- [web/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/web/README.md) — React dashboard, Leaflet GIS mapping, and verification workbench.
- [mobile/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/README.md) — Flutter client, offline storage queue, and GPS telemetry radar.
- [ml/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/ml/README.md) — Disruption prediction model, features, and inference engine.

### Detailed Architectural Specifications
- [docs/architecture.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/architecture.md) — High-level architecture, topology, and module boundaries.
- [docs/api_specification.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/api_specification.md) — REST API contracts, endpoints, and response envelopes.
- [docs/data_model.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/data_model.md) — 18-table PostGIS spatial schema and entity relationships.
- [docs/data_sources_and_pipelines.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/data_sources_and_pipelines.md) — External data integration specifications (Open-Meteo, OSM, Cloudinary).
- [docs/ml_specification.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/ml_specification.md) — Machine learning model design, temporal splitting, and validation protocols.
- [docs/risk_and_conflict_resolution.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/risk_and_conflict_resolution.md) — Multi-factor risk math and evidence arbitration rules.
- [docs/alert_and_emergency.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/alert_and_emergency.md) — Alert dispatch and emergency mode protocols.
- [docs/offline_and_sync.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/offline_and_sync.md) — Offline caching and synchronization protocols.
- [docs/user_roles_and_flows.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/user_roles_and_flows.md) — User personas and interaction workflows.
- [docs/testing_strategy.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/testing_strategy.md) — Testing pyramid and QA verification gates.
- [docs/deployment.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/deployment.md) — Local evaluation and production deployment.
- [docs/CLOUDINARY_SETUP_GUIDE.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/CLOUDINARY_SETUP_GUIDE.md) — Cloudinary media storage configuration.
