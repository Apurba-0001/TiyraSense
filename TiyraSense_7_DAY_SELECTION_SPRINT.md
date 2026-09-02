# TiyraSense — 7-Day Selection Sprint Plan

## Purpose

This is the execution plan for the **65–75% selection-stage build** of TiyraSense.

The goal is not to implement 65–75% of every subsystem. The goal is to implement approximately 65–75% of the **judge-visible core operational workflow** as one continuously executable, testable system.

The selection-stage system must demonstrate:

```text
Driver
→ Destination
→ Map
→ Candidate Routes
→ Current Accessibility
→ Weather
→ Route Risk
→ Safer Recommendation
→ Journey
→ Incident / Field Report
→ Evidence Processing
→ Accessibility / Risk Update
→ Affected User Detection
→ Targeted Alert
→ Alternate Route
→ Official Dashboard Update
→ Offline Report Sync
```

## Source of Truth

This sprint plan is a temporary execution priority. It does not replace:

- `PROJECT_CONTEXT.md`
- `AGENTS.md`
- `SECURITY.md`
- `DECISIONS.md`
- `BUILD_GUIDE.md`
- detailed documents under `docs/`

Permanent architecture decisions remain in the project documentation.

## Selection Goal

By the end of Day 7, the system should have one reliable end-to-end demonstration path.

The strongest demonstration is:

```text
A driver starts a logistics journey.
        ↓
The system shows candidate routes.
        ↓
TiyraSense evaluates current conditions and route risk.
        ↓
A safer route is recommended.
        ↓
Weather/risk conditions worsen.
        ↓
A driver or field worker submits a landslide report.
        ↓
The report is validated and linked to a road segment.
        ↓
The road accessibility/risk assessment changes.
        ↓
The system identifies affected journeys/users.
        ↓
A targeted alert is issued.
        ↓
An alternate route is generated.
        ↓
The driver sees the new recommendation.
        ↓
The official dashboard updates.
        ↓
An offline report can synchronize when connectivity returns.
```

## Delivery Rules

1. Work in the listed order.
2. Do not start a later day while the previous day's exit condition is failing.
3. Build one thin vertical slice first, then expand it.
4. Prefer a small working implementation over broad unfinished modules.
5. Do not invent external APIs or claim unverified providers are production-ready.
6. Clearly label simulated/test data.
7. Do not use an LLM to make the safety-critical route decision.
8. Do not build advanced ML before the core system works end-to-end.
9. Do not spend selection-sprint time on deferred features.
10. Every completed day must leave the repository runnable.

---

# Day 0 — Documentation Freeze and Repository Audit

## Goal

Make the project ready for linear implementation.

## Tasks

- Read `AGENTS.md`
- Read `SECURITY.md`
- Read `SESSION.md`
- Read `TODO.md`
- Read `DECISIONS.md`
- Read `BUILD_GUIDE.md`
- Read relevant `docs/` specifications
- Inspect repository structure
- Inspect installed tool versions
- Check Git status
- Confirm application directories and current code state
- Identify missing `docs/` specifications needed immediately by implementation

## Output

A concise repository audit and a confirmed implementation sequence.

## Exit Condition

The agent can answer:

- what exists,
- what is missing,
- what will be built next,
- what provider decisions are already finalized,
- what remains open.

No application feature work starts before this is understood.

---

# Day 1 — Working Foundation

## Goal

Get the three main layers running and communicating.

```text
Flutter
  ↓
Backend API
  ↓
PostgreSQL/PostGIS
```

and:

```text
React Web
  ↓
Backend API
```

## Priority

### Backend

- project structure
- configuration
- database connection
- health endpoint
- authentication foundation
- user/role model
- basic API error handling

### Mobile

- Flutter project
- app shell
- login
- role-aware navigation
- driver home
- field-worker home

### Web

- React + TypeScript project
- login
- authenticated shell
- official dashboard shell
- admin shell

### Database

Start only with the minimal entities needed for the vertical slice.

## Exit Condition

A real request can travel through:

```text
Flutter
→ Backend
→ PostgreSQL
→ Backend
→ Flutter
```

and:

```text
React
→ Backend
→ PostgreSQL
→ React
```

Authentication and role boundaries work server-side.

---

# Day 2 — Journey, Map, and Routing

## Goal

Create the first visible TiyraSense journey experience.

## Tasks

### Driver

- current location
- destination selection
- interactive map
- route generation
- route display
- route summary

### Routing

Use an existing routing engine.

Do not build pathfinding from scratch.

Generate at least two candidate routes where the selected routing setup supports this.

Show:

```text
Route
ETA
Distance
```

Then introduce TiyraSense fields:

```text
Current Accessibility
Route Risk
Disruption Probability
```

These may initially be clearly labeled prototype values if real intelligence is not yet available.

## Exit Condition

A driver can:

```text
Login
→ Select destination
→ See map
→ Generate route(s)
→ Inspect route information
```

---

# Day 3 — Real Data and Risk Engine v0

## Goal

Make route selection meaningfully different from normal navigation.

## Tasks

Connect the first verified external data sources.

Priority:

1. Weather
2. GIS/map context
3. Any verified road/official information available for the pilot geography

Normalize the data into the road-segment-centric model.

Implement a documented **rule-based Risk Engine v0**.

Keep separate:

```text
Current Accessibility
Disruption Probability
Route Risk
```

For the selection build:

- rule-based risk may be used temporarily,
- it must be explicitly labeled as a prototype,
- no fake probability should be presented as validated ML.

## Example

```text
Route A
ETA: 5h20m
Accessibility: CAUTION
Risk: HIGH

Route B
ETA: 6h05m
Accessibility: OPEN
Risk: LOW

Recommended: Route B
Fastest: Route A
```

## Exit Condition

Changing route conditions can change the displayed risk and recommendation.

The route recommendation is produced by controlled logic, not by an LLM.

---

# Day 4 — Field Reporting and Conflict Resolution

## Goal

Demonstrate ground-level intelligence entering the platform.

## Tasks

### Driver / Field Worker

Incident form:

```text
GPS
Incident Type
Severity
Description
Photo
Timestamp
```

### Backend

```text
Report
→ Validate
→ Map to road segment
→ Evaluate evidence
→ Update incident state
→ Recalculate accessibility
→ Recalculate route risk
```

### Conflict Resolution

Support multiple observations.

Example:

```text
Official source
→ OPEN

Field report
→ LANDSLIDE

Weather
→ HEAVY RAIN

Historical context
→ HIGH SUSCEPTIBILITY
```

Produce an explainable operational assessment.

The exact weights do not need to be production-grade during the selection sprint, but the architecture must preserve:

- source,
- timestamp,
- evidence,
- confidence/reliability,
- current state,
- reason for the resulting assessment.

## Exit Condition

A new incident can visibly change the relevant road's operational state.

---

# Day 5 — Alerts, Affected Journeys, Alternate Routing, Emergency Flow

## Goal

Create the central "TiyraSense is useful" moment.

## Tasks

When a high-severity incident affects a road:

```text
Incident
→ Affected Road
→ Affected Journey
→ Targeted Alert
→ Route Re-evaluation
→ Alternate Route
```

### Driver

Show:

- alert
- affected road
- approximate distance/position when appropriate
- current accessibility
- risk change
- recommended alternative

### Official

Show:

- active incident
- affected road
- affected journey/vehicle/user
- alert status
- updated route/risk

## Exit Condition

The complete incident-to-alert-to-reroute chain works in one environment.

This is the highest-priority selection-sprint capability.

---

# Day 6 — Offline Reporting and Dashboard Completion

## Goal

Demonstrate that the system works under NER connectivity constraints and that officials get an operational view.

## Offline

Implement the minimum reliable flow:

```text
Offline
→ Create report
→ Local storage
→ PENDING
→ Connectivity restored
→ SYNCING
→ Backend
→ SYNCED
```

Also retain, where practical:

- current/active journey
- latest known route information
- relevant alerts
- relevant recent incident information

Every cached item needs a timestamp.

Do not display stale information as current.

## Official Dashboard

Complete the selection-stage operational view:

```text
Regional / pilot map
Incidents
Road accessibility
Risk
Vehicles / journeys
Alerts
Emergency area
```

## Exit Condition

A report can be created without network access and later synchronized successfully.

The official dashboard reflects the latest incident/risk state.

---

# Day 7 — Integration, Reliability, Demo Hardening

## Goal

Stop expanding scope and make the existing slice reliable.

## Run the complete scenario

```text
1. Login as driver
2. Choose destination
3. Generate routes
4. Compare risk
5. See safer recommendation
6. Start journey
7. Introduce worsening weather/risk
8. Submit landslide incident
9. Process evidence
10. Change road accessibility
11. Recalculate route risk
12. Detect affected journey
13. Issue targeted alert
14. Generate alternate route
15. Display updated recommendation
16. View official dashboard update
17. Demonstrate offline report
18. Restore connectivity
19. Synchronize report
20. Verify final state
```

## Reliability checks

Test at least:

- normal network
- weak network
- no network
- reconnect after offline report
- invalid incident data
- duplicate report
- conflicting reports
- inaccessible road
- route with no safe alternative
- failed external data request
- expired/stale cached information
- unauthorized role access

## Demo hardening

Remove:

- debug UI
- fake-looking placeholders
- dead buttons
- broken navigation
- accidental test routes
- hard-coded road decisions
- misleading "AI" labels
- false claims of ML accuracy

Clearly label:

```text
LIVE
HISTORICAL
SIMULATED
TEST
PROTOTYPE
```

## Exit Condition

The complete selection scenario can be demonstrated repeatedly without manual database edits or code changes during the demo.

---

# What Counts Toward the 65–75%

## Must Be Working

```text
✓ Driver application
✓ Field-worker reporting
✓ Official dashboard
✓ Authentication/RBAC
✓ Database
✓ Map
✓ Destination
✓ Routing
✓ Current accessibility
✓ Weather
✓ Route risk
✓ Safety-first recommendation
✓ Incident processing
✓ Conflict resolution
✓ Targeted alert
✓ Alternate route
✓ Affected journey detection
✓ Emergency flow
✓ Basic offline incident queue
✓ End-to-end integration
```

## Can Be Prototype-Level

```text
~ Rule-based risk engine
~ Initial source-reliability scoring
~ Limited pilot geography
~ Simulated historical data
~ Basic vehicle tracking
~ Basic notification delivery
```

These must be explicitly labeled and not presented as validated production intelligence.

## Stretch Goal

```text
Real disruption-prediction ML model
```

A small validated proof of concept is useful if the core system is already stable.

## Deferred

```text
Advanced computer vision
Multiple vehicle classes
Full NER-wide deployment
Advanced supply-chain analytics
Infrastructure planning
Large-scale production optimization
```

---

# Linear Agent Handoff Protocol

Every agent must follow:

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

Before starting a day:

1. Read `SESSION.md`.
2. Read `TODO.md`.
3. Read the relevant specification.
4. Inspect the actual code.
5. Confirm the previous day's exit condition.

At the end of a day:

1. Run tests.
2. Inspect changed files.
3. Update `SESSION.md`.
4. Update `TODO.md`.
5. Update `LOG.md`.
6. Update `DECISIONS.md` if a meaningful decision was made.
7. Update relevant specs if behavior changed.
8. Remove scratch files.

Never claim a day is complete when its exit condition is not met.

---

# Agent Ownership

Use one agent at a time for the main linear path unless work is explicitly isolated.

Recommended sequence:

```text
Agent 1 → Day 0–1 foundation
Agent 2 → Day 2 journey/map/routing
Agent 3 → Day 3 data/risk
Agent 4 → Day 4 incidents/conflict
Agent 5 → Day 5 alerts/emergency/rerouting
Agent 6 → Day 6 offline/dashboard
Agent 7 → Day 7 integration/review
```

An agent may continue across multiple days if it remains the most efficient choice.

Avoid simultaneous edits to shared architecture and coordination files.

---

# Stop Conditions

Stop feature expansion immediately when:

- a core path is broken,
- authentication is broken,
- database state is unreliable,
- routing is unreliable,
- current-risk logic is inconsistent,
- incidents cannot be trusted,
- alerts target the wrong users,
- offline synchronization loses data,
- tests are failing in the core path.

Fix the foundation before adding more features.

---

# Post-Selection Continuation

After internal selection, the project continues from the repository state.

The next work should focus on:

```text
Selection Build
→ Production-grade data pipelines
→ Better conflict resolution
→ Historical dataset
→ Validated ML prediction
→ Risk-aware route optimization
→ Stronger offline sync
→ More vehicle types
→ Broader NER coverage
→ Advanced alerting
→ Security hardening
→ Monitoring
→ Deployment
→ Production validation
```

The selection build is a working vertical slice, not the finished product.
