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

## Document authority

Different kinds of truth live in different files. When documents appear to disagree, resolve the disagreement using this hierarchy rather than guessing:

- **User-approved requirements** (what a human has explicitly asked for in the current task) are the highest authority for requested product behavior.
- **`AGENTS.md`** (this file) is authoritative for project-wide agent, implementation, architecture, and coding rules.
- **`SECURITY.md`** is authoritative for security requirements.
- **`DECISIONS.md`** is authoritative for finalized architectural and other durable project decisions. A decision is only binding once its record says **FINALIZED**.
- **`PROJECT_CONTEXT.md`** is authoritative for permanent product context — what TiyraSense is and why.
- **`BUILD_GUIDE.md`** defines the long-term development phase sequence.
- **`TiyraSense_7_DAY_SELECTION_SPRINT.md`** defines day-to-day execution priority while the selection sprint is active.
- **`SESSION.md`** describes the current handoff and state — not durable rules.
- **`TODO.md`** describes the current work board and status — not durable rules.
- **`LOG.md`** records historical development events for reference — it does not authorize future work.
- **Code** represents the implementation that actually exists. Code is evidence of what was built, not proof that an undocumented architectural decision was approved.
- Relevant files under **`docs/`** define detailed specifications for the areas they cover, once written.

Status files (`SESSION.md`, `TODO.md`, `LOG.md`) never override a FINALIZED decision in `DECISIONS.md`, and they never substitute for reading `AGENTS.md` or `SECURITY.md`. If a status file's stated progress implies an architectural change that `DECISIONS.md` has not recorded, treat `DECISIONS.md` as controlling and flag the discrepancy per "If a previous agent violated these rules" below.

## Mandatory reading order (canonical)

This is the single authoritative reading order. Other files (`FIRST_SESSION.md`, `CONTINUE_SESSION.md`, `TiyraSense_MASTER_AGENT_PROMPT.md`) reference this list rather than repeating it — if this list changes, update it here only.

Before coding, read these files in order:

1. `AGENTS.md`
2. `SECURITY.md`
3. `SESSION.md`
4. `TODO.md`
5. `DECISIONS.md`
6. `BUILD_GUIDE.md`
7. `PROJECT_CONTEXT.md`
8. During the selection sprint, also: `TiyraSense_7_DAY_SELECTION_SPRINT.md`
9. Only the relevant specification documents in `docs/`


## Documentation, research, and freshness rules

- **Use current official documentation for changing libraries, SDKs, APIs, providers, platform behavior, and deployment tooling.** Before implementing against an external dependency, verify its current documentation and supported version instead of relying on remembered or copied instructions.
- Prefer primary sources: official framework/provider documentation, official API references, release notes, security advisories, and authoritative specifications. Use community posts only when primary documentation is unavailable or when they provide clearly identified practical evidence.
- When a task depends on behavior that may have changed, record the documentation/release date or version checked in the session log or decision record. Do not copy stale setup commands or deprecated API names into new code.
- If external research changes a provider, package, API contract, model name, version, or deployment assumption, update `DECISIONS.md` and the affected specification before implementation when the change is durable.
- Do not "research" merely to justify a preferred implementation. Research must answer the actual compatibility, capability, security, cost, licensing, or operational question needed by the task.
- When a dependency or API is uncertain, verify it before coding. Do not write speculative integration code and label it complete.
- Keep documentation consistent: when code, configuration, API/database contracts, architecture, or user-visible behavior changes, update the smallest relevant specification and status/handoff files in the same session.

If code and documentation disagree, do not silently choose one: determine whether the implementation or specification is stale, record the outcome in `DECISIONS.md`, update the specification, then update code.

## If a previous agent violated these rules

If inspection reveals that inherited code or documentation breaks a rule in this file or `SECURITY.md` — e.g. an invented provider, a hard-coded "safe/dangerous" road, a merged risk score, an LLM making a routing decision, a committed secret, or `SIMULATED` data presented as `LIVE`:

1. Do not silently fix it as part of an unrelated task.
2. Do not continue building on top of the violation.
3. Record it plainly in `SESSION.md` as a BLOCKER and in `LOG.md` as a Problem, including what the violation is and where.
4. If it's a committed secret, follow the revoke/rotate steps in `SECURITY.md` immediately regardless of the current task.
5. Propose the minimal correction as its own task; do not bundle it with unrelated feature work.
6. Wait for confirmation before changing a decision marked FINALIZED in `DECISIONS.md`, even to fix a violation — record the conflict there instead.

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

## Code quality standards

These rules apply to project source code (`mobile/`, `web/`, `backend/`, `ml/`, `scripts/`, `tests/`) — not to this instruction file or other project documentation, which stay as detailed as they need to be.

### 1. Code conciseness

- Prefer concise code when it remains clear, readable, maintainable, and correct.
- Avoid unnecessary lines, repetition, boilerplate, wrappers, intermediate variables, and redundant abstractions.
- Prefer direct solutions over verbose implementations.
- Use language/framework features that reduce unnecessary code when they improve clarity.
- Do not artificially compress code into unreadable one-liners.

### 2. Remove redundancy

- Before adding code, search the project for existing implementations that can be reused.
- Do not duplicate business logic, validation, API handling, state management, formatting, constants, types, utilities, or UI behavior.
- Consolidate duplicated logic into the appropriate existing abstraction when that improves maintainability.
- After modifying code, check for newly duplicated, obsolete, unreachable, or superseded code and remove it.
- Do not keep old implementations alongside replacements unless backward compatibility explicitly requires both.

### 3. Meaningful code

- Use descriptive names so the code explains what it does without excessive comments.
- Prefer names that describe intent and purpose rather than short generic names.
- Keep functions, classes, components, and modules focused.
- Avoid unnecessary nesting and complicated control flow.
- Prefer simple, obvious implementations over clever solutions.

### 4. Better implementation before coding

Before implementing a non-trivial feature or change:

- Inspect the existing architecture and relevant code.
- Search the repository for reusable functionality before creating a new implementation.
- Consider simpler implementation approaches and fewer moving parts.
- Verify current official documentation and external contracts when the change depends on them.
- Confirm the change does not conflict with a finalized decision, security rule, or current specification.
- Identify the minimum files that need changing and avoid broad rewrites.
- Choose the approach that provides the best balance of correctness, readability, maintainability, performance, and code simplicity.

### 5. Avoid overengineering

- Do not create abstractions, configuration, interfaces, wrappers, helper layers, factories, services, or extensibility points without a real current requirement.
- Do not build for hypothetical future requirements.
- Do not introduce patterns or architecture simply because they are commonly used elsewhere.
- Prefer the simplest design that satisfies the current requirement and project architecture (see "Critical architectural separation" above — simplicity must still respect that separation, not collapse it).

### 6. Dependency discipline

- Before adding a dependency, check whether the project already has functionality that solves the problem.
- Prefer standard library or existing framework capabilities when they are sufficient.
- Do not add a dependency for trivial functionality.
- Avoid multiple dependencies that solve the same problem.
- A new dependency is still subject to the patch/vulnerability review required by `SECURITY.md`.

### 7. Targeted changes

- Modify only what is necessary for the requested feature or fix.
- Do not rewrite entire files when a focused change is sufficient.
- Do not refactor unrelated working code unless the refactor is required by the requested change or fixes a verified issue.
- Preserve existing behavior outside the requested scope.
- This does not override "Module ownership" above — a targeted change still stays within its owning module unless the task says otherwise.

### 8. Performance without sacrificing clarity

- Avoid obviously wasteful operations, unnecessary repeated computation, redundant API calls, repeated database queries, unnecessary object creation, and inefficient data processing.
- Prefer efficient built-in/library operations where they remain readable.
- Do not sacrifice readability for micro-optimizations without a measurable or meaningful benefit.

### 9. Comments and documentation

- Prefer self-explanatory code over comments.
- Do not add comments that merely restate what the code already says.
- Comment only non-obvious reasoning, constraints, workarounds, edge cases, or important architectural decisions — including *why* a rule from this file (e.g. the LLM/routing boundary, or a provenance requirement) shapes a particular piece of code, where that isn't obvious from the code alone.

### 10. Refactoring rule

When touching existing code, improve local code quality where it is directly related to the change:

- remove duplication
- remove dead code
- simplify unnecessarily complex logic
- remove unused imports/variables
- eliminate obsolete implementations
- preserve behavior unless the task requires a behavior change

Do not turn a feature task into a broad unrelated refactor.

### 11. Final code review

Before considering the implementation complete, review the resulting code specifically for:

- unnecessary lines
- duplicated logic
- unnecessary abstractions
- redundant variables
- repeated conditions
- dead/unused code
- overly complex control flow
- unnecessary dependencies
- unclear naming
- opportunities to simplify without reducing functionality

The goal is not "shortest possible code." The goal is:

> the smallest amount of clear, maintainable code that correctly implements the required functionality.

Do not shorten code if doing so makes it harder to understand or maintain. Treat this review as part of "Definition of Done" below, not a separate optional pass.

### 12. Preserve functionality

Concise code must never come at the cost of:

- correctness
- security
- error handling
- required edge cases
- testability
- maintainability
- project architecture
- existing required behavior

When two implementations provide equivalent functionality, prefer the one with fewer moving parts and less unnecessary code, provided readability remains equal or better. None of this relaxes "Absolute restrictions" below — conciseness is never a reason to skip provenance, labeling, RBAC, or the LLM/routing boundary.

### 13. Apply these rules during updates

Whenever an existing file is modified:

```text
Inspect → Reuse → Simplify → Implement → Remove redundancy → Validate
```

Do not simply append new code to the existing implementation. Re-evaluate whether the existing structure should be reused, simplified, or replaced as part of the requested change.

### 14. Test and temporary-file discipline

- Permanent tests live in the appropriate `tests/` or module test directory and should cover behavior that must keep working across future changes.
- Disposable verification scripts, generated fixtures, debug dumps, temporary exports, and local setup artifacts must be removed after the check succeeds.
- Before marking work complete, search for newly created temporary files and confirm they are either permanent project assets or deleted.
- Prefer adding a focused regression test when a bug or edge case is likely to recur rather than relying only on a one-time manual check.

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

For mobile work, explicitly consider offline behavior and recovery. For intelligence work, preserve data provenance, timestamps, confidence, and the version of the model/risk logic used. A compiling screen, endpoint, or isolated function is not a completed feature. Before marking a feature done, also complete the "Final code review" pass in "Code quality standards" above — passing tests does not by itself satisfy that pass.

## Mandatory continuous logging rule

This rule is non-negotiable and applies to every agent, every task, every session.

**After completing any task that changes code, configuration, documentation, tests, data, or project state — regardless of size — the agent MUST immediately update both `SESSION.md` and `LOG.md` before responding to the next request or stopping work.**

A "completed task" is any of the following:
- Writing, editing, or deleting a source file
- Running a command that changes repository or database state
- Completing a feature, fix, refactor, or security change
- Recording an architectural or security decision
- Pushing a commit to any branch

"Immediately" means in the same response turn, before the next user request is processed.

Specifically:
- Append a new entry to `LOG.md` following the established entry format.
- Update the **Latest session** block in `SESSION.md` to reflect the current actual state, files touched, test results, and next step.
- Do not batch multiple tasks into a single log entry written only at session end. Each task gets its own log entry when it is completed.
- Do not summarize or omit information to save space. LOG.md is a forensic record.
- If a task was attempted and failed or was blocked, record that too — do not only log successes.

This rule cannot be deferred to "session close-out." Session close-out is for final review, not for writing the log for the first time.

## Session close-out

Before ending a work session (in addition to the continuous logging already required above):

1. Run proportionate checks and record their results.
2. Confirm `SESSION.md` reflects the final state of this session, including files changed, verification results, blockers, and exactly one next task.
3. Confirm `LOG.md` has a complete entry for every task completed in this session.
4. Update `TODO.md` statuses.
5. Record durable architectural/security decisions in `DECISIONS.md`.
6. Inspect `git status`; do not stage, discard, or overwrite unrelated user changes.
