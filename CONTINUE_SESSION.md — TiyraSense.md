# CONTINUE_SESSION.md — TiyraSense

## Purpose

Use this prompt when **continuing an existing TiyraSense implementation** with the same or a different AI agent.

The previous agent's conversation is not required.

The agent must reconstruct and verify the current state from the repository, then continue only the next valid task.

---

# TiyraSense Continuation Protocol

Continue the current **TiyraSense** implementation from the repository's actual state.

You are continuing work performed by a previous AI agent.

You do not have access to the previous conversation.

**Do not assume the previous agent's claims are correct.**

The repository, code, tests, and project documentation together define the current state.

---

# 1. Read Project Memory First

Read:

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

Then read the relevant specifications under:

```text
docs/
```

for the current task.

---

# 2. Read the Previous Handoff

Start with:

```text
SESSION.md
```

Determine:

```text
What did the previous agent say it completed?
What files did it change?
What tests did it run?
What blockers did it report?
What did it identify as the next task?
```

Then verify every important claim against the repository.

---

# 3. Inspect the Actual Repository

Run and inspect:

```text
git status
git branch
git log --oneline -5
```

Then inspect the relevant implementation.

Check:

```text
source code
configuration
dependencies
database migrations
tests
Docker configuration
environment configuration
documentation
```

Do not redo work that is already correctly implemented.

Do not assume a feature is complete because `SESSION.md`, `TODO.md`, or `LOG.md` says so.

---

# 4. Verify the Previous Exit Condition

Determine the previous sprint day/phase.

Then verify its exit condition against the actual implementation.

Use:

```text
COMPLETE
PARTIALLY COMPLETE
BLOCKED
NOT STARTED
```

Do not move forward while the required previous foundation is incomplete.

---

# 5. Determine the Exact Next Task

Use:

```text
SESSION.md
TODO.md
BUILD_GUIDE.md
TiyraSense_7_DAY_SELECTION_SPRINT.md
DECISIONS.md
```

to determine the next task.

The next task must be:

```text
specific
small enough for the session
connected to the current sprint phase
verifiable
```

Do not expand the task into unrelated future features.

---

# 6. Architecture and Decision Protection

Before changing architecture:

```text
Read DECISIONS.md
Read relevant architecture specification
```

Do not silently change finalized decisions.

Do not silently resolve:

```text
Map/GIS provider
Routing provider/deployment
Weather provider
Hosting/deployment
Route-risk formula/weights
LLM provider
```

unless the repository shows that these have already been formally decided.

If a new meaningful decision is required:

```text
Research
→ Evaluate
→ Record decision
→ Update relevant specification
→ Implement
```

---

# 7. Core TiyraSense Rules

Preserve:

```text
Safety-first routing
Current Accessibility ≠ Disruption Probability ≠ Route Risk
LLM does not make safety-critical route decisions
Road-segment-centric intelligence
Existing routing engine
Offline-first mobile operation
LIVE / HISTORICAL / SIMULATED / TEST distinction
```

Never replace controlled routing/risk logic with an LLM.

---

# 8. Before Implementation

First report:

```text
CURRENT SPRINT DAY

PREVIOUS AGENT CLAIM

ACTUAL VERIFIED STATE

PREVIOUS EXIT CONDITION

CURRENT TASK

FILES TO CHANGE

IMPLEMENTATION PLAN

TEST PLAN
```

Keep the implementation plan limited to the current task.

Do not start coding before establishing the actual state.

---

# 9. Implement

After state verification:

1. Implement only the current task.
2. Preserve existing working functionality.
3. Follow `AGENTS.md`.
4. Follow `SECURITY.md`.
5. Follow `DECISIONS.md`.
6. Follow relevant specifications.
7. Do not invent APIs.
8. Do not fabricate real-time data.
9. Do not introduce fake production intelligence.
10. Do not modify unrelated files.

---

# 10. Test

After implementation:

```text
Run relevant unit tests
Run relevant integration/API tests
Run the actual application path where practical
Test important failure cases
Verify security-sensitive behavior
Verify the previous functionality still works
```

Do not mark completion solely because the code compiles.

---

# 11. Review the Changes

Before ending the session:

Check:

```text
git diff
git status
```

Review for:

```text
unexpected files
unrelated changes
secrets
debug code
temporary files
documentation drift
broken existing functionality
```

Remove scratch/debug files.

---

# 12. Update Project Memory

When the work is genuinely complete:

## SESSION.md

Update:

```text
What was completed
Exact files changed
Files added/deleted
Tests and results
Current state
Blockers
Next single task
Verification method
```

## TODO.md

Update the actual project state.

## LOG.md

Add a concise historical entry.

## DECISIONS.md

Update only if a meaningful decision was made.

## Relevant docs

Update if implementation changed:

```text
requirements
behavior
API contracts
database contracts
architecture
```

---

# 13. Do Not Continue Automatically

When the current task is complete:

Do not automatically implement the next sprint day.

Stop after the current task and report the handoff state.

---

# 14. Final Session Report

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

The repository must contain enough information for another AI agent to continue without access to this conversation.