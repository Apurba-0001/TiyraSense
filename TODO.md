# TODO.md — TiyraSense Project Status

Status terms: **COMPLETE**, **PARTIALLY COMPLETE**, **BLOCKED**, **NOT STARTED**. This is the current work board, not a historical log.

## Phase 0 — Repository & Coordination Setup — COMPLETE

- [x] COMPLETE — Root coordination/documentation files and Git hygiene templates
- [x] COMPLETE — Empty, module-owned directory skeleton: `mobile/`, `web/`, `backend/`, `ml/`, `docs/`, `scripts/`, `tests/`

## Phase 1 — Specification Completion — NOT STARTED

- [ ] Requirements, product, roles/flows, architecture, data/database, API, source/pipeline, GIS/routing, risk/conflict, alert/emergency, ML, offline/mobile/web, testing, and deployment specifications
- [ ] Research and record map/GIS, routing, weather, hosting, risk-formula, and LLM-provider decisions

## Phase 2 — Environment Validation — PARTIALLY COMPLETE

- [x] COMPLETE — Selection-sprint prerequisites: Git, Docker, Docker-based PostgreSQL/PostGIS, Flutter/Dart, Python/venv/pip, and Node/npm/React-TypeScript verified with disposable checks
- [ ] NOT STARTED — Validate the ML toolchain when ML work is scheduled; it is not required for Day 1

## Phase 3 — Thin End-to-End Slice — NOT STARTED

- [ ] Authenticated Flutter login → Python backend → database → response, with RBAC and tests

## Phase 4 — Core Logistics UX — NOT STARTED

- [ ] Journey planning, map, routing integration, candidate route display

## Phase 5 — Real-World Data Ingestion — NOT STARTED

- [ ] Validated data-source integrations and normalized road-segment observations

## Phase 6 — Rule-Based Risk Engine v0 — NOT STARTED

- [ ] Explicitly temporary, documented, tested rule-based prototype

## Phase 7 — Field Reporting + Conflict Resolution — NOT STARTED

- [ ] Offline reports, evidence validation, conflict resolution, and sync tests

## Phase 8 — Disruption Prediction (ML) — NOT STARTED

- [ ] Dataset, temporally valid training/evaluation, calibrated prediction integration

## Phase 9 — Risk-Aware Routing + Alerts + Emergency Mode — NOT STARTED

- [ ] Safety-first route ranking, targeted alerts, emergency workflow

## Phase 10 — Vehicle Tracking, Dashboard + Offline Hardening — NOT STARTED

- [ ] Operational dashboard, tracking, and resilience verification

## Phase 11 — End-to-End Testing + Demo Polish — NOT STARTED

- [ ] Repeatable, clearly labelled demo scenario and end-to-end checks

## Current blockers for later phases

- **BLOCKED:** Provider selections require research and an explicit decision: map/GIS, routing deployment, weather, hosting/deployment, LLM provider.
- **BLOCKED:** Route-risk formula/weights require data and validation; they must not be invented for production use.
