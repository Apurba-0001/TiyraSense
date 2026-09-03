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

- **Phase 0 — Repository & Coordination Setup:** complete.
- **Selection Sprint Day 0 — Environment Verification:** complete. Local Flutter, Python, React/TypeScript, and PostgreSQL/PostGIS prerequisites were verified with disposable checks; nothing application-level was added.
- The project is ready to begin **Selection Sprint Day 1 — Working Foundation**.
- No application code or detailed `docs/` specification tree has been created yet.
- Map/GIS, routing, weather, hosting, and LLM providers remain open — see `DECISIONS.md` for what is finalized versus still to be researched.

See `SESSION.md` for the current handoff and next task, `TODO.md` for the full phase-by-phase status board, and `LOG.md` for historical verified work. Status files are evidence to verify, not substitutes for inspecting the repository.

## Documentation index

- `AGENTS.md` — mandatory working rules for agents, including document authority
- `PROJECT_CONTEXT.md` — permanent product knowledge
- `SESSION.md` — current handoff and next task
- `LOG.md` — historical development record
- `TODO.md` — current status board
- `DECISIONS.md` — architectural decision rationale and open decisions
- `BUILD_GUIDE.md` — phased build order and exit conditions
- `SECURITY.md` — root security policy
- `TiyraSense_7_DAY_SELECTION_SPRINT.md` — active day-to-day selection-sprint execution plan
- `TiyraSense_MASTER_AGENT_PROMPT.md` — orchestration entry point for AI agents
- `FIRST_SESSION.md` — protocol for starting a new AI agent session
- `CONTINUE_SESSION.md` — protocol for continuing existing work
- `FIRST_SESSION.md` / `CONTINUE_SESSION.md` are the canonical session protocols; use the existing suffixed copies only if explicitly needed for archival reference.
- `.env.example` — placeholder-only configuration template

## Source of truth

Current user-approved requirements take precedence. `PROJECT_CONTEXT.md` and future specifications describe the intended system; code describes what exists today. When they disagree, record the resolution in `DECISIONS.md` before changing implementation. See `AGENTS.md` → "Document authority" for the full hierarchy.
