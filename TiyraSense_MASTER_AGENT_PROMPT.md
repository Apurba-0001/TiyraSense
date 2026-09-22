# TiyraSense — Master Agent Prompt

You are an AI coding agent working on **TiyraSense**, SIH 2026 Problem Statement 26002.

This file is an **orchestration entry point**, not a rulebook. It tells you which document governs which part of your behavior and in what order to read them. It does not restate their contents — read the referenced files for the actual rules.

## Read in this order

1. `AGENTS.md` — follow its canonical mandatory reading order.
2. Choose the applicable session protocol:
   - `FIRST_SESSION.md` for a new session/new agent.
   - `CONTINUE_SESSION.md` for continuing existing work.
3. Follow the remaining files and ordering specified by `AGENTS.md`.
4. Read only task-relevant specification files under `docs/`.

## What governs what

- Project-wide rules (architecture, LLM boundary, absolute restrictions, code quality, Definition of Done): `AGENTS.md`.
- Security: `SECURITY.md`.
- Finalized/open architectural and product decisions: `DECISIONS.md`.
- Permanent product knowledge (users, risk model, data sources, ML approach, safety principles): `PROJECT_CONTEXT.md`.
- Long-term phase sequence and exit conditions: `BUILD_GUIDE.md`.
- New-session state reconstruction: `FIRST_SESSION.md`.
- Continuation state reconstruction: `CONTINUE_SESSION.md`.

The repository — code, tests, and configuration — is the source of truth for what actually exists. Treat claims in `SESSION.md`, `TODO.md`, and `LOG.md` as previous agents' reports to verify, not as facts to accept unchecked.

## Documentation freshness

Current official documentation is required before implementing against changing external libraries, SDKs, APIs, models, providers, or deployment platforms. Do not trust copied/stale instructions. Durable findings belong in `DECISIONS.md` and affected specifications.

## Task handling

- **If a concrete task has already been assigned** (by the human, or clearly implied by current phase priorities and an explicit instruction), complete the state verification required by `FIRST_SESSION.md` or `CONTINUE_SESSION.md`, then proceed with that task.
- **If no task has been assigned**, complete only the initialization/state report required by the applicable session protocol, then stop and wait for instructions.
- Never invent or start a task merely because the next step looks obvious. Never begin unassigned work without an explicit instruction.

## Non-negotiable boundaries (see `AGENTS.md` and `SECURITY.md` for full detail)

- The LLM never makes or overrides a safety-critical accessibility, risk, or routing decision.
- Current Accessibility, Disruption Probability, and Route Risk stay separate and traceable.
- Do not invent providers, APIs, or real-time data; do not present `SIMULATED`/`TEST`/`PROTOTYPE` output as validated or `LIVE`.
- Do not silently change architecture or resolve an open provider decision.
- Do not commit secrets; do not add unauthenticated sensitive endpoints.
- Discovered violations of these rules are reported per `AGENTS.md` → "If a previous agent violated these rules" — not silently fixed as part of unrelated work.

## End of session

Run tests, inspect the diff, then update `SESSION.md`, `TODO.md`, `LOG.md`, and `DECISIONS.md` (if a decision was made) exactly as required by the session protocol you followed. The next agent must be able to continue from the repository alone.

## First response in a new session

Do not code immediately. Produce the state report required by `FIRST_SESSION.md` (new session) or `CONTINUE_SESSION.md` (continuation) first. If a task was already given, move directly into implementing it once that report is done; otherwise wait for one.
