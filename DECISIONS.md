# DECISIONS.md — TiyraSense

This is the reasoning trail for durable project choices, not a status log. Newest records appear first. No provider is selected unless its record says **FINALIZED**.

# Template

Use this for each durable decision:

**Date:**  
**Decision:**  
**Why:**  
**Evidence/source checked:** official documentation, tests, benchmarks, operational evidence, or other supporting basis; include version/release date where relevant  
**Alternatives considered / ruled out:**  
**Impact / affected files or contracts:**  
**Status:** `FINALIZED` or `OPEN`

## Decision hygiene

A decision record is for a durable architectural, security, product, provider, or operational choice. Do not use it as a scratchpad for routine implementation details.

For decisions involving a library, SDK, API, provider, model, platform, or deployment service:
1. Verify current official documentation and compatibility before finalizing.
2. Record the relevant version/release date and the evidence used.
3. Record meaningful alternatives and why they were rejected.
4. Update the affected specification and implementation after finalization.
5. If evidence is insufficient, keep the decision `OPEN` rather than guessing.

A decision marked `OPEN` is not permission to implement. A decision becomes binding only when its record says `FINALIZED`.

## Established decisions

### D-017 — OS-level encrypted mobile session persistence and offline-first launch resilience

- **Decision:** Replace plaintext SharedPreferences with `flutter_secure_storage` (backed by Android Keystore AES-GCM, iOS Keychain, and Windows DPAPI) for persisting the JWT authentication token and cached `UserModel` profile. On app cold starts, credentials are automatically restored before rendering the first frame, routing authenticated users directly to their role-specific home console without showing the login screen. Furthermore, transient network failures or offline starts in remote North Eastern Region (NER) valleys do NOT clear the session; local credentials are only wiped upon an explicit user "Sign Out" tap or an authoritative HTTP 401/403 status code from the server.
- **Why:** Plaintext local storage leaks sensitive JWTs. Drivers operating in dead zones with zero cellular connectivity would be locked out if network validation errors wiped their login state on app restart.
- **Evidence/source checked:** `flutter_secure_storage` v11 API specifications (Android Keystore AES-GCM by default); OWASP Mobile Top 10 (M1: Improper Platform Usage, M2: Insecure Data Storage).
- **Alternatives considered / ruled out:** `shared_preferences` (rejected: unencrypted plaintext XML/JSON on disk); online-only authentication check on every boot (rejected: fails SIH offline-first requirement for NER connectivity).
- **Impact / affected files or contracts:** `mobile/lib/state/auth_provider.dart`, `mobile/lib/main.dart`, `mobile/pubspec.yaml`, `docs/offline_and_sync.md`.
- **Status:** FINALIZED.

### D-016 — Self-service registration role restriction and DB-authoritative RBAC

- **Decision:** Restrict public self-service user registration (`POST /api/v1/auth/register`) exclusively to `DRIVER` and `FIELD_WORKER` roles via a dedicated `RegistrationRole` schema enum. Requests attempting to self-register as `OFFICIAL` or `ADMIN` are rejected at the Pydantic schema validation layer with HTTP 422 before any database queries execute. Government Official and System Administrator accounts can only be provisioned manually in the database by a database administrator. Furthermore, all role checks at API dependencies query the database row directly rather than trusting the JWT role claim.
- **Why:** Prevents self-elevation of privilege, unauthorized dashboard surveillance, and illicit road closure overrides. Eliminates token forgery vectors where a compromised secret key could be used to manufacture administrative JWT claims.
- **Evidence/source checked:** OWASP API Security Top 10 (API1: Broken Object Level Authorization, API5: Broken Function Level Authorization); FastAPI Pydantic v2 validation contracts.
- **Alternatives considered / ruled out:** Trusting JWT `role` claims for authorization (ruled out: stale claims or forged tokens could escalate privileges); open registration with approval flags (ruled out: adds unneeded complexity for selection sprint).
- **Impact / affected files or contracts:** `backend/app/schemas/auth.py`, `backend/app/api/deps.py`, `backend/app/api/v1/endpoints/auth.py`, `docs/user_roles_and_flows.md`, `docs/api_specification.md`.
- **Status:** FINALIZED.

### D-015 — Prototype route-risk formula and multi-factor weights

- **Decision:** Use an interpretable multi-factor risk scoring model over discrete road segments combining (1) dynamic rainfall intensity ($W_r$), (2) terrain slope and landslide susceptibility index ($W_s$), (3) historical incident frequency ($W_h$), and (4) verified active field obstruction severity ($W_o$), evaluated separately from operational accessibility state and ML disruption probability.
- **Why:** Ensures full traceability, auditable risk calculations, and deterministic fail-safe behavior without reliance on opaque black-box models for safety-critical route penalization.
- **Evidence/source checked:** NDMA National Landslide Risk Management Strategy; Indian Road Congress (IRC:SP:48) Hill Road Manual; IMD rainfall classification thresholds.
- **Alternatives considered / ruled out:** Pure black-box neural risk prediction (ruled out due to lack of explainability); static pre-configured hazard maps (ruled out due to dynamic monsoon variations).
- **Impact / affected files or contracts:** `docs/risk_and_conflict_resolution.md`, `backend/services/risk_engine.py`.
- **Status:** FINALIZED for prototype and selection sprint.

### D-014 — Local containerized runtime with Docker Compose and PostGIS

- **Decision:** Deploy local development and evaluation environment via Docker Compose running PostgreSQL 16 + PostGIS 3.4, FastAPI backend, and React web dashboard.
- **Why:** 100% free, reproducible across development workstations, zero ongoing cloud expenses, and functions completely offline during in-person SIH evaluation sessions.
- **Evidence/source checked:** Official Docker `postgis/postgis:16-3.4` container specifications; PostGIS 3.4 spatial indexing performance benchmarks.
- **Alternatives considered / ruled out:** Cloud-only managed databases (AWS RDS, Neon, Google Cloud SQL) ruled out as primary runtime due to costs and network vulnerability during in-person demonstrations.
- **Impact / affected files or contracts:** `docker-compose.yml`, `docs/deployment.md`, `.env.example`.
- **Status:** FINALIZED for local development and selection sprint.

### D-013 — Google Gemini API for multilingual advisory generation

- **Decision:** Utilize Google Gemini API (Gemini 2.0 / 1.5 Flash free tier) exclusively for natural-language incident summaries, multilingual safety advisories (Assamese, Bengali, Hindi, English), and operator queries, backed by deterministic template fallbacks.
- **Why:** High free tier allowance (15 RPM, 1,500 RPD), strong Indic language translation quality, sub-second latency, structured JSON response mode. Strictly isolated from safety-critical routing per D-007.
- **Evidence/source checked:** Google AI Studio free tier limits; Gemini 1.5 Flash latency and language benchmark documentation.
- **Alternatives considered / ruled out:** OpenAI API (no free ongoing tier); local LLM via Ollama (excessive memory footprint for standard laptops, though clean interface permits future offline plug-in).
- **Impact / affected files or contracts:** `docs/architecture.md`, `docs/api_specification.md`, `backend/services/explanation_service.py`.
- **Status:** FINALIZED for non-safety-critical text generation.

### D-012 — Open-Meteo API and IMD bulletins for weather intelligence

- **Decision:** Integrate Open-Meteo API as primary automated quantitative weather provider (hourly rain, surface pressure, soil moisture, 16-day forecast, historical archive) complemented by official IMD district alert bulletins for corroborated warnings.
- **Why:** 100% free for open-source and educational use, requires no API keys, high-resolution ECMWF/GFS numerical weather model coverage over Northeast India topography.
- **Evidence/source checked:** Open-Meteo API documentation (open-meteo.com); ECMWF IFS terrain resolution benchmarks; IMD Mausam regional bulletin specifications.
- **Alternatives considered / ruled out:** OpenWeatherMap (free tier restricted, credit card required for modern endpoint); Tomorrow.io (commercial limits).
- **Impact / affected files or contracts:** `docs/data_sources_and_pipelines.md`, `backend/workers/weather_ingestion.py`.
- **Status:** FINALIZED.

### D-011 — OSRM baseline with PostGIS / pgRouting segment penalization

- **Decision:** Utilize OSRM (Open Source Routing Machine) for baseline four-wheeler route geometry and distance/time estimation, coupled with a PostGIS / pgRouting segment network graph for dynamic risk-penalized alternative route optimization.
- **Why:** OSRM is free, open-source, and blisteringly fast for base navigation geometries. Combining it with PostGIS segment weights enables TiyraSense to apply dynamic safety penalties to high-risk road corridors without commercial map API costs.
- **Evidence/source checked:** Project OSRM API v1 specification; pgRouting 3.6 manual (`pgr_dijkstra`, `pgr_ksp`); Geofabrik OpenStreetMap North-East India PBF extracts.
- **Alternatives considered / ruled out:** Google Directions / Mapbox Directions APIs (expensive, API keys required, terms forbid server-side edge extraction and offline route caching).
- **Impact / affected files or contracts:** `docs/architecture.md`, `docs/api_specification.md`, `backend/services/routing_service.py`.
- **Status:** FINALIZED.

### D-010 — OpenStreetMap, MapLibre GL JS, and flutter_map for GIS stack

- **Decision:** Adopt OpenStreetMap (OSM) data and standard raster/vector tiles, using MapLibre GL JS for the web intelligence dashboard and flutter_map with SQLite cache for the offline-first mobile application.
- **Why:** 100% open-source, zero API licensing costs, compliant with local development, complete tile-caching freedom in connectivity-deprived NER hill tracts without proprietary vendor lock-in.
- **Evidence/source checked:** OpenStreetMap Foundation Tile Usage Policy; MapLibre GL JS v4 API; flutter_map and `flutter_map_cache` offline storage benchmarks.
- **Alternatives considered / ruled out:** Google Maps SDK (strict caching prohibitions, commercial costs, cannot function truly offline for field workers); Mapbox GL (proprietary access token required).
- **Impact / affected files or contracts:** `web/`, `mobile/`, `docs/architecture.md`, `docs/offline_and_sync.md`.
- **Status:** FINALIZED.

### D-009 — Offline-first mobile operation

- **Decision:** Driver and Field Worker mobile capabilities are offline-first, retaining queued reports and relevant journey data with timestamps.
- **Why:** NER travel includes intermittent/weak connectivity; incident reporting and safety information must degrade safely.
- **Alternatives considered / ruled out:** Online-only mobile operation is unsuitable for the operating environment.
- **Status:** FINALIZED. (Implemented via `flutter_secure_storage` and `OfflineStorageService` per D-017).

### D-008 — Road-segment-centric intelligence

- **Decision:** Geographic intelligence is organised around road segments and time, so observations, predictions, risk, routing, and alerts share traceable geographic units.
- **Why:** This supports consistent evidence mapping, prediction, route assessment, and operational views.
- **Alternatives considered / ruled out:** Isolated, route-only or report-only intelligence would lose reuse and traceability across the platform.
- **Status:** FINALIZED. (18-table PostGIS spatial schema specified in `docs/data_model.md` and implemented in `backend/migrations/init.sql`).

### D-007 — LLM excluded from safety-critical routing decisions

- **Decision:** LLM components are limited to explanation, summarization, multilingual messaging, and natural-language dashboard queries. Deterministic risk, routing, and optimization layers make route recommendations.
- **Why:** LLM output is not reliably calibrated or auditable enough for safety-critical decisions.
- **Alternatives considered / ruled out:** Direct LLM route/accessibility/risk decisions are ruled out.
- **Status:** FINALIZED. (Provider finalized as Google Gemini API per D-013 with strict isolation from safety routing).

### D-006 — Safety-first routing over fastest-route-first

- **Decision:** Recommend the safest viable route while keeping the fastest available route visible.
- **Why:** Reducing disruption risk is the core logistics value proposition; travel time is important but secondary to safety and viability.
- **Alternatives considered / ruled out:** Fastest-route-only recommendation is ruled out.
- **Status:** FINALIZED. (Multi-factor risk weights finalized per D-015 and calibrated in Phase 6).

### D-005 — Three separate risk concepts

- **Decision:** Track and display Current Accessibility, Disruption Probability, and Route Risk separately, each with provenance.
- **Why:** A single blended number hides whether evidence is a current fact, a prediction, or a route-level assessment and damages explainability.
- **Alternatives considered / ruled out:** A single opaque "risk score" is ruled out.
- **Status:** FINALIZED. (Formulas and thresholds finalized per D-015 and verified in Phase 6 & Phase 8).

### D-004 — Four-wheelers as the initial vehicle baseline

- **Decision:** MVP routing and risk logic targets four-wheelers while retaining an extensible design for later vehicle-specific support.
- **Why:** It keeps MVP scope achievable without foreclosing future expansion.
- **Alternatives considered / ruled out:** Implementing all vehicle categories in the first MVP is deferred.
- **Status:** FINALIZED MVP scope.

### D-003 — Existing routing engine

- **Decision:** Integrate an established routing engine rather than building global navigation from scratch.
- **Why:** TiyraSense adds safety/risk intelligence over routing; it should not reimplement commodity route computation.
- **Alternatives considered / ruled out:** A custom navigation engine is ruled out for the MVP.
- **Status:** FINALIZED. (Engine finalized as OSRM with PostGIS segment penalization per D-011).

### D-002 — Core technology direction

- **Decision:** Use Flutter for mobile, React + TypeScript for web, Python for backend, and PostgreSQL + PostGIS as the primary database.
- **Why:** This matches the required product clients, geospatial needs, team direction, and free-first strategy.
- **Alternatives considered / ruled out:** Exact framework/provider substitutions are not selected by this decision and must not be assumed.
- **Status:** FINALIZED stack direction.

### D-001 — Project identity

- **Decision:** The project is named TiyraSense for SIH 2026 Problem Statement 26002, the AI-Powered Smart Logistics & Accessibility Intelligence Platform for NER.
- **Why:** This is the approved project identity.
- **Alternatives considered / ruled out:** Prior working names are not authoritative.
- **Status:** FINALIZED.

### D-018 — Pilot corridor fine-tuning (NH-06 Guwahati-Shillong & Damra Bypass)

- **Decision:** Establish National Highway 06 (NH-06) connecting Guwahati Logistics Hub to Shillong Command Terminal as the primary arterial evaluation corridor, backed by the Damra-Mawkyrwat State Highway bypass as the secondary safety alternative, and NH-27 (Guwahati-Silchar) as the secondary long-haul corridor.
- **Why:** NH-06 is the vital economic lifeline into Meghalaya, Mizoram, Tripura, and the Barak Valley carrying essential medical and food supplies, yet suffers repeated disruption from seasonal landslides and waterlogging at Jorabat, Nongpoh, and Umling. The dual-corridor network enables deterministic demonstration of the core logistics value proposition: when NH-06 experiences critical blockage, TiyraSense immediately penalizes the primary route and guides vehicles onto the safest viable bypass.
- **Evidence/source checked:** 14 verified PostGIS road segments seeded via `scripts/seed_road_network.py`; Open-Meteo weather station coordinates for Guwahati Hub (26.1445, 91.7362) and Shillong Terminal (25.5788, 91.8933); IRC:SP:48 Hill Road Guidelines.
- **Alternatives considered / ruled out:** Pure single-corridor setup (ruled out: cannot demonstrate rerouting or alternative route comparison); all-NER 8-state coverage on Day 1 (deferred to post-selection due to map tile volume and compute constraints).
- **Impact / affected files or contracts:** `scripts/seed_road_network.py`, `backend/app/services/routing_service.py`, `backend/app/services/geocoding_service.py`, `docs/gis_and_routing.md`.
- **Status:** FINALIZED.

## Open decisions — do not assume an answer

| Decision needed | Current status | Needed by | Required basis before finalization |
|---|---|---|---|
| Production cloud hosting provider (Post-selection) | OPEN | Production Rollout | Budget, government cloud empanelment (MeitY), SLA requirements |


A "Needed by" date is a scheduling flag, not authorization to auto-select a provider. Providers are still only finalized when a decision record above says **FINALIZED**.

## Blocker escalation

If a "Needed by" day arrives and the decision is still OPEN, the agent must:
1. Not silently pick a provider to keep moving.
2. Record the stall as a BLOCKER in `SESSION.md` and `LOG.md`.
3. Continue with any independent, non-blocked task from the current or an earlier day.
4. Flag it clearly in the session report so the human can decide.



