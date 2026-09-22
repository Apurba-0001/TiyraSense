# BUILD_GUIDE.md — TiyraSense

Build incrementally. Do not attempt to generate the entire platform in one AI session, and do not start a later phase until its predecessor has a credible exit condition.

## Build discipline

These rules apply to every phase:

- Read `AGENTS.md` and `SECURITY.md` before implementation, and read only the task-relevant specifications after that.
- Verify current official documentation for any external library, API, model, provider, or platform behavior used by the phase.
- Inspect existing code before adding new code and search for reusable implementations first.
- Keep each change targeted. Do not rewrite working files wholesale when a focused change is sufficient.
- After implementation, run proportionate tests/checks, inspect the diff, remove scratch files, and update `SESSION.md`, `TODO.md`, and `LOG.md`.
- Update `DECISIONS.md` for durable choices and update affected specifications whenever behavior, contracts, architecture, or operational assumptions change.
- Do not mark a phase complete from compilation alone. The exit condition must be evidenced by the relevant test, workflow, or operational check.

## Development Roadmap & Phase Sequence

The initial 7-day selection sprint milestones have concluded and all 11 phases are integrated. The comprehensive phase sequence outlined below represents the canonical development and verification roadmap for TiyraSense.

| Phase | Description | Status |
|---|---|---|
| Phase 0 | Repository & Coordination Setup | COMPLETE |
| Phase 1 | Specification Completion | COMPLETE |
| Phase 2 | Minimum Viable Backend & Auth | COMPLETE |
| Phase 3 | Core Logistics UX & Routing Integration | COMPLETE |
| Phase 4 | GIS Integration & Interactive Map | COMPLETE |
| Phase 5 | Real Data Ingestion & Disruption Monitoring | COMPLETE |
| Phase 6 | Risk Engine v0 & Calibration | COMPLETE |
| Phase 7 | Field Reporting & Crowdsourced Ingestion | COMPLETE |
| Phase 8 | Validated Machine Learning Pipeline | COMPLETE |
| Phase 9 | Dynamic Alerting & Notification Engine | COMPLETE |
| Phase 10 | Emergency Routing Mode & Offline Resilience | COMPLETE |
| Phase 11 | Full Platform Integration & Operational Hardening | COMPLETE |


## Phase 0 — Repository & Coordination Setup

Create the root documentation, Git hygiene, environment template, and module skeleton only. **No application implementation belongs here.**

**Exit condition:** root coordination files are consistent, reviewed, and accurately tracked in `SESSION.md`, `TODO.md`, and `LOG.md`.

## Phase 1 — Specification Completion

Write the necessary `docs/` specifications for product requirements, architecture, data, security references, APIs, GIS/routing, risk/conflict resolution, alerts, ML, offline sync, mobile/web flows, testing, and deployment. Research and record unresolved providers before adoption.

**Exit condition:** specifications define contracts and unresolved choices without pretending unverified providers or data are selected.

## Phase 2 — Environment Validation

Verify the intended Flutter, React/TypeScript, Python, PostgreSQL/PostGIS, Git, and ML tooling locally before code grows complex.

**Exit condition:** documented, reproducible validation results and known setup gaps.

## Phase 3 — Thin End-to-End Slice

Prove a minimal authenticated Flutter login → Python API → database → response path with server-side RBAC.

**Exit condition:** the full slice is tested, handles errors safely, and updates coordination records.

## Phase 4 — Core Logistics UX

Implement destination entry, map display, existing routing-engine integration, and basic candidate-route display. Do not build a routing engine from scratch.

**Exit condition:** verified routes are clearly sourced and the fastest option is shown separately from the safety recommendation.

## Phase 5 — Real-World Data Ingestion

Integrate researched/approved weather, GIS/road, official, and traffic sources where available. Normalize data around `road segment + time + source + provenance`.

**Exit condition:** ingestion validates sources and labels data `LIVE`, `HISTORICAL`, `SIMULATED`, or `TEST`.

## Phase 6 — Rule-Based Risk Engine v0

Create a documented, explicitly temporary rule-based prototype for accessibility and route-risk assessment while real ML is unavailable. It must not masquerade as validated production intelligence.

**Exit condition:** rules, assumptions, evidence provenance, and limitations are visible and tested.

## Phase 7 — Field Reporting and Conflict Resolution

Implement authenticated report submission, offline queue/sync, evidence validation, road-segment mapping, and conflict resolution using reliability, recency, corroboration, and consistency.

**Exit condition:** offline/restore and conflicting-evidence scenarios are tested end-to-end.

## Phase 8 — Disruption Prediction (ML)

Build a historical road-segment dataset, train/evaluate a calibrated model, and integrate disruption probability with model version and horizon. The model predicts; it does not recommend routes.

**Exit condition:** held-out, temporally valid evaluation and documented limitations meet agreed thresholds.

## Phase 9 — Risk-Aware Routing, Alerts, and Emergency Mode

Combine current accessibility, disruption probability, and route risk to rank viable routes; issue targeted alerts; support the weather/landslide emergency demonstration.

**Exit condition:** affected-user targeting, alternative recommendation, traceability, and safety logic are tested end-to-end.

## Phase 10 — Vehicle Tracking, Dashboard, and Offline Hardening

Add official/admin operational views, vehicle tracking, and robust offline/retry/staleness behavior.

**Exit condition:** authorization, recovery, and role workflows are verified in weak/no-network cases.

## Phase 11 — End-to-End Testing and Demo Polish

Run the realistic MVP scenario with real/verified data or clearly labelled simulation. Fix gaps and prepare demo material.

**Exit condition:** the demonstration passes repeatably, limitations are explicit, and evidence of checks is documented.

## MVP cut

Primary SIH scope is Phases 0–4, 6, 7, and 9 with the rule-based prototype clearly labelled. Phase 8 is a stretch goal. Image analysis and multiple vehicle types remain deferred.

