# PROJECT_CONTEXT.md — TiyraSense

**SIH 2026 · Problem Statement 26002 **

This is permanent knowledge: it should stay stable regardless of what sprint or session is happening. Development status does not belong here — that goes in `SESSION.md` / `LOG.md` / `TODO.md`.

## 1. Problem Background

The North Eastern Region of India faces logistics and accessibility challenges from difficult/mountainous terrain, extreme and rapidly changing weather, landslides, floods, heavy rainfall, road damage, infrastructure gaps, and low connectivity in remote areas. This disrupts movement of medicines, food, agricultural produce, construction materials, and other essential goods — causing delays, shortages, higher costs, and slower emergency response.

## 2. The Real Problem

Not "roads sometimes get blocked" — there is no integrated system turning fragmented information (government data, weather, field reports, terrain, history) into usable route intelligence. Drivers don't know if a route is currently accessible or about to become dangerous. Officials lack one unified operational view of incidents, high-risk corridors, affected vehicles, predictions, and alternatives.

## 3. One-Sentence Product Definition

> TiyraSense is an AI-powered logistics safety and accessibility platform that combines real-time, historical, geographic, weather, traffic, official, and field intelligence to predict route disruptions, assess road accessibility, recommend safer routes, and alert affected users before and during logistics journeys.

## 4. Core Product Promise

Before and during a journey, TiyraSense evaluates current and predicted conditions and recommends the safest viable route while explaining important changes as they happen.

## 5. Core Intelligence Loop

```
Collect (real-time + historical + field + GIS + weather + traffic + official)
  → Validate / Normalize → Assess source reliability → Resolve conflicts
  → Current accessibility → Predict future disruption → Evaluate candidate routes
  → Recommend safest viable route → Alert affected users
  → Receive new field reports → Recalculate → Record actual outcome
  → Improve historical dataset → Improve future models
```

This feedback loop is a core part of the product, not an afterthought.

## 6. Target Users

| Role | Client | Key capabilities |
|---|---|---|
| **Driver** | Flutter mobile | plan journeys, see accessibility/risk/prediction, receive alerts & alternates, track journey, report incidents, work offline |
| **Field Worker** | Flutter mobile | submit geo-tagged reports with photo/severity/description, work offline |
| **Official** | React web | monitor roads/incidents/vehicles, review & validate reports, inspect predictions/emergency zones |
| **Admin** | React web | manage users/roles/data sources/config/alerts/geographic areas, monitor system health |

Drivers and field workers are both **consumers** of intelligence and **sources** of it.

## 7. Safety-First Routing Philosophy

Safety takes priority over shortest time — but the system never hides the fastest option.

```
(example — not a spec'd threshold)
Route A: ETA 5h20m, disruption 78%, risk HIGH
Route B: ETA 6h05m, disruption 14%, risk LOW
→ Recommended: Route B   |   Fastest available: Route A
```

Use an existing routing engine (e.g. OSRM/GraphHopper/Valhalla class of tool) — TiyraSense adds the risk/intelligence layer, it does not build global navigation from scratch. Initial vehicle baseline: **four-wheelers**.

## 8. Risk Must Stay in Three Separate Concepts

1. **Current Accessibility** — `OPEN / CAUTION / RESTRICTED / HIGH_RISK / BLOCKED / UNKNOWN`
2. **Disruption Probability** — ML output, e.g. "72% chance of disruption in the next 12h." Initial horizon: now + ~24h.
3. **Route Risk** — composite score combining accessibility, predicted disruption, weather/rainfall, flood/landslide risk, traffic, restrictions, vehicle compatibility, delivery priority, emergency status, evidence confidence. Exact formula/weights must be validated and documented — never invented arbitrarily.

Never collapse these into a single number, and always preserve where a value came from (observation / official confirmation / prediction / current state / recommendation).

## 9. Data Sources & Conflict Resolution

Planned: government/official data, field reports, weather/forecast, traffic (where available), GIS/map data, terrain, historical disruption records, other reliable sources. Each observation preserves source, timestamp, location, freshness, evidence, and reliability/confidence.

Conflicts are resolved using: source reliability, recency, geographic relevance, evidence, corroboration, environmental consistency, historical consistency. **Never blindly trust one source.**

## 10. Field Reporting

Reports include GPS location, incident type, severity, photo, timestamp, short description. Flow: `Report → Store → Validate → Map to road segment → Evaluate evidence → Update accessibility → Recalculate risk → Check affected journeys → Alert when necessary`. Incident classes: landslide, flood, debris, fallen tree, road damage, bridge issue, severe obstruction, other. Photo AI (if used) is *supporting* evidence only — never an independent safe/blocked verdict.

## 11. AI/ML Approach

Do not use one model for everything.

- **Disruption prediction** (primary ML problem): probability a road segment disrupts within a defined horizon. Inputs: rainfall/weather/forecast, terrain/slope/elevation, road characteristics, historical incidents, traffic, current condition, field/official reports, seasonal patterns. Starting models: Random Forest, Gradient Boosting, XGBoost/LightGBM-style — chosen based on actual data and calibration, not assumption.
- **Other components:** travel-time prediction, incident classification, optional image analysis.
- **LLM:** report understanding, summaries, explanations, multilingual messages, natural-language dashboard queries. **Must never directly make the safety-critical route decision.**

Critical ML rule: a prediction at time T may only use information available at or before T (no temporal leakage). Predictions retain probability, horizon, timestamp, confidence/calibration, and model version.

## 12. Emergency Mode

```
Incident → Affected zone → Affected roads → Affected journeys/vehicles/users
  → Targeted alerts → Safer alternatives → Official dashboard update
```

Alerts are targeted to people actually affected or approaching the affected area — not broadcast blindly.

## 13. Offline-First Mobile

```
Offline: Create report → Local database → Sync queue
Online:  Sync queue → Backend → Normal processing
```

App retains: active route, relevant map/route data, latest known road status, relevant alerts, recent incidents — all timestamped so stale data is never mistaken for current data.

## 14. Safety & Trust Principles

TiyraSense is **decision support, not a safety guarantee**. Preferred phrasing: *"Based on available evidence, this route has a lower predicted disruption risk."* Every recommendation must be traceable through data sources, timestamps, evidence, prediction, confidence, model version, risk-engine version, route candidates, and final recommendation.

## 15. Data Reality

Use real data wherever available; prefer official government sources; document limitations when using secondary sources (weather/GIS/traffic). Tag everything `LIVE / HISTORICAL / SIMULATED / TEST`. Never present simulated data as validated real-world data.

## 16. Free-First Strategy

Open-source tech, free tiers, local dev, open map/GIS data, low-cost deployment initially — but the architecture stays modular so better/paid providers can be swapped in later without major rewrites.

## 17. Core Data Entities

```
users, roles, vehicles, road_segments, incidents, incident_evidence,
weather_observations, traffic_observations, predictions, routes, journeys,
alerts, affected_zones, field_reports, sync_records, data_sources,
model_versions, audit_logs
```

System is **road-segment-centric** — the same geographic intelligence powers routing, prediction, alerts, and dashboards.

## 18. Definition of a Successful MVP / Demo Scenario

```
Journey starts → Rainfall increases → Risk rises → ML predicts increased disruption
  → Field worker/driver reports landslide → Evidence combined
  → Road becomes HIGH_RISK/BLOCKED → Affected driver identified → Alert issued
  → Alternative route calculated & recommended → Official dashboard updates
  → Offline report syncs once connectivity returns
```

If this loop works end-to-end with real/verified inputs in the pilot geography, the project demonstrates its core value.

## 19. What This Project Is Not

Not a pure navigation app. Not a single "AI risk score" black box. Not a system where the LLM decides routes. Not a demo built on invented/fake real-time data presented as real.
