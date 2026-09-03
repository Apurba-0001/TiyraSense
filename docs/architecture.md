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
|   |  - SQLite (Offline Cache & Sync Queue)|   |  - TypeScript + Tailwind CSS  |   |
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
- **Tech:** Flutter 3.x, Dart 3.x.
- **Components:**
  - `presentation/`: Navigation views, route comparison cards, hazard warning modals, field report forms.
  - `offline/`: SQLite database managing local route caches, map tile caches (`flutter_map_cache`), and pending report queue.
  - `services/`: Geolocation GPS provider, background sync daemon.

### 3.2 `web/` — React Operator Dashboard
- **Tech:** React 18+, TypeScript, MapLibre GL JS, Vite.
- **Components:**
  - `map/`: Interactive vector map rendering road corridors, live segment risk color-coding, active fleet locations, incident pins.
  - `dashboard/`: KPI counters (active journeys, impassable segments, weather warnings).
  - `reports/`: Official verification workbench for field incident reports.

### 3.3 `backend/` — Python Core Services
- **Tech:** Python 3.11+, FastAPI, SQLAlchemy 2.0 (asyncio), GeoAlchemy2, Pydantic v2.
- **Sub-packages:**
  - `api/`: REST route controllers (`/routes`, `/journeys`, `/reports`, `/alerts`, `/auth`).
  - `services/risk_engine.py`: Deterministic multi-factor road risk calculation.
  - `services/routing_service.py`: Interface to OSRM and PostGIS spatial graph evaluation.
  - `services/conflict_resolver.py`: Evidence arbitration and status update logic.
  - `services/explanation_service.py`: Gemini API client with fallback templates.
  - `workers/weather_ingestion.py`: Scheduled polling of Open-Meteo API.

### 3.4 `ml/` — Disruption Prediction
- **Tech:** Python, scikit-learn, XGBoost, pandas.
- **Function:** Trains, evaluates, and exports the 2-hour forward Disruption Probability model based on rainfall, gradient, historical cuts, and weather forecasts.
- **Artifact:** Model weights and serialized pipelines loaded read-only by the backend.

### 3.5 `scripts/` — Tooling & Initialization
- Seed scripts to load OSM road segments for the Guwahati–Shillong pilot corridor into PostGIS.
- Synthetic event generator to simulate cloudbursts, mudslides, and fleet journeys for testing.

### 3.6 `tests/` — Verification Suite
- Integration tests verifying end-to-end routing, conflict resolution, RBAC, and offline sync payloads.

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
