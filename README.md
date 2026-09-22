# TiyraSense

**SIH 2026 · Problem Statement 26002**  
**AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)**

TiyraSense is a risk-aware decision-support platform designed specifically for the extreme terrain and climate vulnerabilities of Northeast India. It aggregates validated road network data, dynamic numerical weather forecasts, PostGIS geospatial terrain profiles, historical incident records, and real-time crowdsourced field observations to:
1. Assess current physical road accessibility.
2. Predict localized disruption likelihood ($P_{\text{disrupt}}$) within a 2-hour forward horizon.
3. Quantify multi-factor composite segment risk.
4. Recommend the **Safest Viable** route while keeping the **Fastest Available** route visible.
5. Proactively alert affected logistics carriers before and during mountain journeys.

> [!IMPORTANT]
> **TiyraSense is a risk-aware decision-support platform, not a generic consumer navigation app or a safety guarantee.**  
> Three core concepts remain distinct, traceable, and uncollapsed:
> - **Current Accessibility**: Observed physical state (`OPEN`, `CAUTION`, `RESTRICTED`, `HIGH_RISK`, `BLOCKED`, `UNKNOWN`).
> - **Disruption Probability ($P_{\text{disrupt}}$)**: Time-bounded machine learning output with provenance.
> - **Route Risk ($R_{\text{composite}}$)**: Multi-factor score combining accessibility, predicted weather, terrain slope, fault frequency, and field reports.

---

## 1. High-Level Architecture & Information Flow

```
[DATA SOURCES]  --> Open-Meteo Weather, OSM Corridors, GSI Lithology, Field Reports
       │
       ▼
[ML INFERENCE]  --> Disruption Probability (P_disrupt within 2-hour window)
       │
       ▼
[RISK ENGINE]   --> Deterministic Multi-Factor Segment Risk Score
       │
       ▼
[ROUTING ENGINE]--> OSRM Base Multi-Candidate Path Geometries
       │
       ▼
[OPTIMIZER]     --> Safest Viable vs Fastest Available Route Recommendation
       │
       ▼
[ALERT RADAR]   --> GPS Geofence Proximity Filtering & Active Journey Warnings
       │
       ▼
[LLM ADVISORY]  --> Multilingual Drivers' Warnings (Assamese, Bengali, Hindi, English)
```

> [!CAUTION]
> **Strict Architectural Boundary:** The LLM (Google Gemini API) is restricted strictly to explanation, summarization, and multilingual translation. It **never** calculates risk scores, alters road accessibility states, or selects route recommendations.

---

## 2. Technology Stack

| Tier | Technologies Used | Key Packages & Libraries | Role in TiyraSense |
|---|---|---|---|
| **Mobile App** | Flutter 3.x, Dart 3.x | `flutter_secure_storage`, `geolocator`, `image_picker`, `image`, `flutter_local_notifications`, `http` | Offline-first driver & field-worker client with hardware-backed encryption, GPS telemetry radar, offline incident queueing, and Cloudinary photo evidence. |
| **Web Dashboard** | React 18, TypeScript, Vite | `leaflet`, `lucide-react`, `react-router-dom`, `vitest`, `@testing-library/react` | Command & control operations console for disaster officials and dispatchers with live GIS corridor maps, fleet tracking, and incident verification workbenches. |
| **Backend API** | Python 3.12+, FastAPI, Uvicorn | `SQLAlchemy` (asyncio), `asyncpg`, `GeoAlchemy2`, `Pydantic v2`, `python-jose`, `passlib` (bcrypt), `httpx` | Asynchronous REST gateway, deterministic risk scoring, corridor routing optimizer, multi-source evidence arbitration, and role-based access control. |
| **Machine Learning** | Python 3.12+, scikit-learn | `HistGradientBoostingClassifier`, `CalibratedClassifierCV`, `joblib`, `numpy`, `scipy` | Sub-5ms forward Disruption Probability model trained on 8 physical features with strict anti-leakage temporal splitting (ROC-AUC: 0.8557, PR-AUC: 0.7749). |
| **Spatial Database** | PostgreSQL 16 + PostGIS 3.4 | PostGIS extension, spatial R-Tree indexing, Row Level Security (RLS) | 18 normalized tables managing road segments, dynamic hazard polygons, fleet telemetry breadcrumbs, field reports, and audit logs. |
| **GIS & Routing** | OpenStreetMap, Leaflet, OSRM | OSRM v5.24 HTTP client, EPSG:4326 PostGIS geometry | Free, open-source cartography and routing engine with dynamic risk-penalized alternative route calculation. |
| **Weather Telemetry**| Open-Meteo API | REST API / ECMWF IFS high-resolution model | Automated hourly rainfall, soil moisture, surface pressure, and 2-hour forecasts along North Eastern corridors. |
| **Multilingual AI** | Google Gemini API (Flash 2.0) | `google-genai` Python SDK | Natural-language incident translation and localized driver safety advisories backed by deterministic template fallbacks. |
| **Cloud Storage** | Cloudinary | Direct REST upload integration | Secure media storage and CDN delivery for geotagged field incident photographs. |

---

## 3. Repository Structure

```text
TiyraSense/
├── backend/                          # FastAPI REST services, risk engine, and PostGIS models
│   ├── app/                          # Core application package (api, core, models, schemas, services)
│   ├── migrations/init.sql           # PostGIS schema definition (18 tables, spatial indexes)
│   ├── tests/                        # Backend unit, security, and integration test suite
│   ├── requirements.txt              # Locked Python dependencies
│   └── README.md                     # Backend-specific architecture and developer guide
├── web/                              # React 18 + TypeScript + Vite operations dashboard
│   ├── src/                          # Components, layouts, pages, routes, state, services, types
│   ├── package.json                  # Node dependencies and scripts
│   ├── vite.config.ts                # Vite build and Vitest configuration
│   └── README.md                     # Web console architecture and developer guide
├── mobile/                           # Flutter offline-first mobile application
│   ├── lib/                          # Models, screens, services, state, theme, widgets
│   ├── test/                         # Flutter widget and unit tests
│   ├── pubspec.yaml                  # Mobile dependencies and asset configuration
│   └── README.md                     # Mobile architecture and developer guide
├── ml/                               # Machine Learning disruption prediction pipeline
│   ├── models/                       # Serialized model artifacts (joblib) and metadata (json)
│   ├── dataset.py                    # Anti-leakage temporal dataset generator
│   ├── train.py                      # Model training, probability calibration, and export
│   ├── predict.py                    # Standalone sub-5ms forward inference service
│   ├── requirements.txt              # Locked ML dependencies
│   └── README.md                     # ML pipeline and feature engineering guide
├── docs/                             # Comprehensive system specifications
│   ├── architecture.md               # High-level architecture, pipelines, and security boundaries
│   ├── api_specification.md          # REST API contracts, endpoints, and response envelopes
│   ├── data_model.md                 # 18-table PostGIS spatial schema and entity relationships
│   ├── data_sources_and_pipelines.md # External data ingestion (Open-Meteo, OSM, Cloudinary)
│   ├── ml_specification.md           # Machine learning task, features, and validation protocols
│   ├── risk_and_conflict_resolution.md # Multi-factor risk math and evidence arbitration rules
│   ├── alert_and_emergency.md        # Alert generation, priority levels, and escalation
│   ├── offline_and_sync.md           # Mobile offline queueing, conflict handling, and retry logic
│   ├── user_roles_and_flows.md       # Persona user journeys and RBAC permission matrix
│   ├── testing_strategy.md           # Testing pyramid, verification gates, and CI checks
│   ├── deployment.md                 # Docker Compose local evaluation & production setup
│   └── CLOUDINARY_SETUP_GUIDE.md     # Cloudinary media storage configuration
├── scripts/                          # Seeding, network extraction, and utility tools
│   ├── seed_users.py                 # Seeds test users across Driver, Field, Official, Admin roles
│   └── seed_road_network.py          # Seeds NH-06 & Damra bypass road segments in PostGIS
├── tests/                            # Repository-wide integration and scenario tests
│   └── test_e2e_demo_scenario.py     # Continuous 20-step canonical demonstration scenario test
├── AGENTS.md                         # Mandatory rules of engagement for developers and AI agents
├── BUILD_GUIDE.md                    # 11-phase development roadmap and exit criteria
├── DECISIONS.md                      # Architectural decision records (D-001 through D-018)
├── PROJECT_CONTEXT.md                # Permanent product knowledge and operating principles
├── SECURITY.md                       # Security policies, RBAC gates, and vulnerability checklist
├── SESSION.md                        # Active session state and verified handoff history
├── LOG.md                            # Forensic chronological development log
├── TODO.md                           # Master phase status board (all 11 phases COMPLETE)
├── FIRST_SESSION.md                  # Protocol for starting a new developer session
├── CONTINUE_SESSION.md               # Protocol for resuming existing development
├── TiyraSense_MASTER_AGENT_PROMPT.md # AI orchestration instructions
└── docker-compose.yml                # Multi-container orchestration (DB, Backend, Web)
```

---

## 4. Current Status: 100% Complete Across All 11 Phases

| Phase | Title | Focus Area | Status |
|:---:|---|---|:---:|
| **Phase 0** | Repository & Coordination Setup | Git hygiene, documentation authority, baseline configuration | **COMPLETE** |
| **Phase 1** | Specification Completion | Authoring all 12 architectural, data, and API specifications in `docs/` | **COMPLETE** |
| **Phase 2** | Minimum Viable Backend & Auth | Database-authoritative RBAC, bcrypt auth, PostGIS connectivity | **COMPLETE** |
| **Phase 3** | Core Logistics UX & Routing | OSRM integration, multi-candidate routes, Safest vs Fastest comparison | **COMPLETE** |
| **Phase 4** | GIS Integration & Interactive Map | Leaflet/OSM vector map, corridor overlays, live vehicle telemetry radar | **COMPLETE** |
| **Phase 5** | Real Data Ingestion & Monitoring | Open-Meteo weather polling, soil moisture tracking, incident ingestion | **COMPLETE** |
| **Phase 6** | Risk Engine v0 & Calibration | Multi-factor road risk formula, terrain gradient weights, fault frequency | **COMPLETE** |
| **Phase 7** | Field Reporting & Ingestion | Mobile photo capture, Cloudinary upload, official verification workbench | **COMPLETE** |
| **Phase 8** | Validated Machine Learning | Calibrated `HistGradientBoostingClassifier` ($P_{\text{disrupt}}$, ROC-AUC: 0.8557) | **COMPLETE** |
| **Phase 9** | Dynamic Alerting Engine | Geofenced proximity alerts, emergency push notifications, route rerouting | **COMPLETE** |
| **Phase 10** | Emergency Mode & Offline Sync | Mobile offline incident queue, encrypted session storage, cold-start resilience | **COMPLETE** |
| **Phase 11** | Full Platform Integration | 20-step continuous scenario test (`test_e2e_demo_scenario.py`), hardening | **COMPLETE** |

---

## 5. Quickstart & Execution Guide

### 5.1 Start the PostGIS Spatial Database
```bash
docker compose up db -d
```

### 5.2 Initialize and Run the Backend API
```bash
# Setup Python virtual environment
python -m venv .venv
.venv\Scripts\Activate.ps1    # On Windows
source .venv/bin/activate      # On Linux/macOS

# Install dependencies and seed initial data
pip install -r backend/requirements.txt
python scripts/seed_users.py
python scripts/seed_road_network.py

# Start FastAPI server
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive Swagger docs: `http://localhost:8000/docs`.

### 5.3 Run the React Operations Console
```bash
cd web
npm install
npm run dev
```
Access dashboard at `http://localhost:5173`.

### 5.4 Run the Flutter Mobile Application
```bash
cd mobile
flutter pub get
flutter run -d chrome     # Or -d windows, or connected mobile device
```

---

## 6. Comprehensive Test Suites

The entire platform is protected by strict automated test suites across all tiers:

```bash
# 1. Backend, Security, ML & E2E Scenario Tests (49 tests, 100% pass)
python -m pytest backend/tests tests/test_e2e_demo_scenario.py -v

# 2. Web Frontend Component & Integration Tests (26 tests, 100% pass)
cd web && npm test

# 3. Web Production Build Verification (Clean build, 0 errors)
cd web && npm run build

# 4. Mobile Widget & Unit Tests (54 tests, 100% pass)
cd mobile && flutter test

# 5. Mobile Static Analysis (0 errors, 0 warnings, 0 hints)
cd mobile && flutter analyze
```

---

## 7. Documentation Index

- **Core Working Agreements**:
  - [AGENTS.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/AGENTS.md) — Mandatory agent rules, document authority hierarchy, code quality standards
  - [SECURITY.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/SECURITY.md) — Root security policies, RBAC rules, vulnerability checklist
  - [DECISIONS.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/DECISIONS.md) — Architectural decision records (D-001 through D-018)
  - [PROJECT_CONTEXT.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/PROJECT_CONTEXT.md) — Permanent product context, core promise, user personas
  - [BUILD_GUIDE.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/BUILD_GUIDE.md) — Phased development sequence and exit conditions
- **Module Technical Guides**:
  - [backend/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/README.md) — FastAPI services, risk engine, database models, and API map
  - [web/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/web/README.md) — React dashboard, Leaflet GIS mapping, and verification workbench
  - [mobile/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/README.md) — Flutter client, offline storage queue, and GPS telemetry radar
  - [ml/README.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/ml/README.md) — Disruption prediction model, features, and inference engine
- **Detailed Architectural Specifications**:
  - [docs/architecture.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/architecture.md) — Topology, module boundaries, external integrations
  - [docs/api_specification.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/api_specification.md) — Comprehensive REST API documentation
  - [docs/data_model.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/data_model.md) — 18-table PostGIS spatial schema
  - [docs/data_sources_and_pipelines.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/data_sources_and_pipelines.md) — External data integration specifications
  - [docs/ml_specification.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/ml_specification.md) — Machine learning model design & validation
  - [docs/risk_and_conflict_resolution.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/risk_and_conflict_resolution.md) — Risk math & evidence arbitration
  - [docs/alert_and_emergency.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/alert_and_emergency.md) — Alert dispatch & emergency mode protocols
  - [docs/offline_and_sync.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/offline_and_sync.md) — Offline caching and synchronization protocols
  - [docs/user_roles_and_flows.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/user_roles_and_flows.md) — User personas and interaction workflows
  - [docs/testing_strategy.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/testing_strategy.md) — Testing pyramid and QA verification gates
  - [docs/deployment.md](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/docs/deployment.md) — Local evaluation and production deployment
