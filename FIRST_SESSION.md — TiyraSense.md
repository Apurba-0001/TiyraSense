# FIRST_SESSION.md — TiyraSense

## Purpose

Use this prompt when starting work with a **new AI agent or a completely new development session**.

The agent must reconstruct the current TiyraSense project state from the repository before making any changes.

---

# TiyraSense New Session Protocol

You are an AI development agent working on **TiyraSense**, SIH 2026 Problem Statement 26002.

You may be working after another AI agent. You do not have access to previous conversations.

**The repository is the source of truth.**

Your first responsibility is to understand the actual current state of the repository before modifying anything.

## 1. Mandatory Reading

Read these files completely:

```text
AGENTS.md
SECURITY.md
SESSION.md
TODO.md
DECISIONS.md
BUILD_GUIDE.md
PROJECT_CONTEXT.md

TiyraSense_7_DAY_SELECTION_SPRINT.md
TiyraSense_SELECTION_ACCEPTANCE_CHECKLIST.md
```

Then read only the relevant specification files under:

```text
docs/
```

for the task you are going to perform.

Do not assume the documentation is correct merely because it says something is complete.

---

# 2. Inspect the Repository

Before coding, inspect:

```text
git status
git branch
git log --oneline -5
```

Then inspect the actual project structure and implementation.

Check:

```text
mobile/
web/
backend/
ml/
scripts/
tests/
infrastructure/
docs/
```

Inspect, where present:

```text
source files
manifests
dependencies
configuration
database migrations
Docker configuration
tests
environment configuration
generated files
```

Do not modify anything during this initial inspection.

---

# 3. Reconstruct the Actual Project State

Compare:

```text
SESSION.md
TODO.md
LOG.md
```

against the actual code and tests.

Determine:

```text
What was previously claimed complete?
What is actually complete?
What is partially implemented?
What is stubbed?
What is broken?
What is untested?
What is missing?
What is blocked?
```

Never report a feature as complete only because `SESSION.md` or `TODO.md` says so.

Verify it against the implementation and relevant tests.

---

# 4. Determine the Current Sprint State

Read:

```text
TiyraSense_7_DAY_SELECTION_SPRINT.md
BUILD_GUIDE.md
TODO.md
SESSION.md
```

Determine:

```text
Current day/phase
Previous completed day/phase
Previous exit condition
Whether that exit condition is actually satisfied
Current task
Next task
Remaining blockers
```

The selection sprint follows:

```text
Day 1 → Foundation
Day 2 → Map + Journey + Routing
Day 3 → Real Data + Accessibility + Risk
Day 4 → Incident Reporting + Conflict Resolution
Day 5 → Alerts + Affected Journeys + Alternate Routing + Emergency Mode
Day 6 → Offline Sync + Official Dashboard
Day 7 → Integration + Testing + Demo Hardening
```

Do not skip an incomplete phase.

Do not implement future sprint days.

---

# 5. Verify Existing Decisions

Read:

```text
DECISIONS.md
```

before making architectural changes.

Do not silently change finalized decisions.

Do not silently resolve open decisions.

Current core rules include:

```text
Safety-first routing
Current Accessibility ≠ Disruption Probability ≠ Route Risk
LLM does not make safety-critical route decisions
Road-segment-centric intelligence
Existing routing engine rather than navigation from scratch
Offline-first mobile operation
LIVE / HISTORICAL / SIMULATED / TEST remain distinguishable
```

---

# 6. Security

Read and follow:

```text
SECURITY.md
```

Do not introduce:

```text
secrets
unauthenticated sensitive endpoints
unsafe uploads
unsafe data handling
insecure authentication shortcuts
production-only bypasses
```

Do not commit credentials or API keys.

---

# 7. Before Coding

Do not start implementation immediately.

First produce this report:

```text
# TiyraSense Session Start Report

## 1. Repository State
[actual repository state]

## 2. Documentation State
[actual documentation state]

## 3. Current Sprint Day
[day/phase]

## 4. Previous Exit Condition
[COMPLETE / PARTIALLY COMPLETE / BLOCKED / NOT STARTED]

Evidence:
[how you verified it]

## 5. Implemented
[verified completed work]

## 6. Partially Implemented
[verified partial work]

## 7. Missing
[missing work]

## 8. Broken / Failing
[known failures]

## 9. Tests
[existing tests and results]

## 10. Open Decisions
[actual unresolved decisions]

## 11. Blockers
[actual blockers]

## 12. Current Task
[the single task that should be worked on now]

## 13. Files Likely to Change
[list]

## 14. Implementation Plan
[concise plan for the current task only]

## 15. Verification Plan
[how completion will be demonstrated]

## 16. Ready to Implement
YES / NO
```

Do not modify files until this report has been produced.

---

# 8. Implementation Rules

Once implementation begins:

1. Work only on the current task.
2. Follow `AGENTS.md`.
3. Follow `SECURITY.md`.
4. Follow `DECISIONS.md`.
5. Follow the relevant specifications.
6. Do not invent external APIs.
7. Do not invent provider capabilities.
8. Do not fabricate real-time data.
9. Do not create fake production intelligence.
10. Do not silently change architecture.
11. Do not modify unrelated functionality.

---

# 9. Testing

After implementation:

```text
Run relevant tests
Verify the feature
Verify integration
Check important failure cases
Check security-sensitive behavior
Inspect changed files
Inspect the diff
Check for secrets
Check for scratch files
Check for unrelated changes
```

A feature is not complete merely because it compiles.

---

# 10. Update Project Memory

At the end of every meaningful session:

### SESSION.md

Record:

- what was actually completed,
- exact files changed,
- files added/deleted,
- tests and results,
- current state,
- blockers,
- one concrete next task,
- exact verification command/action.

### TODO.md

Update the actual status.

### LOG.md

Add a concise historical entry.

### DECISIONS.md

Update only when a meaningful architectural, product, or security decision was made.

### Relevant docs

Update specifications if behavior, contracts, or architecture changed.

Remove all scratch/debug files.

---

# 11. Completion Status

Use only:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Never use:

```text
mostly complete
almost done
probably working
should work
```

---

# 12. Final Session Report

When the work is complete, return:

```text
# Session Completion Report

## Current Sprint Day
...

## Previous Agent State
...

## Actual Verified State
...

## Implemented
...

## Files Changed
...

## Tests Run
...

## Test Results
...

## Exit Condition
COMPLETE / PARTIALLY COMPLETE / BLOCKED

## Remaining Work
...

## Blockers
...

## Next Single Task
...

## Verification
...

READY FOR NEXT AGENT: YES / NO
```

The next AI agent must be able to continue from the repository without access to this conversation.