# AGENTS.md — TiyraSense (SIH 2026, Problem Statement 26002)

This is the primary working agreement for every AI agent and human contributor in this repository. Read it before changing anything.

## Project identity

**TiyraSense** is the **AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)** for **SIH 2026, Problem Statement 26002**. It is a risk-aware decision-support platform, not a navigation app or a safety guarantee.

Its purpose is to assess road accessibility, estimate likely disruptions, compare viable routes by risk, alert affected users, and incorporate validated field evidence.

## Technology direction

| Area | Direction |
|---|---|
| Mobile | Flutter; offline-first |
| Web | React + TypeScript |
| Backend | Python |
| Database | PostgreSQL + PostGIS |
| GIS/maps | Open map/GIS ecosystem; provider TBD |
| Routing | Existing routing engine; provider/deployment TBD |
| ML | Python ML ecosystem |
| LLM | Explanation, summarization, multilingual messaging, and dashboard queries only |

Do not treat a provider marked **TBD** as selected. Record a researched, approved architectural change in `DECISIONS.md` before implementing it.

## Mandatory reading order

Before coding, read these files in order:

1. `AGENTS.md`
2. `SECURITY.md`
3. `SESSION.md`
4. `TODO.md`
5. `DECISIONS.md`
6. `BUILD_GUIDE.md`
7. Only the relevant specification documents in `docs/`

If code and documentation disagree, do not silently choose one: determine whether the implementation or specification is stale, record the outcome in `DECISIONS.md`, update the specification, then update code.

## Module ownership

```text
mobile/    Flutter driver and field-worker applications
web/       React + TypeScript official and admin dashboard
backend/   APIs, business logic, risk engine, and alerts
ml/        Models, training, datasets, and evaluation
docs/      Project specifications
scripts/   Controlled utilities
tests/     Integration and end-to-end tests
```

Do not modify another module or unrelated root files without recording why in the session handoff and log.

## Critical architectural separation

```text
DATA         → what information exists?
ML           → what is likely to happen?
RISK ENGINE  → how risky is the road/route?
ROUTING      → which routes are available?
OPTIMIZATION → which viable route should be recommended?
ALERTS       → who needs to know?
LLM          → how should the result be explained?
```

The LLM must never make or override an accessibility state, risk score, or route recommendation.

Keep these outputs distinct and traceable:

- **Current Accessibility:** observed operational state.
- **Disruption Probability:** time-bounded ML prediction with provenance.
- **Route Risk:** composite risk assessment across a candidate route.

Routing/optimization recommends the safest viable route; the fastest available route remains visible.

## Absolute restrictions

Agents must not:

- invent external APIs, source coverage, or real-time information;
- present `SIMULATED` or `TEST` data as `LIVE` or validated;
- hard-code particular roads as safe/dangerous, or fake production probabilities;
- let an LLM directly make safety-critical decisions;
- silently change architecture or add duplicate systems/databases;
- commit credentials, tokens, real `.env` files, or private location data;
- delete working functionality without documenting it in `LOG.md`;
- change unrelated files without justification;
- leave scratch/debug files in the repository;
- mark partial, untested, or UI-only work as complete.

All inputs and outputs must be labeled `LIVE`, `HISTORICAL`, `SIMULATED`, or `TEST` as appropriate.

## Definition of Done

A feature is complete only after this chain is satisfied:

```text
Requirement → Design → Implementation → Integration → Error handling
→ Security review → Tests → Passing tests → Documentation update
→ SESSION/TODO/LOG update
```

For mobile work, explicitly consider offline behavior and recovery. For intelligence work, preserve data provenance, timestamps, confidence, and the version of the model/risk logic used. A compiling screen, endpoint, or isolated function is not a completed feature.

## Session close-out

Before ending a work session:

1. Run proportionate checks and record their results.
2. Update `SESSION.md` with the exact state, files changed, verification, blockers, and one next task.
3. Update `TODO.md` statuses and append a factual entry to `LOG.md`.
4. Record durable architectural/security decisions in `DECISIONS.md`.
5. Inspect `git status`; do not stage, discard, or overwrite unrelated user changes.

