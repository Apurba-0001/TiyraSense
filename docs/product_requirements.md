# Product Requirements Specification — TiyraSense

**Project Identity:** TiyraSense (SIH 2026, Problem Statement 26002)  
**Classification:** AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)  
**Document Status:** FINALIZED Specification (Phase 1)

---

## 1. Problem Context & Core Vision

The North Eastern Region (NER) of India faces severe logistics, access, and transportation bottlenecks due to complex Himalayan topography, active tectonic zones, heavy monsoon precipitation, cloudbursts, riverine flooding, and frequent landslides. Standard consumer navigation platforms (Google Maps, Apple Maps) focus on commercial highway transit times and frequently route logistics carriers onto impassable, flooded, or structurally compromised hill roads because they lack localized terrain risk modeling, offline evidence aggregation, and official state disaster management integration.

**TiyraSense is a risk-aware decision-support platform, not a generic navigation app or a safety guarantee.** It evaluates road accessibility, predicts localized disruptions, compares alternative routes by safety risk, alerts affected logistics operators, and incorporates field observations directly from drivers and emergency workers.

---

## 2. Target Users & Operating Personas

| Persona | Primary Needs & Operating Constraints | Key System Touchpoints |
|---|---|---|
| **Commercial Logistics Driver** | Transits inter-state corridors (e.g. NH-6, NH-27); experiences extended network dead zones; requires proactive warnings before entering isolated mountain passes; needs offline route guidance and one-tap incident reporting. | Mobile App (Flutter, Offline-First) |
| **Field Worker / Incident Reporter** | Stationed at checkpoints, toll plazas, or disaster relief sites; observes physical road cuts, mudslides, waterlogging, bridge distress; submits ground-truth photos and severity reports. | Mobile App (Field Mode, GPS verified) |
| **Logistics Coordinator / Dispatcher** | Monitors fleet journeys across Assam, Meghalaya, and neighbouring states; manages delivery schedules; reroutes vehicles away from developing hazards. | Web Intelligence Dashboard (React + TS) |
| **Disaster Official / Regional Admin** | Verifies crowd-sourced incident reports; issues corridor-wide travel advisories; monitors live regional accessibility states. | Web Admin Portal (React + TS) |

---

## 3. Pilot Geography & Baseline Corridor

To ground all benchmarks, spatial indexing, and demonstration data in real-world infrastructure, the primary pilot geography for the selection sprint and MVP is the **Guwahati–Shillong Corridor (NH-6 / GS Road)** and its immediate secondary bypass networks:

- **Primary Corridor:** Guwahati (Kamrup Metropolitan, Assam) $\leftrightarrow$ Jorabat $\leftrightarrow$ Nongpoh $\leftrightarrow$ Umiam $\leftrightarrow$ Shillong (East Khasi Hills, Meghalaya). Distance $\approx 100$ km. High freight volume, steep valley gradients, prone to monsoon mudslides and rockfalls near Nongpoh and Umsning.
- **Alternative / Bypass Corridors:**
  - Route A (Standard NH-6 GS Road 4-lane): Fastest under normal conditions (~2.5h), highly vulnerable to cut-offs during extreme precipitation.
  - Route B (Secondary via Guwahati–Damra–Nongstoin–Shillong or local arterial bypasses): Slower transit (~4.5h), lower mudslide susceptibility in critical cut-off sections.
- **Geographic Extent:** $25.5^\circ \text{N}$ to $26.3^\circ \text{N}$, $91.5^\circ \text{E}$ to $92.0^\circ \text{E}$.

---

## 4. Functional Requirements (FR)

### FR-1: Road-Segment-Centric Ingestion & Network Representation
- The road network must be decomposed into discrete, uniquely identified segments (`road_segments`) defined by PostGIS LineString geometries, length, road classification (NH, SH, MDR), gradient, and terrain slope.
- Every dynamic state (weather, incidents, risk score, traffic) must bind directly to `road_segment_id`.

### FR-2: Multi-Source Quantitative Weather Ingestion
- Ingest real-time and forecasted meteorological parameters (hourly precipitation mm/h, soil moisture saturation %, wind gust km/h, surface pressure) from Open-Meteo API for geographic points along road corridors.
- Maintain temporal provenance and data labeling (`LIVE`, `HISTORICAL`, `SIMULATED`, `TEST`).

### FR-3: Ground-Truth Field Incident Reporting
- Provide an offline-first mobile interface for reporting incidents: `LANDSLIDE`, `MUDSLIDE`, `WATERLOGGING`, `ROAD_COLLAPSE`, `TREE_FALL`, `HEAVY_CONGESTION`, `BRIDGE_DISTRESS`.
- Support severity rating (Low, Medium, High, Critical), geotagged coordinates, photo upload, and local offline timestamping.

### FR-4: Conflict Resolution & Provenance Tracking
- Resolve conflicting reports on the same road segment using an auditable multi-factor arbitration model: source reliability weight, recency decay, cross-source corroboration, and physical plausibility.
- Never overwrite evidence history; store raw observations in `field_reports` and publish verified state to `road_segments`.

### FR-5: Three-Concept Risk Assessment
- Explicitly evaluate and present three distinct metrics:
  1. **Current Accessibility State:** Discrete status (`OPEN`, `CAUTION`, `RESTRICTED`, `HIGH_RISK`, `BLOCKED`, `UNKNOWN`).
  2. **Disruption Probability:** Continuous likelihood ($0.0 \le P \le 1.0$) of transit stoppage within a 2-hour forward horizon.
  3. **Route Risk:** Composite hazard index across a full origin-destination journey.

### FR-6: Safety-First Multi-Route Evaluation & Recommendation
- Generate multiple viable candidate routes between origin and destination.
- Calculate travel duration and aggregate safety risk for each candidate.
- Recommend the **safest viable route** as the default choice while keeping the **fastest route** visible with transparent risk comparison warnings.

### FR-7: Proactive Journey Alerting & Geofenced Dispatch
- Track active driver journeys against candidate routes.
- When an upstream segment on an active journey transitions to `HIGH_RISK` or `BLOCKED`, identify affected journeys within seconds and dispatch prioritized alerts with alternative diversion options.

### FR-8: Multilingual AI Advisory Generation (LLM Boundary Protected)
- Generate concise, culturally contextualized, multilingual voice/text advisories (Assamese, Bengali, Hindi, English) explaining why a route is risky or diverted.
- The LLM is strictly confined to textual synthesis and summarization. It must never calculate, alter, or override risk scores, accessibility states, or route recommendations.

---

## 5. Non-Functional Requirements (NFR)

- **NFR-1 (Offline Tolerance):** Mobile clients must function seamlessly during network drops $\ge 24$ hours, caching maps, tracking journey state locally, and queueing outgoing field reports with SQLite.
- **NFR-2 (Latency):** Route evaluation and risk scoring API responses must complete within $\le 1.5$ seconds for journeys spanning up to 200 road segments.
- **NFR-3 (Data Labeling & Auditability):** 100% of stored and displayed observations, scores, and alerts must carry provenance headers (`LIVE`, `HISTORICAL`, `SIMULATED`, or `TEST`).
- **NFR-4 (Security & Zero-Trust):** Server-side RBAC validation on all state-altering endpoints; no hardcoded API credentials; strictly parameterized database access.
- **NFR-5 (Resource Footprint):** Development stack must run fully locally within Docker Compose under 4 GB RAM footprint.

---

## 6. End-to-End Canonical Evaluation Scenario (20-Step Flow)

1. Driver logs into TiyraSense Mobile; active offline route cache verified.
2. Driver initiates freight journey from Guwahati to Shillong.
3. System fetches baseline OSRM route geometry and evaluates PostGIS segment risks.
4. Fastest route (NH-6 GS Road) and alternative secondary route are displayed; fastest is currently OPEN.
5. Journey commences; mobile app records breadcrumbs locally.
6. Weather worker ingests Open-Meteo precipitation surge (55 mm/hr cloudburst event near Nongpoh).
7. Rain-intensity trigger elevates Disruption Probability on Segment `NER-NH6-042` from 0.12 to 0.68.
8. Local field worker loses cellular signal; inspects active mudslide on `NER-NH6-042`.
9. Field worker captures photo and submits `MUDSLIDE - HIGH` report in offline mode.
10. Field worker moves to roadside village with 2G/EDGE; report automatically syncs.
11. Ingestion service receives field report; triggers Conflict Resolution Engine.
12. Corroborated evidence elevates Segment `NER-NH6-042` to `HIGH_RISK / BLOCKED`.
13. Road segment update propagates to active journey monitor.
14. System detects Driver's active journey heading towards `NER-NH6-042` (18 km upstream).
15. Targeted high-priority Alert is generated with alternative diversion via Umsning-Shillong bypass.
16. Gemini advisory service formats alert explanation in Assamese and English.
17. Driver's mobile device receives alert notification; sounds audible hazard alert.
18. Driver accepts recommended safe diversion; navigation recalculates.
19. Regional Web Intelligence Dashboard updates live map view: Nongpoh highlighted RED, rerouted fleet visible.
20. Journey completes safely; all events permanently logged with audit provenance.
