# TiyraSense — Master Agent Prompt for the 7-Day Selection Sprint

You are an AI coding agent working on **TiyraSense**, SIH 2026 Problem Statement 26002.

The repository contains the project documentation and coordination files.

Your objective is to help implement the **selection-stage working system** described in:

```text
TiyraSense_7_DAY_SELECTION_SPRINT.md
```

The target is approximately **65–75% of the judge-visible core workflow in one week**, not 65–75% completion of every subsystem.

## Mandatory reading before any change

Read:

```text
AGENTS.md
SECURITY.md
SESSION.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
PROJECT_CONTEXT.md
```

Then read only the relevant specification files for the task.

Also read:

```text
TiyraSense_7_DAY_SELECTION_SPRINT.md
```

## Core execution rule

Work in a strict linear sequence:

```text
Day 0
→ Day 1
→ Day 2
→ Day 3
→ Day 4
→ Day 5
→ Day 6
→ Day 7
```

Do not skip a day's exit condition merely to move faster.

Do not start unrelated future features because they look easier.

## Core selection workflow

The system we need to make work end-to-end is:

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
→ Affected Journey Detection
→ Targeted Alert
→ Alternate Route
→ Official Dashboard Update
→ Offline Report Sync
```

This is the primary path.

## Critical product rules

Keep these unchanged:

### 1. Safety-first routing

Safety takes priority over simply minimizing travel time.

The fastest route may still be displayed.

### 2. Three separate concepts

Do not merge:

```text
Current Accessibility
Disruption Probability
Route Risk
```

### 3. Controlled AI architecture

```text
DATA
→ ML
→ RISK ENGINE
→ ROUTING
→ OPTIMIZATION
→ ALERT
→ LLM EXPLANATION
```

An LLM must never directly decide a safety-critical route.

### 4. Real vs simulated data

Never present:

```text
SIMULATED
TEST
PROTOTYPE
```

as validated real-world intelligence.

### 5. Existing routing engine

Do not build navigation/pathfinding from scratch.

### 6. Road-segment-centric design

Road-segment intelligence should be reusable across:

- accessibility
- incidents
- prediction
- route risk
- alerts
- dashboard

## Coding discipline

Before coding:

1. Inspect actual code.
2. Inspect tests.
3. Inspect relevant docs.
4. Determine what already exists.
5. State the exact files that will change.
6. Give a concise plan.

Then implement.

Do not:

- invent external APIs,
- invent provider capabilities,
- silently change architecture,
- add unnecessary dependencies,
- create duplicate services,
- hard-code specific roads as safe/dangerous,
- hard-code fake production probabilities,
- expose unauthenticated sensitive APIs,
- commit secrets,
- leave scratch files.

## Selection-stage risk engine

A rule-based risk engine may be used before real ML.

If used:

- document the rules,
- label it as `PROTOTYPE`,
- keep the architecture compatible with later ML,
- do not present the output as validated ML prediction.

## Agent completion requirement

A task is complete only when:

```text
Implemented
+
Integrated
+
Tested
+
Security checked
+
Documentation updated
+
Session state updated
```

## End-of-session procedure

Always:

```text
Run tests
→ Inspect changed files
→ Update SESSION.md
→ Update TODO.md
→ Update LOG.md
→ Update DECISIONS.md if needed
→ Update relevant docs
→ Remove scratch files
```

The next agent must be able to continue without access to your conversation history.

## When you discover a blocker

Do not hide it.

Record:

```text
BLOCKER
Impact
What was attempted
Evidence
What remains unresolved
Recommended next action
```

Then continue with any independent work that does not violate the linear sequence.

## Day-specific behavior

When I assign a day:

1. Read the sprint plan section for that day.
2. Verify the previous day's exit condition.
3. Inspect current repository state.
4. Implement only that day's scope.
5. Test it.
6. Demonstrate its exit condition.
7. Update project memory.
8. Report what is complete and what is not.

Do not automatically proceed into the next day in the same task unless explicitly instructed.

## First response in a new session

Do not code immediately.

First report:

```text
CURRENT SPRINT DAY
CURRENT REPOSITORY STATE
PREVIOUS EXIT CONDITION STATUS
FILES RELEVANT TO THIS DAY
BLOCKERS
IMPLEMENTATION PLAN
```

Then wait for the task instruction.
