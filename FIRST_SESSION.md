# FIRST_SESSION.md — TiyraSense

## Purpose

Use this protocol when starting work with a new AI agent or a completely new development session.

The agent must reconstruct the current TiyraSense project state from the repository before modifying anything.

---

# TiyraSense First Session Protocol

You are an AI development agent working on **TiyraSense**, SIH 2026 Problem Statement 26002.

You may be working after another AI agent. You do not have access to previous conversations.

**The repository is the source of truth.** Documentation provides project memory, but implementation and tests must be used to verify important claims.

## 1. Mandatory reading

Read the files listed in `AGENTS.md` → "Mandatory reading order (canonical)" in the specified order.

Then read only the relevant specification files under `docs/` for the task you are going to perform.

Do not assume documentation is correct merely because it says something is complete.

## 2. Initial repository inspection

Before coding, inspect:

```text
git status
git branch
git log --oneline -5
```

Then inspect the actual project structure and relevant implementation, including where present:

```text
mobile/
web/
backend/
ml/
scripts/
tests/
docs/
source files
manifests and dependencies
configuration
database migrations
Docker/environment configuration
generated files
```

Do not modify implementation during this initial inspection unless a tooling/bootstrap action is required and clearly documented.

## 3. Reconstruct the actual project state

Compare:

```text
SESSION.md
TODO.md
LOG.md
```

with the actual code, configuration, tests, and relevant specifications.

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

Use only:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Never report a feature as complete only because documentation says so.

## 4. Determine the current project state

Read:

```text
BUILD_GUIDE.md
TODO.md
SESSION.md
```

Determine:

```text
Current day/phase
Previous completed day/phase
Previous exit condition
Whether the previous exit condition is actually satisfied
Current task
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

Do not skip an incomplete phase or implement future sprint days simply because they are planned.

## 5. Verify existing decisions

Read `DECISIONS.md` before making architectural changes.

Do not silently change finalized decisions or silently resolve open decisions.

Protect the established boundaries:

```text
Safety-first routing
Current Accessibility ≠ Disruption Probability ≠ Route Risk
LLM does not make safety-critical route decisions
Road-segment-centric intelligence
Existing routing engine rather than navigation from scratch
Offline-first mobile operation
LIVE / HISTORICAL / SIMULATED / TEST remain distinguishable
```

If a new meaningful decision is required:

```text
Research current authoritative sources
→ Evaluate options
→ Record rationale and decision status
→ Update relevant specification
→ Implement
→ Verify
```

## 6. Documentation freshness and external research

Before implementing anything that depends on an external library, SDK, API, model, provider, platform behavior, or changing standard:

```text
Check current official documentation.
Check the repository's installed/version-pinned dependency where applicable.
Confirm API compatibility and relevant breaking changes.
Do not use stale examples or remembered APIs as authority.
Record durable compatibility findings where they affect future work.
```

## 7. Security

Read and follow `SECURITY.md` for all implementation work.

At minimum, do not introduce:

```text
hardcoded secrets or API keys
unauthenticated sensitive endpoints
unsafe uploads
unsafe data handling
insecure authentication shortcuts
production-only bypasses
unsafe logging of secrets or sensitive location data
```

Apply security requirements during implementation, not only at release time.

## 8. Before coding: session start report

Do not start implementation immediately. First produce:

```text
# TiyraSense Session Start Report

## 1. Repository State
[actual repository state]

## 2. Documentation State
[actual documentation state]

## 3. Current Sprint Day
[day/phase]

## 4. Previous Exit Condition
COMPLETE / PARTIALLY COMPLETE / BLOCKED / NOT STARTED

Evidence:
[how it was verified]

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

Do not modify implementation files until this report has been produced. If no task is explicitly assigned and the current task cannot be determined unambiguously, stop after the report rather than inventing work.

## 9. Implementation rules

Once implementation begins:

1. Work only on the current task.
2. Search for and reuse existing implementations before adding new helpers, components, services, or utilities.
3. Avoid redundant or duplicate code.
4. Follow `AGENTS.md`.
5. Follow `SECURITY.md`.
6. Follow `DECISIONS.md`.
7. Follow the relevant specifications.
8. Do not invent external APIs or provider capabilities.
9. Do not fabricate real-time data or fake production intelligence.
10. Do not silently change architecture.
11. Do not modify unrelated functionality.
12. Prefer meaningful variable/function names and readable code over compressed or clever code.
13. Keep the change set minimal and easy to review.

## 10. Testing and verification

After implementation:

```text
Run relevant unit tests
Run relevant integration/API tests
Run type/lint/static checks where available
Verify the actual application path where practical
Check important failure cases
Check security-sensitive behavior
Check affected existing functionality for regressions
Inspect the diff and status
```

A feature is not complete merely because it compiles.

Record exactly what was run and the result.

## 11. Update project memory

At the end of every meaningful session:

### `SESSION.md`
Record:

```text
what was actually completed
exact files changed/added/deleted
tests/checks and results
current verified state
blockers
one concrete next task
exact verification command/action
```

### `TODO.md`
Update actual status and remove stale claims.

### `LOG.md`
Add a concise historical entry. Preserve prior history.

### `DECISIONS.md`
Update only when a meaningful architectural, product, security, provider, or dependency decision was made.

### Relevant docs
Update specifications when requirements, behavior, contracts, security boundaries, or architecture changed.

Remove scratch/debug files that are not intentionally part of the project.

## 12. Completion status

Use only:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Never use vague completion terms such as:

```text
mostly complete
almost done
probably working
should work
```

## 13. Final session report

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
COMPLETE / PARTIALLY COMPLETE / BLOCKED / NOT STARTED

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
