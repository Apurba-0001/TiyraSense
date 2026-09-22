# System Architecture Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Authoritative Architectural Rules:** Defined in `AGENTS.md` and `SECURITY.md`

---

## 1. High-Level Architecture Topology

TiyraSense employs a decoupled, service-oriented architecture designed to operate resiliently across severe network constraints in the North Eastern Region.

```
+-----------------------------------------------------------------------------------+
|                                 CLIENT TIER                                       |
|                                                                                   |
|   +---------------------------------------+   +-------------------------------+   |
|   |         Flutter Mobile App            |   |       React Web Dashboard     |   |
|   |   (Driver & Field Worker Modes)       |   |    (Dispatcher & Official)    |   |
|   |  - flutter_map (OpenStreetMap)        |   |  - MapLibre GL JS             |   |
|   |  - SQLite (Offline Cache & Sync Queue)|   |  - TypeScript + Vanilla CSS   |   |
|   |  - Location & Camera Services         |   |  - Real-time Alert Monitor    |   |
|   +---------------------------------------+   +-------------------------------+   |
+---------------------------------------+-------------------------------------------+
                                        | HTTPS / WSS
+---------------------------------------v-------------------------------------------+
|                          API & ORCHESTRATION TIER                                 |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |                           FastAPI Gateway                                 |   |
|   |   - JWT Authentication & RBAC Verification                                |   |
|   |   - Pydantic Input/Output Schema Enforcement                              |   |
|   |   - Rate Limiting & Payload Size Protection                               |   |
|   +-------+--------------------+-------------------+--------------------+-----+   |
|           |                    |                   |                    |         |
|   +-------v--------+   +-------v-------+   +-------v--------+   +-------v-----+   |
|   | Ingestion &    |   | Risk Engine   |   | Routing & Alt  |   | Alert &     |   |
|   | Evidence Sync  |   | (Multi-Factor)|   | Path Optimizer |   | Notification|   |
|   +----------------+   +---------------+   +----------------+   +-------------+   |
|                                                                 | Multilingual|   |
|                                                                 | Advisory Gen|   |
|                                                                 +------+------+   |
+------------------------------------------------------------------------|----------+
                                                                         |
+------------------------------------------------------------------------v----------+
|                            PERSISTENCE & SPATIAL TIER                             |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |                  PostgreSQL 16 + PostGIS 3.4 Spatial Database             |   |
|   |   - road_segments (LineString, spatial R-Tree index, terrain slope)       |   |
|   |   - weather_observations, field_reports, active_incidents                 |   |
|   |   - journeys, routes, targeted_alerts, audit_logs                         |   |
|   +---------------------------------------------------------------------------+   |
+-----------------------------------------------------------------------------------+
```

---

## 2. Critical Architectural Separation

To prevent model hallucinations from endangering lives, TiyraSense enforces a strict unidirectional pipeline. **No downstream component may feed untrusted conclusions back into an upstream safety layer.**

```
[DATA INGESTION]  --> What physical information exists? (Weather, OSM roads, Field reports)
       |
       v
[ML INFERENCE]    --> What is likely to occur? (Probability of disruption within 2 hours)
       |
       v
[RISK ENGINE]     --> How hazardous is the road segment? (Deterministic multi-factor risk score)
       |
       v
[ROUTING ENGINE]  --> Which physical paths connect origin to destination? (OSRM geometries)
       |
       v
[OPTIMIZATION]    --> Which viable path minimizes hazard risk? (Safest vs Fastest evaluation)
       |
       v
[ALERT ENGINE]    --> Who is currently on or heading towards affected segments? (Geofence filter)
       |
       v
[LLM ADVISORY]    --> How should the advisory be phrased for the driver? (Assamese, Hindi, etc.)
```

### Invariable Rule:
> **The LLM never calculates risk scores, never determines road accessibility states, and never chooses route recommendations.** It receives finalized structured data and translates/summarizes it for human consumption.

---

## 3. Module Boundaries & Responsibilities

### 3.1 `mobile/` — Flutter Client
- **Tech:** Flutter 3.x, Dart 3.x, Riverpod / ChangeNotifier state, `flutter_secure_storage`, `geolocator`, `image_picker`, `image`, `flutter_local_notifications`.
- **Components:**
  - `screens/`: Role-tailored dashboards (`driver_home_screen.dart`, `field_worker_home_screen.dart`), GIS navigation maps (`driver_map_screen.dart`), and auth/history views.
  - `widgets/`: Dynamic hazard report sheets, journey evaluator sheets, slippy tile layers, live notification cards.
  - `services/`: `offline_storage_service.dart` (local report queue & sync), `location_service.dart` (GPS telemetry), `report_service.dart` (Cloudinary photo upload), `alert_service.dart` (audible notifications).

### 3.2 `web/` — React Operator Dashboard
- **Tech:** React 18, TypeScript, Vite, Leaflet, Lucide React, React Router v7.
- **Components:**
  - `pages/`: Command center (`Dashboard.tsx`), corridor risk monitoring (`CorridorMonitor.tsx`), official incident verification workbench (`FieldReports.tsx`), active alert broadcasts (`AlertFeed.tsx`), administrative governance (`UserManagement.tsx`, `SystemSettings.tsx`).
  - `components/`: Leaflet vector GIS map (`VectorGisMap.tsx`), journey evaluator modal (`JourneyPlanningModal.tsx`), status badges, header, and collapsible sidebar.
  - `routes/RoleGuard.tsx`: Client-side RBAC gate enforcing `OFFICIAL` and `ADMIN` access.

### 3.3 `backend/` — Python Core Services
- **Tech:** Python 3.12+, FastAPI, Uvicorn, SQLAlchemy 2.0 (asyncio) + asyncpg, GeoAlchemy2, Pydantic v2, python-jose (JWT), passlib (bcrypt), httpx.
- **Sub-packages:**
  - `app/api/v1/endpoints/`: REST endpoints (`health.py`, `auth.py`, `routes.py`, `journeys.py`, `field_reports.py`, `alerts.py`, `evidence.py`, `external.py`).
  - `app/services/`: Deterministic multi-factor risk engine (`risk_engine.py`), OSRM corridor route optimizer (`routing_service.py`), multi-source evidence conflict resolver (`conflict_resolver.py`), Google Gemini multilingual advisory generator (`explanation_service.py`), GPS telemetry radar (`radar_service.py`).
  - `app/models/` & `app/schemas/`: Declarative PostGIS models (18 tables) and strict Pydantic v2 schemas.

### 3.4 `ml/` — Disruption Prediction
- **Tech:** Python 3.12+, scikit-learn (`HistGradientBoostingClassifier`, `CalibratedClassifierCV`), joblib, numpy, scipy.
- **Components:**
  - `dataset.py`: Anti-leakage temporal split dataset generator covering 8 canonical physical and meteorological features across NH-06, NH-27, and NH-10.
  - `train.py`: Model training and probability calibration pipeline (ROC-AUC: 0.8557, PR-AUC: 0.7749).
  - `predict.py`: High-efficiency (<5ms CPU latency) standalone forward inference engine with physics fallback.
  - `models/`: Exported serialized model artifact (`disruption_v1.0.joblib`) and descriptor (`disruption_v1.0.json`).

### 3.5 `scripts/` — Tooling & Initialization
- `seed_users.py`: Seeds initial credentials for Driver, Field Worker, Official, and Admin accounts.
- `seed_road_network.py`: Seeds PostGIS road segments, elevation profiles, and coordinates for NH-06 and the Damra bypass.

### 3.6 `tests/` — Verification Suite
- `tests/test_e2e_demo_scenario.py`: Automated 20-step continuous integration scenario exercising the complete lifecycle from healthcheck to rerouting.
- Module test suites: `backend/tests/` (49 tests), `web/src/test/` (26 tests), `mobile/test/` (54 tests).

---

## 4. External Integrations

| External System | Integration Protocol | Direction | Primary Purpose | Failure Fallback |
|---|---|:---:|---|---|
| **Open-Meteo API** | REST / JSON | Inbound | Hourly precipitation, wind, soil moisture along corridor points | Retain last valid weather observation; decay confidence over 3 hours |
| **OSRM Engine** | HTTP / JSON | Bidirectional | Base road geometries, distances, and free-flow transit durations | Fallback to pre-calculated segment network in PostGIS |
| **Google Gemini API** | HTTPS / SDK | Outbound | Multilingual translation and concise warning advisories | Deterministic string templates in English and Hindi |
| **OpenStreetMap** | Standard Raster Tiles | Inbound | Background map cartography for mobile and web viewers | Cached tiles in SQLite / local vector fallback |

---

## 5. Security & Trust Boundaries

1. **Untrusted Boundary (Mobile/Client):** All device inputs (coordinates, incident types, timestamps, user identifiers) are treated as untrusted. Timestamps are bounded against server clock drift; coordinates are validated against PostGIS corridor bounding boxes.
2. **Database Boundary:** Direct database access is restricted to the backend service role. All queries utilize parameterized ORM statements or typed query builders.
3. **LLM Boundary:** Prompt templates strictly enclose external text within explicit delimiters and validate model output against Pydantic models.
