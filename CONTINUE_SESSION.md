# CONTINUE_SESSION.md — TiyraSense

## Purpose

Use this protocol when continuing an existing TiyraSense implementation with the same or a different AI agent. The previous conversation is not required. The repository, code, tests, and project documentation define the current state.

The agent must reconstruct and verify the actual state before making changes.

---

# TiyraSense Continuation Protocol

Continue the current **TiyraSense** implementation from the repository's actual state.

**Do not assume previous agent claims are correct.** Verify important claims against code, tests, configuration, and documentation.

## 1. Read project memory first

Read the files listed in `AGENTS.md` → "Mandatory reading order (canonical)" in the specified order.

Then read only the specification files under `docs/` relevant to the current task.

## 2. Read the previous handoff

Start with `SESSION.md` and determine:

```text
What the previous agent claimed was completed
What files were changed/added/deleted
What tests were run and their results
What blockers remain
What single next task was identified
```

Verify every important claim against the repository. Treat documentation as project memory, not proof of implementation.

## 3. Inspect the actual repository

Before coding, inspect where applicable:

```text
git status
git branch
git log --oneline -5
source code
project structure
configuration
manifests and dependencies
database migrations
Docker/environment configuration
tests
infrastructure
relevant documentation
```

Do not redo work that is already correctly implemented. Do not modify files during initial inspection unless required for tooling/bootstrap and explicitly justified.

## 4. Reconstruct the actual project state

Compare `SESSION.md`, `TODO.md`, `LOG.md`, and relevant specifications with the implementation and tests.

Classify meaningful work as:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Do not use vague states such as "mostly complete" or "should work".

## 5. Verify the previous exit condition

Determine the previous sprint day/phase and verify its exit condition against the actual implementation and relevant tests.

Do not move forward while a required foundation is incomplete. Do not implement future sprint days merely because they appear in the plan.

## 6. Determine the exact next task

Use:

```text
SESSION.md
TODO.md
BUILD_GUIDE.md
DECISIONS.md
```

to identify one specific, bounded, verifiable task for the current phase. Avoid unrelated improvements and speculative future features.

If no task has been explicitly assigned and the project documentation does not identify an unambiguous current task, stop after the state report rather than inventing work.

## 7. Architecture and decision protection

Before changing architecture, read `DECISIONS.md` and the relevant specification.

Do not silently change `FINALIZED` decisions or silently resolve `OPEN` decisions, including decisions around:

```text
Map/GIS
Routing provider/deployment
Weather provider
Hosting/deployment
Route-risk formula/weights
LLM provider
Other decisions explicitly marked OPEN or FINALIZED
```

If a new meaningful decision is genuinely required:

```text
Research current authoritative information
→ Evaluate viable options
→ Record the decision and rationale
→ Update the affected specification
→ Implement
→ Verify
```

## 8. Documentation freshness and external research

When implementation depends on an external library, SDK, API, model, provider, platform, or changing standard:

1. Verify the current official documentation.
2. Verify compatibility with the versions actually used by the repository.
3. Do not rely on remembered API names, stale examples, or old tutorials.
4. Record durable findings, version information, or compatibility constraints in `DECISIONS.md`, the relevant specification, or the session log when they affect future work.

## 9. Core TiyraSense rules

Preserve the project's existing safety and architecture boundaries:

```text
Safety-first routing
Current Accessibility ≠ Disruption Probability ≠ Route Risk
LLM is explanation-only and does not make safety-critical route decisions
Road-segment-centric intelligence
Use the existing routing engine rather than rebuilding navigation unnecessarily
Offline-first mobile operation
LIVE / HISTORICAL / SIMULATED / TEST data remain distinguishable
```

Never replace controlled routing, accessibility, risk, or safety logic with an LLM.

## 10. Before implementation

First produce:

```text
# TiyraSense Session Start Report

## Repository State
[actual state]

## Documentation State
[actual relevant documentation state]

## Current Sprint Day
[day/phase]

## Previous Agent Claim
[claim]

## Actual Verified State
[verified result]

## Previous Exit Condition
COMPLETE / PARTIALLY COMPLETE / BLOCKED / NOT STARTED

Evidence:
[verification evidence]

## Current Task
[one task]

## Files Likely to Change
[list]

## Implementation Plan
[concise, task-scoped plan]

## Verification Plan
[how completion will be demonstrated]

## Ready to Implement
YES / NO
```

Do not start coding before establishing the actual state. If no valid task exists, stop after this report.

## 11. Implement

Implement only the current task.

Before adding code:

```text
Search for existing implementations, utilities, components, services, schemas, and tests.
Reuse correct existing functionality.
Avoid duplicate helpers and parallel implementations.
```

During implementation:

```text
Preserve working behavior.
Follow AGENTS.md.
Follow SECURITY.md.
Follow DECISIONS.md.
Follow relevant specifications.
Use meaningful names and readable structure.
Keep changes minimal and focused.
Do not invent APIs or provider capabilities.
Do not fabricate real-time data or production intelligence.
Do not modify unrelated functionality.
```

## 12. Test and verify

After implementation, run relevant checks, which may include:

```text
Unit tests
Integration/API tests
Type/lint/static checks
Database/migration validation
Actual application path where practical
Important failure cases
Security-sensitive cases
Regression checks for affected behavior
```

Do not mark a feature complete only because it compiles.

Record what was actually run and whether it passed, failed, or was not run.

## 13. Review the changes

Before ending the session, inspect:

```text
git diff
git status
```

Check for:

```text
unexpected files
unrelated changes
duplicate code
obsolete code left behind
secrets or credentials
debug code
scratch/temp files
generated artifacts that should not be committed
documentation drift
broken existing functionality
```

Remove scratch/debug files unless they are intentionally part of the project.

## 14. Update project memory

When the work is genuinely complete:

### `SESSION.md`
Record:

```text
What was actually completed
Exact files changed/added/deleted
Tests/checks run and results
Current verified state
Blockers
One concrete next task
Exact verification command/action
```

### `TODO.md`
Update the real task status. Do not leave stale completion markers.

### `LOG.md`
Add a concise historical entry describing the meaningful work, verification, and result. Preserve previous history.

### `DECISIONS.md`
Update only when a meaningful architectural, product, security, dependency, or provider decision was made.

### Relevant `docs/`
Update specifications when requirements, behavior, API/database contracts, security boundaries, or architecture changed.

## 15. Do not continue automatically

When the current task is complete, do not automatically implement the next sprint day. Stop at the current exit condition and hand off the next single task.

## 16. Final session report

Return:

```text
# Session Completion Report

## Current Sprint Day
...

## Previous Agent Claim
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

The repository must contain enough accurate information for another AI agent to continue without access to this conversation.
