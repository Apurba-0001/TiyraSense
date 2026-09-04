# TODO.md — TiyraSense Project Status

Status terms: **COMPLETE**, **PARTIALLY COMPLETE**, **BLOCKED**, **NOT STARTED**. This is the current work board, not a historical log.

## Phase 0 — Repository & Coordination Setup — COMPLETE

- [x] COMPLETE — Root coordination/documentation files and Git hygiene templates
- [x] COMPLETE — Empty, module-owned directory skeleton: `mobile/`, `web/`, `backend/`, `ml/`, `docs/`, `scripts/`, `tests/`

## Phase 1 — Specification Completion — COMPLETE

- [x] COMPLETE — Requirements, product, roles/flows, architecture, data/database, API, source/pipeline, GIS/routing, risk/conflict, alert/emergency, ML, offline/mobile/web, testing, and deployment specifications (all 12 comprehensive specs authored under `docs/`)
- [x] COMPLETE — Researched, verified, and recorded map/GIS (OSM/MapLibre/flutter_map), routing (OSRM/PostGIS), weather (Open-Meteo/IMD), hosting (Docker PostGIS), risk-formula (multi-factor weights), and LLM-provider (Gemini free tier) decisions in `DECISIONS.md` (D-010 through D-015)

## Phase 2 — Environment Validation — PARTIALLY COMPLETE

- [x] COMPLETE — Selection-sprint prerequisites: Git, Docker, Docker-based PostgreSQL/PostGIS, Flutter/Dart, Python/venv/pip, and Node/npm/React-TypeScript verified with disposable checks
- [ ] NOT STARTED — Validate the ML toolchain when ML work is scheduled; it is not required for Day 1

## Phase 3 — Thin End-to-End Slice & Security Hardening — COMPLETE

- [x] COMPLETE — Authenticated Flutter login → Python FastAPI backend → PostGIS database → response, with server-side RBAC (Driver, Field Worker, Official, Admin) and 10 passing widget tests.
- [x] COMPLETE — React 18 + TypeScript + Vite web operations console & admin governance shell with RoleGuard and 5 passing Vitest tests.
- [x] COMPLETE — FastAPI backend (`app/main.py`) with asyncpg connection pool, bcrypt, JWT auth, healthcheck, and 23 passing pytest tests.
- [x] COMPLETE — Initial user accounts seeded for all 4 roles in live PostgreSQL/PostGIS database via `scripts/seed_users.py`.
- [x] COMPLETE — Security Hardening: Registration role restriction (`RegistrationRole` accepts only DRIVER and FIELD_WORKER; rejects OFFICIAL/ADMIN with 422), DB-authoritative RBAC, SQL/null-byte/control-char defenses, and HTTP security response headers (`CSP`, `nosniff`, `X-Frame-Options: DENY`).
- [x] COMPLETE — Persistent Mobile Authentication: Hardware-encrypted storage via `flutter_secure_storage` (Android Keystore / iOS Keychain) preserving session across app restarts and offline cold boots.
- [!] NOTE — Current State of Data: Auth, RBAC, DB connection, and encrypted session storage are LIVE. Corridor lists, route options, and hazard feeds on the client UI are currently pre-defined demonstrations pending Phase 4 (OSRM route engine & dynamic origin/destination selection).

## Phase 4 — Core Logistics UX (Dynamic Route Planning & GIS) — NOT STARTED (Next)

- [ ] Dynamic Origin & Destination Hub selection (Guwahati, Shillong, Silchar, Dimapur, Kohima, etc.)
- [ ] OSRM routing engine integration (`/api/v1/routes/evaluate` and `/api/v1/routes/plan`)
- [ ] Multi-factor candidate route evaluation: Safest Viable vs Fastest Available
- [ ] Dynamic road corridor status and geometry endpoints

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

## Status evidence rule

Statuses in this file must reflect the repository as verified in the current session. Do not mark work complete from documentation, compilation, or UI appearance alone. Record the verification evidence in `SESSION.md` and `LOG.md`; use `BLOCKED` when an open decision or dependency genuinely prevents the next task.

## Current blockers for later phases
 
- **Blockers:** None. Provider decisions D-010 through D-015 and security decisions D-016 through D-017 are FINALIZED in `DECISIONS.md`.
- **Immediate Next Task:** Phase 4 / Selection Sprint Day 2: Implement dynamic Origin/Destination Hub selector and integrate OSRM routing engine with PostGIS multi-factor risk evaluation.
