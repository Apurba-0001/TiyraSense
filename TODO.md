# TODO.md — TiyraSense Project Status

Status terms: **COMPLETE**, **PARTIALLY COMPLETE**, **BLOCKED**, **NOT STARTED**. This is the current work board, not a historical log.

## Phase 0 — Repository & Coordination Setup — COMPLETE

- [x] COMPLETE — Root coordination/documentation files and Git hygiene templates
- [x] COMPLETE — Empty, module-owned directory skeleton: `mobile/`, `web/`, `backend/`, `ml/`, `docs/`, `scripts/`, `tests/`

## Phase 1 — Specification Completion — COMPLETE

- [x] COMPLETE — Requirements, product, roles/flows, architecture, data/database, API, source/pipeline, GIS/routing, risk/conflict, alert/emergency, ML, offline/mobile/web, testing, and deployment specifications (all 12 comprehensive specs authored under `docs/`)
- [x] COMPLETE — Researched, verified, and recorded map/GIS (OSM/MapLibre/flutter_map), routing (OSRM/PostGIS), weather (Open-Meteo/IMD), hosting (Docker PostGIS), risk-formula (multi-factor weights), and LLM-provider (Gemini free tier) decisions in `DECISIONS.md` (D-010 through D-015)

## Phase 2 — Environment Validation — COMPLETE

- [x] COMPLETE — Selection-sprint prerequisites: Git, Docker, Docker-based PostgreSQL/PostGIS, Flutter/Dart, Python/venv/pip, and Node/npm/React-TypeScript verified with disposable checks
- [x] COMPLETE — Validate the ML toolchain: `scikit-learn`, `joblib`, `numpy`, `scipy` installed, verified, and passing tests in `backend/tests/test_ml.py`

## Phase 3 — Thin End-to-End Slice & Security Hardening — COMPLETE

- [x] COMPLETE — Authenticated Flutter login → Python FastAPI backend → PostGIS database → response, with server-side RBAC (Driver, Field Worker, Official, Admin) and 10 passing widget tests.
- [x] COMPLETE — React 18 + TypeScript + Vite web operations console & admin governance shell with RoleGuard and 5 passing Vitest tests.
- [x] COMPLETE — FastAPI backend (`app/main.py`) with asyncpg connection pool, bcrypt, JWT auth, healthcheck, and 23 passing pytest tests.
- [x] COMPLETE — Initial user accounts seeded for all 4 roles in live PostgreSQL/PostGIS database via `scripts/seed_users.py`.
- [x] COMPLETE — Security Hardening: Registration role restriction (`RegistrationRole` accepts only DRIVER and FIELD_WORKER; rejects OFFICIAL/ADMIN with 422), DB-authoritative RBAC, SQL/null-byte/control-char defenses, and HTTP security response headers (`CSP`, `nosniff`, `X-Frame-Options: DENY`).
- [x] COMPLETE — Persistent Mobile Authentication: Hardware-encrypted storage via `flutter_secure_storage` (Android Keystore / iOS Keychain) preserving session across app restarts and offline cold boots.

## Phase 4 — Core Logistics UX (Dynamic Route Planning, Spatial Risk & Live Telemetry) — COMPLETE

- [x] COMPLETE — Arbitrary & Dynamic Origin & Destination Hub selection with GPS lookup and custom coordinate inputs across NER
- [x] COMPLETE — OSRM routing engine candidate evaluation (`/api/v1/routes/evaluate` and `/api/v1/routes/corridors`)
- [x] COMPLETE — Multi-factor candidate route risk scoring: Safest Viable vs Fastest Available (D-015 formula & PostGIS ST_DWithin spatial matching)
- [x] COMPLETE — Dynamic road corridor status, geometry seeding (`scripts/seed_road_network.py` with 14 segments in PostGIS)
- [x] COMPLETE — Live Location Tracking & Telemetry Engine (`/api/v1/journeys`, `/api/v1/journeys/{id}/telemetry`, `/api/v1/journeys/{id}/tracking`, `/api/v1/journeys/active`) with forward hazard warning lookahead
- [x] COMPLETE — Web and Mobile integrations with dynamic route evaluations and live telemetry streaming (all 32 backend tests, 9 web tests, 22 mobile tests passing)

## Phase 5 — Real-World Data Ingestion & Universal Map Layering — COMPLETE

- [x] COMPLETE — Live Supabase Cloud PostgreSQL PostgREST queries for corridors, alerts, field reports, and active telemetry
- [x] COMPLETE — Google Maps styled Map Layer Switcher (Satellite, Road/Default, Terrain) + details toggles (Alerts, Incidents) across all maps in Mobile and Web
- [x] COMPLETE — Real-time atmospheric telemetry ingestion pipeline via Open-Meteo API covering 8 primary North Eastern Region hubs with dynamic weather penalties, backend `/api/v1/external/weather` endpoints, and live web dashboard telemetry ribbon
- [x] COMPLETE — Vehicle Dashboard Naming & Complete GIS Map Zoom Isolation (replaces raw UUIDs with vehicle model, number, and genuine driver identities across unit selector, marker pins, HUD badges, and route focus buttons; isolates GIS map wheel and pinch zoom from website window)

## Phase 6 — Rule-Based Risk Engine v0 — COMPLETE

- [x] COMPLETE — Documented, tested deterministic Risk Engine in `backend/app/services/risk_engine.py` implementing Decision D-015 multi-factor weights ($W_r=0.35, W_s=0.25, W_h=0.15, W_o=0.25$), critical state override ($R=1.0$), and composite route risk blending 70% distance-weighted average + 30% bottleneck peak.

## Phase 7 — Field Reporting & Evidence Sync Pipeline — COMPLETE

- [x] COMPLETE — Real-world photographic evidence streaming from mobile phones directly to server storage / Cloudinary with offline queue synchronization (`uploadEvidencePhoto`, `createFieldReport`, `syncPendingData`)
- [x] COMPLETE — Multi-user web dashboard live reflection of field evidence photos in `/reports` and `/dashboard` operations queue with full-screen high-resolution lightbox inspection and geo-verification badges
- [x] COMPLETE — Automated incident alert generation and PostGIS route risk recalculation upon official report verification

## Phase 8 — Disruption Prediction (ML) — COMPLETE

- [x] COMPLETE — Anti-leakage temporal dataset generator in `ml/dataset.py` covering primary hill corridors (NH-06, NH-27, NH-10) with 8 canonical features.
- [x] COMPLETE — Calibrated `HistGradientBoostingClassifier` trained on historical monsoon data and evaluated on held-out peak monsoon test set in `ml/train.py` (ROC-AUC: 0.856, PR-AUC: 0.775) with model artifact `ml/models/disruption_v1.0.joblib` and metadata `disruption_v1.0.json`.
- [x] COMPLETE — Standalone high-efficiency disruption inference service in `ml/predict.py` with strict model provenance (`model_version="xgb-disruption-v1.0.0"`) and physics fallback.
- [x] COMPLETE — Unit and regression test suite passing in `backend/tests/test_ml.py`.

## Phase 9 — Risk-Aware Routing + Alerts + Emergency Mode — COMPLETE

- [x] COMPLETE — Dynamic virtual hazard segment injection into OSRM route bounding boxes (`backend/app/services/routing_service.py`), elevating risk scores and flagging `BLOCKED`/`HIGH_RISK` states upon verified incidents.
- [x] COMPLETE — Automated incident alert generation and push upon official report verification (`backend/app/api/v1/endpoints/field_reports.py`).
- [x] COMPLETE — Web Alert Feed with auto-polling (`web/src/pages/AlertFeed.tsx`) and emergency route warning banners in journey planning (`web/src/components/JourneyPlanningModal.tsx`).
- [x] COMPLETE — Mobile alert read state persistence, unread badge indicators, and push notifications restricted to genuine emergencies (`mobile/lib/services/alert_service.dart`).

## Phase 10 — Vehicle Tracking, Dashboard + Offline Hardening — COMPLETE

- [x] COMPLETE — Operational dashboard (`web/src/pages/Dashboard.tsx`) with real Web Mercator GIS Map (`web/src/components/VectorGisMap.tsx`), focused route tracking vs all fleet locations mode, interactive vehicle telemetry inspector, and multi-aspect filters.
- [x] COMPLETE — Real-time GPS telemetry radar ingestion, dynamic distance-to-destination, and forward hazard lookahead (`backend/app/services/telemetry_service.py`).
- [x] COMPLETE — Mobile offline report queuing with `PENDING` state in hardware-encrypted storage and auto-sync on reconnect (`mobile/lib/services/offline_storage_service.dart`).
- [x] COMPLETE — Physical mobile device USB ADB reverse & Wi-Fi LAN host configuration with encrypted persistence, live connection probe modal (`mobile/lib/widgets/server_connection_dialog.dart`), and end-to-end evidence photo persistence to PostgreSQL/Supabase across app reinstalls and web dashboard display.

## Phase 11 — End-to-End Testing + Demo Polish — COMPLETE

- [x] COMPLETE — Automated 20-step continuous selection demonstration scenario test in `tests/test_e2e_demo_scenario.py` verifying full cross-stack workflow from driver login to route planning, telemetry, incident submission, verification, auto-alerting, and dynamic rerouting.
- [x] COMPLETE — All test suites green: 48 backend tests (including ML and E2E), 26 web tests, 54 mobile tests passing with 0 compiler or linter errors.

## Status evidence rule

Statuses in this file must reflect the repository as verified in the current session. Do not mark work complete from documentation, compilation, or UI appearance alone. Record the verification evidence in `SESSION.md` and `LOG.md`; use `BLOCKED` when an open decision or dependency genuinely prevents the next task.

## Current blockers for later phases
 
- **Blockers:** None. All architectural decisions D-010 through D-018 are FINALIZED in `DECISIONS.md`.
- **Immediate Next Task:** End-to-end rehearsal of the selection demonstration and live staging deployment packaging.
