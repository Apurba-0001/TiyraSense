# AI_DEVELOPMENT_SETUP.md
# TiyraSense
# SIH 26002 NER Logistics Intelligence Platform
# AI-Assisted Multi-Agent Development Setup

> **Purpose**
>
> This document defines the documentation, repository structure, AI-agent workflow, session continuity system, decision tracking, progress tracking, security rules, build discipline, and handoff process that should be established **before AI coding agents begin building the NER logistics platform**.
>
> It does **not** implement or fill the project's individual specification files. Instead, it defines what those files must exist for, what they should contain, how they relate to each other, and how multiple AI models can safely work on the same repository without losing context.

---

# 1. Project Context

## Project

**SIH 2026 Problem Statement 26002**

### Project name

**TiyraSense**

### Project subtitle

**AI-Powered Smart Logistics & Accessibility Intelligence Platform for the North Eastern Region (NER)**

### Core objective

Build a real working platform that combines:

- real-time information,
- historical records,
- weather,
- GIS/map data,
- government/official sources,
- traffic information where available,
- field reports,
- GPS/vehicle information,
- AI/ML predictions,
- route optimization,
- risk analysis,
- emergency alerts,
- and offline operation.

The platform should help drivers, field workers, officials, and administrators determine:

- current road accessibility,
- probability of future disruption,
- route risk,
- safer alternative routes,
- affected vehicles/users,
- and emergency logistics conditions.

The core product promise is:

> **Before and during a journey, evaluate current and predicted road conditions and recommend the safest viable route while keeping the user informed when conditions change.**

---

# 2. Why This File Exists

Large AI-assisted projects have a specific problem:

> Different AI models do not share memory automatically.

A project may be worked on by:

- Claude Code,
- Codex,
- Gemini,
- Cursor,
- GitHub Copilot,
- Antigravity,
- another coding agent,
- or a human developer.

If every agent starts by reading only the code, it may:

- repeat work,
- undo previous decisions,
- create conflicting architecture,
- touch unrelated files,
- forget important requirements,
- use fake APIs,
- create duplicate services,
- change database structures unexpectedly,
- misunderstand what is already finished,
- or leave incomplete work without documenting it.

The repository therefore needs a **persistent project memory system**.

The minimum cross-agent memory system is:

```text
AGENTS.md
SESSION.md
LOG.md
TODO.md
DECISIONS.md
SECURITY.md
BUILD_GUIDE.md
```

The individual specification documents then define the actual NER system.

---

# 3. Source-of-Truth Hierarchy

AI agents must understand that different documents have different authority.

Use this hierarchy:

```text
1. Current user-approved requirements
2. PROJECT_CONTEXT.md
3. REQUIREMENTS.md
4. PRODUCT_SPECIFICATION.md
5. ARCHITECTURE.md
6. Feature/system specification documents
7. DECISIONS.md
8. SECURITY.md
9. AGENTS.md
10. BUILD_GUIDE.md
11. SESSION.md
12. TODO.md
13. LOG.md
14. Existing code
```

However, this hierarchy needs one important rule:

> **Code is authoritative for what currently exists; documentation is authoritative for what the system is supposed to become.**

If code and documentation conflict:

1. Do not silently choose one.
2. Determine whether the code is stale or the specification changed.
3. Record the decision in `DECISIONS.md`.
4. Update the affected specification.
5. Then update the code.

---

# 4. The Three Different Types of Project Memory

Do not mix project information together.

## A. Permanent knowledge

This belongs in:

- `PROJECT_CONTEXT.md`
- `REQUIREMENTS.md`
- `ARCHITECTURE.md`
- other specification documents.

Examples:

> The mobile app uses Flutter.

> Safety takes priority over fastest route.

> Prediction means probability of disruption within a defined future horizon.

---

## B. Why decisions were made

This belongs in:

`DECISIONS.md`

Example:

> OpenStreetMap-based mapping was selected for the initial free-first implementation because the project needs custom road overlays and lower initial cost.

---

## C. What happened during development

This belongs in:

- `SESSION.md`
- `LOG.md`
- `TODO.md`

Examples:

> Phase 4 completed.

> `risk_engine.py` was modified.

> ML model endpoint is implemented but not yet validated against a real dataset.

Do not put temporary development status inside permanent architecture documents.

---

# 5. Repository Documentation Structure

Before major coding begins, create:

```text
docs/
│
├── PROJECT_CONTEXT.md
├── REQUIREMENTS.md
├── PRODUCT_SPECIFICATION.md
├── USER_ROLES.md
├── USER_FLOWS.md
│
├── ARCHITECTURE.md
├── DATA_ARCHITECTURE.md
├── DATABASE_SCHEMA.md
├── API_SPECIFICATION.md
│
├── DATA_SOURCES.md
├── DATA_PIPELINES.md
├── GIS.md
├── ROUTING_ENGINE.md
├── RISK_ENGINE.md
├── CONFLICT_RESOLUTION.md
├── ALERT_SYSTEM.md
├── EMERGENCY_MODE.md
│
├── ML_SPECIFICATION.md
├── ML_DATASET.md
├── MODEL_EVALUATION.md
│
├── OFFLINE_SYNC.md
├── MOBILE_APP.md
├── WEB_DASHBOARD.md
├── SECURITY.md
├── TESTING.md
└── DEPLOYMENT.md
```

Repository-level coordination files:

```text
AGENTS.md
SESSION.md
LOG.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
SECURITY.md
README.md
.env.example
.gitignore
```

If `SECURITY.md` is kept at the repository root, `docs/SECURITY.md` should not be duplicated unless there is a clear reason.

Recommended:

```text
AGENTS.md
SESSION.md
LOG.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
SECURITY.md

docs/
...
```

---

# 6. AGENTS.md

## Purpose

`AGENTS.md` is the **behavioral instruction manual for every AI coding agent**.

Uploaded multi-agent project guidance demonstrated the value of treating `AGENTS.md` as the single source of truth for agents and requiring agents to read security and project state before coding.

For NER, this pattern should be preserved and expanded.

`AGENTS.md` should contain:

### Project summary

A concise explanation of the NER platform.

### Current scope

What the MVP includes and what is deliberately deferred.

### Finalized stack

At the current planning stage:

- Flutter mobile
- React + TypeScript web
- Python backend
- PostgreSQL + PostGIS
- GIS/map system
- routing engine
- AI/ML services
- external data ingestion
- offline-first mobile operation

Exact provider choices should only be recorded after they are researched and approved.

### Mandatory reading order

Every AI agent should read:

```text
1. AGENTS.md
2. SECURITY.md
3. SESSION.md
4. TODO.md
5. DECISIONS.md
6. BUILD_GUIDE.md
7. relevant architecture/specification documents
```

An agent should not start coding before reading the required documents.

### Coding conventions

Define:

- naming,
- folder ownership,
- API conventions,
- state-management conventions,
- database conventions,
- error handling,
- testing rules,
- logging,
- comments/docstrings,
- dependency rules.

### Module ownership

For example:

```text
mobile/       Flutter only
web/          React only
backend/      API/business services
ml/           model/data work
docs/         project specifications
scripts/      controlled utilities
tests/        integration/end-to-end tests
```

### Things agents must not do

Examples:

- do not invent external APIs,
- do not fabricate real-time data,
- do not hard-code risk probabilities,
- do not let an LLM make direct safety-critical route decisions,
- do not silently change architecture,
- do not introduce a second database unnecessarily,
- do not commit secrets,
- do not delete working functionality,
- do not leave scratch scripts,
- do not modify unrelated files,
- do not mark incomplete features as complete.

### Definition of done

Every feature must meet the project definition of done before being marked complete.

---

# 7. SESSION.md

## Purpose

`SESSION.md` is the **short-term handoff memory**.

It answers:

> What was the last agent doing, what was actually completed, and what should the next agent do first?

This should be kept short.

It should contain the **newest session at the top**.

Use this structure:

```markdown
# Session Handoff — TiyraSense | SIH 26002

Updated at the END of every work session.
Read this before starting work.

---

## Current State

Phase:
Feature:
Overall status:
Current branch:

---

## Latest Session

### [DATE] — [MODEL/AGENT] — [PHASE]

**Did:**
What was actually changed.

**State:**
Precise completion status.

Examples:
- fully implemented and tested
- implemented but integration test pending
- partially implemented
- UI complete but backend missing
- backend complete but real API not verified

**Files touched:**
- file/path
- file/path

**Files added:**
- file/path

**Files deleted:**
- file/path

**Scratch files cleaned:**
Yes/No

**Tests run:**
Commands and result.

**Next:**
The single next concrete task.

**Blockers/Open Questions:**
Anything unresolved.

**Verify by:**
Exact command, endpoint, or action that verifies the state.
```

### Important rule

`SESSION.md` is not a documentation dump.

Do not copy whole architecture descriptions into it.

It is a handoff note.

---

# 8. LOG.md

## Purpose

`LOG.md` is the **longer chronological development history**.

Unlike `SESSION.md`, which describes the latest handoff, `LOG.md` records the project's development history.

Use it to answer:

> What happened throughout the project?

Suggested format:

```markdown
# Development Log — TiyraSense | SIH 26002

## [DATE] — [AGENT] — Phase X

### Work
- ...

### Files Changed
- ...

### Tests
- ...

### Decisions
- ...

### Problems Found
- ...

### Resolution
- ...

### Result
- ...

### Commit
- ...
```

Newest entries should normally appear at the top, unless the project explicitly chooses chronological order.

For AI efficiency, newest-first is recommended.

---

# 9. Difference Between SESSION.md and LOG.md

Do not duplicate them unnecessarily.

| File | Purpose |
|---|---|
| `SESSION.md` | Latest handoff and immediate next step |
| `LOG.md` | Historical development record |
| `TODO.md` | Current remaining work |
| `DECISIONS.md` | Why technical/product decisions were made |
| `BUILD_GUIDE.md` | How the project is intended to be built |
| `AGENTS.md` | How AI agents must behave |
| `SECURITY.md` | Mandatory security rules |

Example:

### SESSION.md

> Risk engine endpoint implemented but not connected to routing. Next: connect route evaluator.

### LOG.md

> Phase 7 added risk engine, updated API, wrote tests, discovered route scoring needed vehicle constraints.

### TODO.md

> [ ] Integrate risk engine with routing service.

### DECISIONS.md

> Risk score is separate from ML disruption probability because they represent different concepts.

This separation prevents documentation from becoming chaotic.

---

# 10. TODO.md

## Purpose

`TODO.md` is the current project status board.

It should contain:

- completed tasks,
- current phase,
- next tasks,
- blockers,
- deferred tasks,
- backlog.

Suggested structure:

```markdown
# TODO — TiyraSense | SIH 26002

## Phase 0 — Project Setup
- [ ] ...

## Phase 1 — Documentation
- [ ] ...

## Phase 2 — Development Environment
- [ ] ...

## Phase 3 — Database
- [ ] ...

...

## Current Phase
...

## Blockers
...

## Deferred
...

## Backlog
...
```

Keep it concise.

Detailed implementation instructions belong in `BUILD_GUIDE.md` or feature specifications.

---

# 11. DECISIONS.md

## Purpose

`DECISIONS.md` prevents AI agents from repeatedly reopening settled technical decisions.

Uploaded project documentation uses a concise structure:

```markdown
Date:
Decision:
Why:
Alternatives considered / ruled out:
```

Use this same pattern for NER.

Example:

```markdown
### [DATE]

**Decision:**
Flutter for mobile application.

**Why:**
One codebase can target Android and iOS while supporting the project's mobile/offline requirements.

**Alternatives considered / ruled out:**
Native Android-only development was not selected as the primary direction because cross-platform support remains a future requirement.
```

Important decisions to record will include:

- mobile framework,
- web framework,
- backend framework,
- database,
- mapping solution,
- routing engine,
- weather provider,
- government-data strategy,
- ML model family,
- LLM provider,
- image model,
- offline database,
- notification mechanism,
- risk model,
- route optimization philosophy,
- emergency alert behavior,
- authentication architecture,
- deployment strategy.

Do not record every tiny coding choice.

Record choices that future agents might otherwise reconsider.

---

# 12. BUILD_GUIDE.md

## Purpose

`BUILD_GUIDE.md` tells an AI agent:

> What to build, in what order, and what proves each phase is complete?

Every phase should have:

```text
Goal
Prerequisites
Tasks
Files/components expected
Tests
Exit condition
Cleanup
Documentation updates
```

Example:

```markdown
## Phase X — Incident Reporting

### Goal
Drivers and field workers can submit geo-tagged incidents.

### Prerequisites
- Authentication
- Database
- GPS
- Mobile foundation
- Incident schema

### Tasks
1. Build database model.
2. Build API.
3. Build Flutter form.
4. Add photo upload.
5. Add offline queue.
6. Add tests.

### Exit condition
A report can be created online and offline,
stored correctly, synchronized, and displayed on the dashboard.

### Close-out
- update TODO.md
- update SESSION.md
- update LOG.md
- update DECISIONS.md if needed
- clean scratch files
```

---

# 13. SECURITY.md

## Purpose

Security must be applied while writing code, not added at the end.

The uploaded project materials explicitly use this principle: security rules apply from the first implementation phase, with specific rules for SQL, uploads, authentication, secrets, API validation, logging, and scratch files.

For NER, extend this substantially because the project handles:

- location,
- vehicles,
- incident reports,
- photos,
- user identities,
- operational information,
- potentially sensitive government/field information,
- and safety-related predictions.

The file should define:

### Authentication

- authentication method,
- token/session handling,
- role-based access.

### Authorization

- Driver permissions
- Field Worker permissions
- Official permissions
- Admin permissions

Never trust role or user identity supplied directly in a request body.

### Database security

- parameterized queries,
- migrations,
- row-level access where applicable,
- least privilege,
- backend-only service credentials.

### API security

- Pydantic/request validation,
- rate limiting,
- body-size limits,
- CORS,
- generic client errors,
- secure logging.

### File uploads

Validate:

- content signature,
- type,
- size,
- generated filename,
- safe storage location.

### GPS/location data

Define:

- who can see it,
- how long it is retained,
- precision,
- access rules,
- audit behavior.

### AI security

AI outputs are untrusted data.

LLMs must not:

- execute arbitrary instructions from user reports,
- override authorization,
- directly choose safety-critical routes,
- expose secrets,
- or become trusted execution paths.

### Prompt injection

Field reports, images, external text, and other external content must be treated as untrusted.

### Secrets

Never commit:

- API keys,
- tokens,
- database credentials,
- cloud credentials.

### Logs

Never log:

- secrets,
- full tokens,
- unnecessary GPS history,
- full user-uploaded evidence,
- sensitive request contents.

### Dependency security

Pin dependencies when appropriate and periodically review vulnerabilities.

### Scratch-file discipline

Temporary scripts must be deleted once their purpose is complete.

---

# 14. PROJECT_CONTEXT.md

## Purpose

This is the permanent project narrative.

It should contain:

- problem statement,
- why the problem matters,
- product vision,
- users,
- system purpose,
- confirmed decisions,
- safety philosophy,
- geographic scope,
- MVP,
- future scope.

The previously created project-context document should become this file.

Do not repeatedly rewrite it during ordinary coding sessions unless the product itself changes.

---

# 15. REQUIREMENTS.md

Convert the concept into testable requirements.

Requirements should have IDs.

Example:

```text
FR-001
Driver can enter a destination.

FR-002
System calculates candidate routes.

FR-003
System displays current road accessibility.

FR-004
System provides predicted disruption probability.

FR-005
System recommends a safer route.

FR-006
Driver can submit a geo-tagged incident.

FR-007
Incident can be stored offline.

FR-008
Offline incident synchronizes after connectivity returns.
```

Also define:

- non-functional requirements,
- safety requirements,
- performance,
- offline requirements,
- scalability,
- security.

---

# 16. PRODUCT_SPECIFICATION.md

Define exactly what users can do.

Separate by role.

## Driver

- journey planning,
- map,
- route risk,
- accessibility,
- alerts,
- alternate route,
- GPS,
- reporting,
- offline.

## Field Worker

- report,
- photo,
- GPS,
- severity,
- description,
- offline sync.

## Official

- monitor,
- validate,
- predict,
- track,
- emergency operations.

## Admin

- manage users,
- configure platform,
- manage data sources,
- manage system.

---

# 17. USER_ROLES.md

Create explicit permissions.

Example:

```text
DRIVER
READ:
- own journey
- relevant route information
- relevant alerts

WRITE:
- incident reports
- journey location
```

Then define Field Worker, Official, Admin.

The backend must enforce these roles.

The frontend must not be the only place where permissions are enforced.

---

# 18. USER_FLOWS.md

Describe complete user journeys.

Important flows:

```text
Driver plans journey
Driver receives route
Driver begins journey
Incident occurs
Alert generated
Alternative route provided
Driver reports issue

Field worker reports offline
Report synchronizes
Report affects intelligence

Official reviews incident
Official validates incident
Road state changes
Affected vehicles alerted

Emergency incident occurs
Affected zone created
Vehicles identified
Alerts issued
Alternative routes calculated
```

These flows will later become end-to-end tests.

---

# 19. ARCHITECTURE.md

This is the technical master architecture.

It should define:

```text
Flutter
React
Backend
Database
GIS
Routing
Data ingestion
Risk engine
ML
Alert service
Offline sync
Emergency system
```

Include:

- component responsibilities,
- data flow,
- APIs,
- dependencies,
- deployment boundaries.

Do not allow an AI agent to restructure the architecture without a documented decision.

---

# 20. DATA_ARCHITECTURE.md

Describe how data moves:

```text
External Sources
        ↓
Ingestion
        ↓
Validation
        ↓
Normalization
        ↓
Geospatial mapping
        ↓
Reliability scoring
        ↓
Conflict resolution
        ↓
Current state
        ↓
Prediction
        ↓
Risk
        ↓
Routing
        ↓
Alerts
```

Define:

- raw data,
- normalized data,
- processed data,
- historical data,
- prediction data,
- user-generated data.

---

# 21. DATABASE_SCHEMA.md

Define the database before implementation.

Potential entities:

```text
users
roles
vehicles
road_segments
incidents
incident_evidence
weather_observations
traffic_observations
predictions
routes
journeys
alerts
affected_zones
field_reports
sync_records
data_sources
audit_logs
model_versions
```

For every table define:

- columns,
- types,
- nullability,
- defaults,
- primary keys,
- foreign keys,
- indexes,
- geospatial fields,
- constraints.

Use PostGIS concepts where geographic data requires them.

---

# 22. API_SPECIFICATION.md

Define all public/backend interfaces.

Each endpoint should document:

```text
Method
Path
Authentication
Allowed roles
Request
Response
Error responses
Validation
Side effects
```

Example:

```text
POST /api/v1/incidents
```

The AI agent must use the documented API contract rather than inventing new endpoints during implementation.

---

# 23. DATA_SOURCES.md

This is especially important for NER.

Every data source must be researched before integration.

Document:

```text
Provider
Dataset/API
Purpose
Coverage
NER coverage
Update frequency
Historical availability
API limits
Pricing
License
Reliability
Failure behavior
Authentication
Test status
```

Also record:

```text
VERIFIED
PARTIALLY VERIFIED
NOT VERIFIED
UNAVAILABLE
```

Never claim a real-time source exists until it has been tested.

---

# 24. DATA_PIPELINES.md

Define every ingestion process:

```text
Source
 ↓
Fetch
 ↓
Validate
 ↓
Normalize
 ↓
Store raw
 ↓
Transform
 ↓
Store processed
 ↓
Expose to intelligence
```

Document:

- refresh interval,
- retry,
- timeouts,
- stale data,
- source failures,
- duplicate data,
- timestamps,
- fallback providers.

---

# 25. GIS.md

Define:

- map system,
- road network,
- coordinate system,
- road segments,
- incident coordinates,
- geographic zones,
- route geometry,
- overlays,
- offline map/cache strategy.

Important entities:

```text
Road Segment
Incident Point
Route Geometry
Emergency Zone
District
State
```

---

# 26. ROUTING_ENGINE.md

Document how routes are generated and ranked.

The AI agent must never invent routes using language-model reasoning.

Use:

```text
Origin
+
Destination
 ↓
Routing Engine
 ↓
Candidate Routes
 ↓
Accessibility Filter
 ↓
Risk Evaluation
 ↓
Operational Constraints
 ↓
Route Ranking
 ↓
Recommendation
```

Define separately:

### Recommended route

Safety-first.

### Fastest route

Time-first.

The system may display both.

---

# 27. RISK_ENGINE.md

Define the distinction between:

## Current accessibility

```text
OPEN
CAUTION
RESTRICTED
HIGH_RISK
BLOCKED
UNKNOWN
```

## Disruption probability

Example:

> Probability of road disruption within the next 12 hours.

## Route risk

A separate route-level score.

Document exactly how each is calculated.

Do not allow agents to invent arbitrary weights without recording and approving the decision.

---

# 28. CONFLICT_RESOLUTION.md

Document how competing evidence is evaluated.

Consider:

- source reliability,
- recency,
- geographic relevance,
- evidence,
- corroboration,
- environmental consistency,
- historical consistency.

Every important final state should retain supporting evidence and timestamps.

---

# 29. ML_SPECIFICATION.md

Define each model independently.

Initial model categories:

### Disruption prediction

Inputs:

- weather,
- forecast,
- terrain,
- historical disruptions,
- current incidents,
- traffic,
- road condition,
- geographic variables.

Output:

```text
disruption_probability
prediction_horizon
model_version
```

### Travel-time prediction

Define inputs and output.

### Incident classification

Define categories.

### Image analysis

Optional evidence system.

---

# 30. ML_DATASET.md

Define the exact historical dataset.

For example:

```text
road_segment_id
timestamp
weather
rainfall
forecast
terrain
slope
historical_incidents
traffic
road_condition
field_reports
official_reports
future_outcome
```

Most important rule:

> A prediction at time T can only use information that would have been available by T.

This prevents data leakage.

---

# 31. MODEL_EVALUATION.md

Document how model quality is measured.

For disruption prediction:

- precision,
- recall,
- F1,
- calibration,
- false positives,
- false negatives,
- geographic performance,
- seasonal performance.

For travel time:

- MAE,
- RMSE,
- percentage error.

For computer vision:

- precision,
- recall,
- confusion matrix.

Do not call a model reliable merely because it succeeds in one demo scenario.

---

# 32. OFFLINE_SYNC.md

Define the full offline architecture.

Example:

```text
Create report
 ↓
Local database
 ↓
Sync queue
 ↓
Connectivity restored
 ↓
Upload
 ↓
Server acknowledgement
 ↓
Mark synced
```

Define states:

```text
PENDING
SYNCING
SYNCED
FAILED
RETRYING
CONFLICT
```

Also document:

- cached routes,
- relevant alerts,
- recent road status,
- stale-data timestamps,
- retry behavior,
- duplicate handling.

---

# 33. MOBILE_APP.md

Define Flutter architecture.

Example:

```text
mobile/
└── lib/
    ├── core/
    ├── models/
    ├── services/
    ├── repositories/
    ├── database/
    └── features/
        ├── auth/
        ├── home/
        ├── journey/
        ├── map/
        ├── incidents/
        ├── alerts/
        └── profile/
```

Document:

- navigation,
- state management,
- map,
- GPS,
- API,
- local database,
- sync,
- notifications,
- permissions.

---

# 34. WEB_DASHBOARD.md

Define the React + TypeScript dashboard.

Modules:

```text
Dashboard
Live Map
Incidents
Vehicles
Predictions
Alerts
Emergency
Reports
Administration
```

Document:

- role access,
- map,
- real-time updates,
- filters,
- tables,
- analytics,
- incident validation.

---

# 35. TESTING.md

Testing is part of implementation, not a final step.

Define:

### Backend

- unit tests,
- API tests,
- database tests.

### Flutter

- widget tests,
- local DB tests,
- offline tests,
- sync tests.

### React

- component tests,
- role tests,
- API integration.

### ML

- dataset validation,
- model tests,
- evaluation.

### End-to-end

Scenarios:

```text
Normal journey
Heavy rainfall
Risk increase
Field report
Landslide
Road closure
Rerouting
Alert
Offline report
Network restoration
Conflicting reports
Emergency mode
```

---

# 36. DEPLOYMENT.md

Document:

- local development,
- staging,
- production,
- database,
- backend,
- ML serving,
- web hosting,
- mobile builds,
- environment variables,
- backups,
- monitoring.

Start free-first but keep the design upgradeable.

---

# 37. Repository Structure for Actual Code

Recommended starting structure:

```text
sih26002/
│
├── AGENTS.md
├── SESSION.md
├── LOG.md
├── TODO.md
├── DECISIONS.md
├── BUILD_GUIDE.md
├── SECURITY.md
├── README.md
├── .gitignore
├── .env.example
│
├── docs/
│   ├── PROJECT_CONTEXT.md
│   ├── REQUIREMENTS.md
│   ├── PRODUCT_SPECIFICATION.md
│   ├── USER_ROLES.md
│   ├── USER_FLOWS.md
│   ├── ARCHITECTURE.md
│   ├── DATA_ARCHITECTURE.md
│   ├── DATABASE_SCHEMA.md
│   ├── API_SPECIFICATION.md
│   ├── DATA_SOURCES.md
│   ├── DATA_PIPELINES.md
│   ├── GIS.md
│   ├── ROUTING_ENGINE.md
│   ├── RISK_ENGINE.md
│   ├── CONFLICT_RESOLUTION.md
│   ├── ALERT_SYSTEM.md
│   ├── EMERGENCY_MODE.md
│   ├── ML_SPECIFICATION.md
│   ├── ML_DATASET.md
│   ├── MODEL_EVALUATION.md
│   ├── OFFLINE_SYNC.md
│   ├── MOBILE_APP.md
│   ├── WEB_DASHBOARD.md
│   ├── TESTING.md
│   └── DEPLOYMENT.md
│
├── mobile/
├── web/
├── backend/
├── ml/
├── scripts/
├── tests/
└── infrastructure/
```

---

# 38. AI Agent Start Protocol

Every AI agent must follow this process.

## Step 1: Read context

Read:

```text
AGENTS.md
SECURITY.md
SESSION.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
```

Then read only the specifications relevant to the assigned task.

---

## Step 2: Inspect code

Before modifying anything:

```text
Inspect repository structure
Inspect relevant files
Inspect current tests
Inspect recent git changes if useful
```

Do not assume the previous agent implemented something correctly.

---

## Step 3: Determine exact state

Answer:

```text
What already exists?
What is incomplete?
What is stubbed?
What is untested?
What files will need to change?
```

---

## Step 4: Plan

Before coding, provide a concise implementation plan.

Do not produce a giant speculative plan for the entire project.

Plan the assigned feature only.

---

## Step 5: Implement

Follow:

- architecture,
- API contracts,
- database specification,
- security,
- coding conventions.

---

## Step 6: Test

Run relevant tests.

Do not call a feature complete merely because the code compiles.

---

## Step 7: Inspect changes

Check:

```text
git diff
git status
```

Review:

- unexpected files,
- unrelated changes,
- secrets,
- debug statements,
- temporary scripts,
- documentation drift.

---

## Step 8: Update project memory

At the end of every meaningful work session:

1. Update `TODO.md`.
2. Add/update `SESSION.md`.
3. Add an entry to `LOG.md`.
4. Add a `DECISIONS.md` entry if a meaningful decision was made.
5. Update relevant specification documents if behavior changed.
6. Delete scratch files.

The uploaded project workflow specifically uses this close-out discipline and should be adapted directly to NER.

---

# 39. Session Close-Out Template

Every agent should finish its session with a handoff like:

```markdown
# SESSION.md

## [DATE] — [AGENT/MODEL] — Phase X

**Did:**
- Implemented ...
- Updated ...

**State:**
Feature is fully implemented and tested.
OR
Feature is implemented but real API validation remains.

**Files touched:**
- ...
- ...

**Tests:**
- `command` → result

**Scratch files cleaned:**
Yes.

**Next:**
Implement ...

**Blockers/Open Questions:**
...

**Verify by:**
`command`
```

The next AI agent should be able to start from this without asking the previous agent what happened.

---

# 40. How Multiple AI Models Should Work

Different models may work on different areas.

Example:

```text
Agent A
Backend

Agent B
Flutter

Agent C
React

Agent D
ML/Data

Agent E
Testing/Security
```

All agents share:

```text
AGENTS.md
SESSION.md
LOG.md
TODO.md
DECISIONS.md
SECURITY.md
BUILD_GUIDE.md
docs/
```

They do not need the previous model's conversation.

The repository is the shared memory.

---

# 41. Avoid Parallel Changes to the Same Files

Multiple AI agents should not simultaneously edit the same subsystem unless coordinated.

Prefer:

```text
Agent A → backend/risk/
Agent B → mobile/journey/
Agent C → web/incidents/
```

Avoid:

```text
Agent A → ARCHITECTURE.md
Agent B → ARCHITECTURE.md
Agent C → ARCHITECTURE.md
```

without coordination.

If multiple agents need to change a shared document, the agent finishing the feature should update the relevant documentation and record the decision.

---

# 42. Git Workflow

Use Git from the first coding session.

Suggested branches:

```text
main
develop
feature/...
```

For AI agents, feature branches are strongly recommended.

Example:

```text
feature/backend-auth
feature/flutter-map
feature/risk-engine
feature/ml-prediction
feature/offline-sync
```

Do not allow an AI agent to rewrite unrelated history.

---

# 43. Commit Convention

Use:

```text
type(scope): short description
```

Examples:

```text
feat(routing): add route risk evaluation
feat(mobile): add offline incident reports
feat(ml): add disruption prediction inference
fix(sync): retry failed incident uploads
test(risk): add accessibility edge cases
docs(architecture): update route intelligence flow
refactor(api): extract incident service
```

The commit message should describe the actual change.

---

# 44. Scratch File Rule

AI agents frequently create temporary scripts.

Examples:

```text
debug.py
test_api_temp.py
scratch.py
manual_check.py
try_route.py
```

These should not remain indefinitely.

Rule:

> If a file exists only to manually verify something and has no long-term regression value, delete it after verification.

Permanent tests belong in the appropriate test directory.

This rule should be included in both:

- `AGENTS.md`
- `SECURITY.md`

because temporary scripts can accidentally contain secrets or insecure shortcuts.

---

# 45. Documentation Drift Prevention

Whenever code behavior changes, ask:

> Does a specification document now describe something incorrectly?

If yes:

```text
Update code
+
Update documentation
```

Do not allow:

```text
Code says A
Documentation says B
```

This is particularly important for:

- API contracts,
- database schema,
- risk calculations,
- route ranking,
- offline behavior,
- and role permissions.

---

# 46. Decision Workflow

When an AI agent wants to make a meaningful architectural change:

```text
Identify change
      ↓
Check existing decision
      ↓
Check architecture
      ↓
Evaluate alternatives
      ↓
Implement only if justified
      ↓
Record decision
      ↓
Update architecture/specification
```

Example:

> Replace routing provider.

Do not silently make the change.

Create a decision entry explaining:

- why,
- what changed,
- what was rejected,
- migration implications.

---

# 47. Unknown Information Rule

AI agents must explicitly distinguish:

```text
KNOWN
VERIFIED
ASSUMED
SIMULATED
UNKNOWN
```

Example:

```text
Weather API:
VERIFIED

Government road feed:
PARTIALLY VERIFIED

Historical landslide dataset:
UNKNOWN

Development test data:
SIMULATED
```

Never convert an assumption into a fact.

---

# 48. Real-Time API Rule

Before integrating an external service:

```text
Research
 ↓
Read current documentation
 ↓
Verify endpoint
 ↓
Verify NER coverage
 ↓
Verify rate limits
 ↓
Verify pricing
 ↓
Verify license
 ↓
Test request
 ↓
Document result
 ↓
Implement
```

AI coding agents should not invent APIs based on memory.

---

# 49. ML Development Rule

Before connecting an ML model to production route logic:

```text
Dataset exists
 ↓
Features documented
 ↓
Target defined
 ↓
Temporal leakage checked
 ↓
Model trained
 ↓
Validation complete
 ↓
Calibration checked
 ↓
Failure cases examined
 ↓
Model versioned
 ↓
Inference tested
 ↓
Only then integrate
```

Do not use fake probabilities in production paths.

---

# 50. Route Safety Rule

Route recommendation must remain a controlled system.

Correct:

```text
Data
 ↓
Prediction
 ↓
Risk Engine
 ↓
Routing Engine
 ↓
Recommendation
 ↓
LLM explanation
```

Incorrect:

```text
Data
 ↓
LLM
 ↓
"Take this road"
```

The AI coding agent must never silently replace deterministic/routing logic with an LLM.

---

# 51. Data and Model Traceability

Important risk decisions should be traceable.

Store where appropriate:

```text
timestamp
road_segment
data sources
prediction
prediction horizon
model version
confidence
risk score
route recommendation
```

This allows later investigation of:

> Why did the system recommend this route?

---

# 52. Definition of Done

A feature is complete only when:

```text
Requirement exists
       ↓
Design exists
       ↓
Code exists
       ↓
Integration works
       ↓
Error handling exists
       ↓
Security reviewed
       ↓
Tests exist
       ↓
Tests pass
       ↓
Documentation updated
       ↓
Session logged
```

For ML:

```text
Dataset
+
Training
+
Evaluation
+
Inference
+
Monitoring
```

are all part of "done."

---

# 53. Recommended Build Phases

The exact phase numbers may change, but the project should generally follow:

```text
Phase 0
Repository + AI workflow setup

Phase 1
Product/specification completion

Phase 2
Development environment

Phase 3
Database/PostGIS foundation

Phase 4
Backend foundation + authentication

Phase 5
Flutter mobile foundation

Phase 6
React dashboard foundation

Phase 7
GIS/map integration

Phase 8
Routing engine

Phase 9
Real-time data ingestion

Phase 10
Incident/field reporting

Phase 11
Accessibility + conflict resolution

Phase 12
Risk engine

Phase 13
Historical dataset

Phase 14
ML prediction

Phase 15
Risk-aware routing

Phase 16
Vehicle tracking

Phase 17
Alerts

Phase 18
Emergency mode

Phase 19
Offline-first synchronization

Phase 20
End-to-end integration

Phase 21
Testing and validation

Phase 22
Deployment/demo hardening
```

Every phase needs a clear exit condition.

---

# 54. Exit-Condition Discipline

Do not say:

> "The phase is mostly done."

Instead state:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Example:

```text
ML Prediction

Status:
PARTIALLY COMPLETE

Done:
- preprocessing
- training script
- inference endpoint

Not done:
- validation against real NER historical data

Therefore:
Phase is NOT complete.
```

This prevents AI agents from building on unfinished foundations.

---

# 55. AI Agent Handoff Protocol

When an agent starts:

```text
READ
 ↓
INSPECT
 ↓
UNDERSTAND
 ↓
PLAN
 ↓
IMPLEMENT
 ↓
TEST
 ↓
REVIEW
 ↓
DOCUMENT
 ↓
HAND OFF
```

When an agent finishes, the next agent should need only:

```text
AGENTS.md
SESSION.md
TODO.md
DECISIONS.md
relevant specification
```

plus the code itself.

---

# 56. Prompt Template for Starting a Session

Give an AI coding agent a prompt structurally like:

```text
You are working on the SIH 26002 NER Logistics Intelligence Platform.

Before changing anything:

1. Read AGENTS.md.
2. Read SECURITY.md.
3. Read SESSION.md.
4. Read TODO.md.
5. Read DECISIONS.md.
6. Read BUILD_GUIDE.md.
7. Read the specification documents relevant to this task.
8. Inspect the current repository and git status.

Do not code yet.

Determine:
- current project state,
- what is already implemented,
- what this task requires,
- which files must change,
- what tests already exist,
- and any blockers.

Then provide a concise implementation plan.

Do not invent APIs or architectural decisions.
Do not modify unrelated functionality.
Do not use fake data unless explicitly requested and clearly labeled.
Do not let an LLM directly make safety-critical route decisions.
```

---

# 57. Prompt Template for Continuing Previous Work

Use:

```text
Continue the current implementation from the repository state.

Read SESSION.md first.

Do not repeat work that is already complete.

Verify the claimed current state against the code before making changes.

Read:
- AGENTS.md
- SECURITY.md
- SESSION.md
- TODO.md
- DECISIONS.md
- relevant specification documents

Complete only the next concrete task identified by SESSION.md/TODO.md.

Run tests.

At the end:
- update TODO.md,
- update SESSION.md,
- update LOG.md,
- update DECISIONS.md if a meaningful decision was made,
- update documentation if behavior changed,
- clean scratch files.
```

---

# 58. Prompt Template for Review-Only AI

A separate AI model can act as a reviewer rather than a coder.

Use:

```text
Review the current implementation against the project documentation.

Read:
- AGENTS.md
- SECURITY.md
- SESSION.md
- TODO.md
- relevant architecture/specification files

Inspect the code.

Do not modify files.

Find:
1. requirement gaps
2. architecture violations
3. incorrect assumptions
4. security risks
5. missing validation
6. missing tests
7. API inconsistencies
8. database inconsistencies
9. offline failures
10. ML/data problems
11. route-safety problems
12. documentation drift

Separate:
- critical
- high
- medium
- low

Return exact files and recommended fixes.
```

---

# 59. Prompt Template for Final Verification

Before a phase is closed:

```text
Perform a phase-completion audit.

Read:
- AGENTS.md
- SECURITY.md
- BUILD_GUIDE.md
- TODO.md
- SESSION.md
- relevant specifications

Verify:
- all phase requirements
- tests
- error handling
- security
- API behavior
- database behavior
- frontend behavior
- offline behavior if applicable
- documentation
- scratch-file cleanup

Do not modify code.

Return:
- PASS
- FAIL
- PARTIAL

For every failure give:
- file
- issue
- evidence
- required action
```

---

# 60. How to Use Different AI Models

Do not try to make all AI models "own" the project.

Use roles.

Example:

### Primary coding agent

Responsible for implementation.

### Architecture/reviewer model

Responsible for reviewing design.

### ML-focused model

Responsible for dataset/model reasoning.

### Testing model

Responsible for finding edge cases.

### Security review model

Responsible for auditing vulnerabilities.

All models read the same repository memory.

This prevents model-specific conversation history from becoming a hidden dependency.

---

# 61. Recommended AI Ownership Boundaries

Example:

```text
Flutter Agent
→ mobile/

React Agent
→ web/

Backend Agent
→ backend/

ML Agent
→ ml/

Infrastructure Agent
→ infrastructure/

Test Agent
→ tests/ + review

Documentation
→ agent that owns the feature updates relevant docs
```

Shared files:

```text
AGENTS.md
SESSION.md
LOG.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
SECURITY.md
```

must be changed carefully.

---

# 62. Important Rule for Shared Session Memory

Only record **verified state**.

Bad:

> "I think routing should work."

Good:

> "`POST /api/v1/routes/evaluate` returns 200 for the tested sample and all 18 route tests pass."

The purpose of `SESSION.md` is to tell the next agent what is actually true.

---

# 63. Keep Session Entries Short

Do not copy entire git diffs into `SESSION.md`.

Do not paste full logs.

Do not paste every test output.

Use:

```text
Tests:
pytest -q → 48 passed

Files touched:
backend/app/services/risk.py
backend/tests/test_risk.py
```

If detailed historical information is needed, use `LOG.md` or Git history.

---

# 64. Keep LOG.md Useful

The development log should help answer:

> How did this project evolve?

It should capture:

- meaningful milestones,
- important problems,
- decisions,
- architecture changes,
- model changes,
- integration discoveries.

It should not contain meaningless events such as:

> Created file X.

unless the file represents an important milestone.

---

# 65. AI Context Efficiency

Do not force every AI agent to read every document every time.

Use:

### Always read

```text
AGENTS.md
SECURITY.md
SESSION.md
TODO.md
```

### Usually read

```text
DECISIONS.md
BUILD_GUIDE.md
```

### Read for the current task

```text
ARCHITECTURE.md
API_SPECIFICATION.md
DATABASE_SCHEMA.md
...
```

This reduces context usage while preserving consistency.

---

# 66. When an Agent Encounters a Contradiction

Never silently choose.

Example:

`ROUTING_ENGINE.md` says safety-first.

Existing code selects shortest route.

Agent should:

1. identify contradiction,
2. inspect `DECISIONS.md`,
3. determine whether code is stale,
4. report contradiction,
5. make the smallest corrective change if the specification clearly governs,
6. document the result.

If the requirement itself is ambiguous, record it as an open question instead of inventing behavior.

---

# 67. When an Agent Finds a Better Technology

An AI agent may discover a better tool.

It must not silently switch.

It should provide:

```text
Current:
Technology A

Proposed:
Technology B

Benefits:
...

Costs:
...

Migration:
...

Risks:
...

Recommendation:
...
```

Then the decision can be recorded in `DECISIONS.md`.

---

# 68. When an API Becomes Unavailable

Never replace it with a fake API and continue silently.

Instead:

```text
API status:
UNAVAILABLE

Impact:
Weather prediction integration blocked.

Fallback:
Secondary verified provider / development simulation.

Production implication:
Needs validation.
```

This prevents false confidence.

---

# 69. When Data Is Insufficient for ML

The correct response is not:

> "Use a random model and output probabilities."

Instead:

```text
Dataset insufficient
 ↓
Build data collection pipeline
 ↓
Use development/simulated data only where necessary
 ↓
Clearly label it
 ↓
Validate using real historical records
 ↓
Only then promote model
```

---

# 70. Model Versioning

Every deployed prediction model should have:

```text
model_name
model_version
training_dataset_version
training_period
features
metrics
created_at
```

Predictions should reference the model version.

This lets you compare:

```text
Model v1
vs
Model v2
```

without losing historical traceability.

---

# 71. Risk-Engine Versioning

Do the same for route risk calculations.

Example:

```text
risk_engine_version = 1.0
```

A route recommendation should be reproducible using:

- model version,
- risk-engine version,
- relevant evidence,
- timestamp.

---

# 72. Data Source Versioning

Track source configuration.

Example:

```text
weather_provider = X
weather_config_version = 2
```

This matters when an API changes behavior later.

---

# 73. Offline Versioning

The app should know which data snapshot it has locally.

Example:

```text
cached_data_timestamp
road_data_version
alert_sync_timestamp
```

This prevents stale information from being shown as if it were current.

---

# 74. Production-Safety Principle

The platform should distinguish:

```text
Prediction
Observation
Verified Incident
Recommendation
```

Example:

```text
Prediction:
78% disruption probability

Observation:
Driver reports flooding

Verified:
Official confirms blocked road

Recommendation:
Route B
```

Never collapse these concepts into one status without preserving their origin.

---

# 75. Final Pre-Coding Setup Checklist

Before substantial application code is generated:

## Repository

- [ ] Git repository initialized
- [ ] Main branch created
- [ ] `.gitignore`
- [ ] `.env.example`
- [ ] README

## AI Continuity

- [ ] `AGENTS.md`
- [ ] `SESSION.md`
- [ ] `LOG.md`
- [ ] `TODO.md`
- [ ] `DECISIONS.md`
- [ ] `BUILD_GUIDE.md`
- [ ] `SECURITY.md`

## Product Documentation

- [ ] PROJECT_CONTEXT.md
- [ ] REQUIREMENTS.md
- [ ] PRODUCT_SPECIFICATION.md
- [ ] USER_ROLES.md
- [ ] USER_FLOWS.md

## Technical Documentation

- [ ] ARCHITECTURE.md
- [ ] DATA_ARCHITECTURE.md
- [ ] DATABASE_SCHEMA.md
- [ ] API_SPECIFICATION.md

## Intelligence

- [ ] DATA_SOURCES.md
- [ ] DATA_PIPELINES.md
- [ ] GIS.md
- [ ] ROUTING_ENGINE.md
- [ ] RISK_ENGINE.md
- [ ] CONFLICT_RESOLUTION.md
- [ ] ALERT_SYSTEM.md
- [ ] EMERGENCY_MODE.md

## ML

- [ ] ML_SPECIFICATION.md
- [ ] ML_DATASET.md
- [ ] MODEL_EVALUATION.md

## Applications

- [ ] MOBILE_APP.md
- [ ] WEB_DASHBOARD.md
- [ ] OFFLINE_SYNC.md

## Quality

- [ ] TESTING.md
- [ ] DEPLOYMENT.md

---

# 76. First AI-Agent Setup Session

The first agent should **not build the entire app**.

Its first task should be:

```text
1. Inspect repository.
2. Create required directory structure.
3. Create documentation files.
4. Create AGENTS.md.
5. Create SESSION.md.
6. Create LOG.md.
7. Create TODO.md.
8. Create DECISIONS.md.
9. Create BUILD_GUIDE.md.
10. Create SECURITY.md.
11. Create `.env.example`.
12. Configure `.gitignore`.
13. Initialize development environments where appropriate.
14. Verify tooling.
15. Do not implement application features yet.
```

The exit condition is:

> The repository is ready for controlled AI-assisted development.

---

# 77. Second AI-Agent Setup Session

The next agent should focus on specification completion.

Its job:

```text
1. Review project context.
2. Identify unresolved architectural decisions.
3. Research required external technologies/data sources.
4. Update specifications.
5. Record decisions.
6. Do not build the full application.
```

Only after the technical specifications are sufficiently complete should implementation begin.

---

# 78. Third AI-Agent Setup Session

The next step is environment validation:

```text
Flutter
React
TypeScript
Python
PostgreSQL
PostGIS
Docker
Git
ML environment
```

Every tool should be verified before the codebase becomes complicated.

---

# 79. First Actual Feature

The first meaningful product feature should be a thin end-to-end slice.

Example:

```text
Flutter
 ↓
Login
 ↓
Backend
 ↓
Database
 ↓
Response
```

Then progressively:

```text
Destination
 ↓
Routing
 ↓
Map
```

Then:

```text
Weather
 ↓
Risk
 ↓
Route
```

Then:

```text
Incident
 ↓
Risk update
 ↓
Alert
 ↓
Dashboard
```

Then:

```text
Historical data
 ↓
ML
 ↓
Prediction
```

Then:

```text
Prediction
+
Risk
+
Routing
```

This ensures the project remains continuously executable.

---

# 80. Final Multi-Agent Workflow

The complete process should be:

```text
                    PROJECT DOCUMENTATION
                            │
                            ▼
                      AGENTS.md
                            │
                            ▼
                    SESSION / TODO
                            │
                            ▼
                       AI AGENT
                            │
                     inspect repository
                            │
                            ▼
                         PLAN
                            │
                            ▼
                       IMPLEMENT
                            │
                            ▼
                         TEST
                            │
                            ▼
                         REVIEW
                            │
                            ▼
                    UPDATE DOCS/MEMORY
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
       SESSION            LOG             TODO
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
                       NEXT AGENT
```

---

# 81. The Key Principle

The purpose of this setup is not to create many Markdown files for the sake of documentation.

Each file has one job:

```text
AGENTS.md
How the AI must work

SESSION.md
What just happened

LOG.md
What has happened historically

TODO.md
What remains

DECISIONS.md
Why choices were made

BUILD_GUIDE.md
What to build and in what order

SECURITY.md
What must never be compromised

PROJECT_CONTEXT.md
Why the project exists

REQUIREMENTS.md
What the system must do

ARCHITECTURE.md
How the system is structured

Feature specifications
How each subsystem must behave
```

This separation is what allows multiple AI models to work on the same project without relying on a single model's memory.

---

# 82. Final Recommended Project Memory System

For the NER project, the minimum persistent AI memory should be:

```text
                    NER PROJECT MEMORY

                         AGENTS.md
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    SECURITY.md        BUILD_GUIDE.md       DECISIONS.md
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                 ┌─────────────────────┐
                 │     CURRENT STATE   │
                 ├─────────────────────┤
                 │ SESSION.md          │
                 │ TODO.md             │
                 └──────────┬──────────┘
                            ▼
                       LOG.md
                  historical memory
                            │
                            ▼
                    PROJECT DOCUMENTS
                            │
        ┌───────────────────┼────────────────────┐
        ▼                   ▼                    ▼
    Product             Architecture          AI/ML
        │                   │                    │
        ▼                   ▼                    ▼
    Requirements        Database              Models
    User Flows          APIs                  Dataset
    Roles               GIS                   Evaluation
                        Routing
                        Risk
                        Alerts
                        Offline
```

This should become the **standard operating system for AI-assisted development of SIH 26002**.

The individual Markdown specification files should remain separate and detailed. This file, `AI_DEVELOPMENT_SETUP.md`, exists to define **how those files work together and how multiple AI agents use them to build the project consistently**.

---

# 83. Absolute Rules for Every AI Agent

Before modifying the NER repository:

```text
READ THE MEMORY
READ THE SECURITY RULES
READ THE CURRENT STATE
READ THE RELEVANT SPEC
INSPECT THE CODE
PLAN
IMPLEMENT
TEST
REVIEW
UPDATE SESSION
UPDATE TODO
UPDATE LOG
RECORD DECISIONS
CLEAN SCRATCH FILES
```

Never:

```text
Guess
Invent APIs
Fake intelligence
Skip tests
Ignore offline requirements
Bypass security
Rewrite architecture silently
Forget previous work
Claim incomplete work is finished
```

The project succeeds when a new AI model can open the repository tomorrow, read a small set of coordination files, understand exactly where the project stands, identify the next task, and continue development without needing the previous model's conversation history.
