# DECISIONS.md — TiyraSense

This is the reasoning trail for durable project choices, not a status log. Newest records appear first. No provider is selected unless its record says **FINALIZED**.

## Established decisions

### D-009 — Offline-first mobile operation

- **Decision:** Driver and Field Worker mobile capabilities are offline-first, retaining queued reports and relevant journey data with timestamps.
- **Why:** NER travel includes intermittent/weak connectivity; incident reporting and safety information must degrade safely.
- **Alternatives considered / ruled out:** Online-only mobile operation is unsuitable for the operating environment.
- **Status:** FINALIZED product direction; implementation details remain open.

### D-008 — Road-segment-centric intelligence

- **Decision:** Geographic intelligence is organised around road segments and time, so observations, predictions, risk, routing, and alerts share traceable geographic units.
- **Why:** This supports consistent evidence mapping, prediction, route assessment, and operational views.
- **Alternatives considered / ruled out:** Isolated, route-only or report-only intelligence would lose reuse and traceability across the platform.
- **Status:** FINALIZED architectural direction; detailed data model is pending specification.

### D-007 — LLM excluded from safety-critical routing decisions

- **Decision:** LLM components are limited to explanation, summarization, multilingual messaging, and natural-language dashboard queries. Deterministic risk, routing, and optimization layers make route recommendations.
- **Why:** LLM output is not reliably calibrated or auditable enough for safety-critical decisions.
- **Alternatives considered / ruled out:** Direct LLM route/accessibility/risk decisions are ruled out.
- **Status:** FINALIZED safety boundary; provider is open.

### D-006 — Safety-first routing over fastest-route-first

- **Decision:** Recommend the safest viable route while keeping the fastest available route visible.
- **Why:** Reducing disruption risk is the core logistics value proposition; travel time is important but secondary to safety and viability.
- **Alternatives considered / ruled out:** Fastest-route-only recommendation is ruled out.
- **Status:** FINALIZED product behavior; exact risk weights remain open.

### D-005 — Three separate risk concepts

- **Decision:** Track and display Current Accessibility, Disruption Probability, and Route Risk separately, each with provenance.
- **Why:** A single blended number hides whether evidence is a current fact, a prediction, or a route-level assessment and damages explainability.
- **Alternatives considered / ruled out:** A single opaque "risk score" is ruled out.
- **Status:** FINALIZED conceptual model; formula/threshold validation remains open.

### D-004 — Four-wheelers as the initial vehicle baseline

- **Decision:** MVP routing and risk logic targets four-wheelers while retaining an extensible design for later vehicle-specific support.
- **Why:** It keeps MVP scope achievable without foreclosing future expansion.
- **Alternatives considered / ruled out:** Implementing all vehicle categories in the first MVP is deferred.
- **Status:** FINALIZED MVP scope.

### D-003 — Existing routing engine

- **Decision:** Integrate an established routing engine rather than building global navigation from scratch.
- **Why:** TiyraSense adds safety/risk intelligence over routing; it should not reimplement commodity route computation.
- **Alternatives considered / ruled out:** A custom navigation engine is ruled out for the MVP.
- **Status:** FINALIZED direction; engine and deployment remain open.

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

## Open decisions — do not assume an answer

| Decision needed | Current status | Required basis before finalization |
|---|---|---|
| Map/GIS provider | OPEN | NER coverage, licensing, cost, offline/overlay needs, and operational suitability |
| Routing deployment/provider | OPEN | Route coverage, vehicle support, licensing, cost, hosting, and integration fit |
| Weather provider(s) | OPEN | NER coverage, historical data, update frequency, reliability, and cost |
| Hosting/deployment provider | OPEN | Security, cost, operational support, data residency needs, and managed PostGIS options |
| Route-risk formula and weights | OPEN | Documented evidence, pilot data, validation, calibration, and safety review |
| LLM provider | OPEN | Privacy, cost, language support, reliability, and explanation-only boundary |

