# TiyraSense

**SIH 2026 · Problem Statement 26002**  
**AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)**

TiyraSense is a safety-first logistics decision-support platform. It brings together validated road, weather, GIS, official, historical, traffic, and field evidence to assess current accessibility, estimate future disruption probability, compare route risk, recommend a safer viable route, and alert affected users.

**Current Accessibility**, **Disruption Probability**, and **Route Risk** remain separate, traceable concepts: observed state, time-bounded prediction, and route-level assessment respectively.

It is not a navigation app and it does not promise safety. The fastest available route remains visible, while recommendation prioritizes risk-aware viability.

## Users and platform components

- **Drivers and field workers:** Flutter, offline-first mobile apps for journeys, alerts, and incident reporting.
- **Officials and administrators:** React + TypeScript web dashboard for operational awareness, validation, and administration.
- **Backend:** Python services for APIs, evidence processing, risk, routing integration, and alerts.
- **Data:** PostgreSQL + PostGIS for the primary geospatial datastore.
- **Intelligence:** Python ML predicts disruption; the deterministic risk/routing/optimization layers assess and recommend; an LLM may only explain or summarize.

Map/GIS, routing, weather, hosting, and LLM providers are intentionally undecided until researched and recorded in `DECISIONS.md`.

## Current project state

The project is in **Phase 0: documentation and coordination setup**. No application code or detailed `docs/` specification tree has been created yet.

## Documentation index

- `AGENTS.md` — mandatory working rules for agents
- `PROJECT_CONTEXT.md` — permanent product knowledge
- `SESSION.md` — current handoff and next task
- `LOG.md` — historical development record
- `TODO.md` — current status board
- `DECISIONS.md` — architectural decision rationale and open decisions
- `BUILD_GUIDE.md` — phased build order and exit conditions
- `SECURITY.md` — root security policy
- `.env.example` — placeholder-only configuration template

## Source of truth

Current user-approved requirements take precedence. `PROJECT_CONTEXT.md` and future specifications describe the intended system; code describes what exists today. When they disagree, record the resolution in `DECISIONS.md` before changing implementation.
