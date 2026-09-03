# SECURITY.md — TiyraSense

This is the single authoritative security policy for the TiyraSense repository.

It applies to all feature, bug-fix, refactor, data-source, AI/LLM, database, API, infrastructure, testing, and deployment work.

Security requirements are part of implementation, not a final review step. An agent must check the relevant security rules before changing code and must verify the applicable controls before marking the work complete.

---

## 1. Security Principles

TiyraSense handles operational data, location-related data, incident evidence, external data feeds, uploaded documents/media, and AI-generated output. Treat all of these as potentially sensitive or untrusted unless explicitly classified otherwise.

Follow these principles:

- Default to least privilege.
- Treat all client, uploaded, external, and model-generated content as untrusted.
- Validate at system boundaries before business logic, database writes, external calls, or downstream processing.
- Prefer existing safe abstractions over introducing new security-sensitive logic.
- Make security-sensitive behavior explicit, testable, and auditable.
- Fail safely. Do not expose internal details when an operation fails.
- Do not weaken a security control to make a test, demo, or feature easier.
- Never assume that a frontend restriction is a security control. Security enforcement belongs on trusted backend/database boundaries.

---

## 2. Current Authentication State

### Current state

TiyraSense does not currently have an implemented authentication system unless the repository's current code and documentation explicitly confirm otherwise.

Local development may therefore operate without authentication.

Do not write new functionality that assumes authentication, user identity, or RBAC already exists when it has not actually been implemented and verified.

Before any deployment accessible beyond localhost, authentication and authorization must be implemented, tested, and documented.

### When authentication is added

- Use the project's chosen authentication provider (see `DECISIONS.md`) rather than hand-rolling password, token, or session handling.
- When the database supports row-level security (RLS) or equivalent, enable it on every table that can be reached by authenticated or client-facing access.
- Do not rely on the API layer alone when the database can enforce access boundaries with RLS or equivalent row-level policies.
- Keep service-role or administrative database credentials backend-only. Never send them to the frontend.
- The frontend may use a public/anonymous key only within the intended row-level security model.
- Never trust `user_id`, `role`, ownership, or privilege fields supplied by the client. Derive identity and authorization context from the verified server-side authentication state.
- If privileged roles such as Official or Admin are introduced, enforce the role server-side on every privileged request.
- Do not gate privileged functionality only through frontend visibility or route protection.
- Do not add development authentication bypasses to production-capable code.
- Any temporary authentication exception must be isolated, time-limited, clearly marked, and recorded in `DECISIONS.md`.

---

## 3. Authorization and Role Escalation

The intended TiyraSense capability groups may include Driver, Field Worker, Official, and Admin.

When these roles are implemented:

- Every protected operation must perform authorization at the trusted boundary.
- A valid login does not automatically grant permission for every operation.
- Enforce least privilege. Users should receive only the access required for their role and task.
- Check ownership or resource-level authorization where a role alone is insufficient.
- Never accept a client-provided role as proof of authorization.
- Never hide an unauthorized operation only in the UI.
- Return explicit authorization failures without exposing internal security state.
- Administrative operations, user management, source configuration, and sensitive operational data require stronger authorization controls and auditable access where applicable.

No unauthenticated writes are allowed to sensitive operational records once public or authenticated access exists, including:

- road segments
- incidents
- predictions
- risk scores
- routes
- alerts
- administrative configuration

---

## 4. Secrets and Configuration

- Never commit credentials, API keys, tokens, certificates, private connection strings, or production identifiers.
- `.env.example` must contain placeholders only.
- Real `.env` files must remain local and gitignored.
- Never hardcode API keys, database credentials, service URLs, or equivalent secrets anywhere in source code.
- Never place secrets in tests, screenshots, documentation examples that look executable, scratch scripts, notebooks, or debug configuration.
- Never use a real credential merely because it is "temporary for testing."
- Never expose service-role or other privileged backend credentials to the frontend.
- Never log API keys, authorization headers, session tokens, passwords, cookies, or full connection strings.
- If a secret is accidentally committed, treat it as compromised:
  1. Revoke/rotate the secret.
  2. Remove the active use of the exposed secret.
  3. Assess whether any dependent credentials or data are affected.
  4. Record the incident and remediation in `LOG.md`.
  5. Record any lasting policy or architectural decision in `DECISIONS.md`.
- Verify that `.gitignore` still excludes local secret/config files after dependency, build, deployment, or configuration changes.

---

## 5. SQL Injection and Database Query Safety

### Normal database access

Use the project's chosen database client's query builder or ORM for normal database operations. When using a query-builder client, prefer typed/safe methods such as:

- `.select()`
- `.insert()`
- `.update()`
- `.delete()`
- `.eq()`
- `.neq()`
- `.in_()`
- `.order()`
- other supported typed/query-builder operations

Do not build database queries by concatenating untrusted values.

### Prohibited patterns

Never construct SQL or database query fragments using:

- f-strings containing user or external input
- `.format()` containing user or external input
- `%` interpolation containing user or external input
- string concatenation containing user or external input
- dynamically constructed filter/sort expressions from raw client strings without an allowlist

This includes values originating from:

- filenames
- user questions or search text
- incident report descriptions
- path or query parameters
- request bodies
- uploaded metadata
- external feeds (weather, traffic, official data)
- model output
- any other untrusted source

### Raw SQL exception

Raw SQL is exceptional.

When raw SQL is genuinely necessary, use parameter binding only, such as the parameterized mechanism supported by the selected driver or database interface. Never concatenate values directly into SQL.

If raw SQL is introduced:

- Document why the normal query builder or ORM was insufficient.
- Keep the query parameters separate from the SQL text.
- Add targeted tests for injection-sensitive inputs.
- Record the exception and rationale in `DECISIONS.md`.

### Logging database queries

Never log SQL with user input interpolated into it.

When database troubleshooting requires logging, log structured information such as:

- query/template identifier
- operation type
- parameter names or sanitized parameter metadata
- timing/status

Do not log secrets, tokens, or unnecessary private input values.

---

## 6. Input Validation and Data Boundaries

Validate data at the earliest trusted boundary.

For API requests:

- Use the web framework's built-in validation (e.g. FastAPI/Pydantic, or the chosen alternative) for request bodies, query parameters, path parameters, enums, identifiers, pagination, sorting, and structured data.
- Reject malformed input before business logic or expensive external calls.
- Do not manually re-implement validation that the framework already performs.
- Add custom validation only where the built-in schema constraints do not express the required business/security rule.
- Keep validation logic centralized when the same rule applies to multiple routes.

Validate and constrain:

- string lengths
- numeric ranges
- enum values
- list sizes
- pagination limits
- sort/filter fields
- resource identifiers
- uploaded file sizes
- uploaded file counts
- structured external data
- model-generated structured output

Do not assume that data is safe merely because it came from another internal service. Internal and external boundaries must still enforce the required schema and invariants.

---

## 7. API and Endpoint Hygiene

- Every endpoint must declare an explicit HTTP method.
- Do not introduce catch-all routes when a specific route is sufficient.
- Validate all request input before business logic executes.
- Apply authentication and authorization where required.
- Enforce body/payload-size limits at the ASGI/server boundary as defense in depth.
- Apply resource-level authorization before returning protected resources.
- Explicitly handle not-found cases for resource endpoints such as `/incidents/{id}` or `/road-segments/{id}`.
- Do not allow bad IDs or invalid state to cause unhandled exceptions that leak internal details.
- Return generic client-safe messages for unexpected 500-level failures.
- Log diagnostic details server-side without exposing stack traces, filesystem paths, credentials, or raw internal exception details to clients.
- Do not expose `/docs` or `/redoc` in production unless deliberately protected by the approved deployment/authentication model.
- Do not expose debug routes, environment diagnostics, dependency inspection, or internal admin utilities in public deployments.
- Use explicit CORS origins once a real frontend/client exists.
- Never ship `allow_origins=["*"]` with real user or operational data.
- Use TLS in deployed environments.
- Do not rely on frontend route guards as the only protection for protected API operations.

---

## 8. Resource and Object-Level Safety

For every endpoint that references a specific object:

1. Validate the identifier format.
2. Determine whether the resource exists.
3. Verify the requester is authorized to access it when authentication exists.
4. Check any required state constraints.
5. Return an appropriate client-safe result for not-found or unauthorized access.
6. Avoid revealing whether protected resources exist when that distinction itself is sensitive and the application's authorization model requires a generic response.

Do not use exceptions accidentally thrown by downstream libraries as the authorization mechanism.

---

## 9. File Upload Security

Uploaded files are untrusted input.

For incident photos, PDFs, and other uploads:

- Enforce request body and individual file size limits.
- Enforce file count limits.
- Validate file content/signatures rather than trusting filename extensions alone.
- Generate safe server-side filenames or object keys.
- Do not use user-provided filenames directly as filesystem paths.
- Prevent path traversal and unsafe path construction.
- Store uploads outside executable locations.
- Do not execute uploaded content.
- Do not serve uploaded content publicly by default.
- Require authorization for protected retrieval.
- Process uploads through the intended safe parser/extractor only.
- Treat extracted text, metadata, OCR text, and embedded content as untrusted.
- Reject or safely handle malformed or unsupported files.
- Use temporary storage only when necessary and clean it up after processing.
- Do not log full uploaded files or full private file contents.

If upload handling changes, add or update regression tests covering size limits, invalid files, unsafe names/paths, and unauthorized retrieval.

---

## 10. Prompt Injection and LLM Security

TiyraSense may send untrusted user-uploaded or externally sourced content to Gemini or other LLM systems.

Treat all of the following as untrusted content:

- PDF text
- PDF images
- OCR output
- incident report text
- document metadata
- user questions
- external feed text
- retrieved tool output
- model-generated text
- extracted content from previous processing stages

Untrusted content may contain instructions intended to manipulate the model, such as requests to ignore system instructions, disclose hidden prompts, change classifications, or alter application behavior.

### Prompt structure

- Keep trusted workflow/instruction content clearly separated from document or user content.
- Use the SDK's actual supported instruction/system-vs-user/document role separation when available.
- Do not rely on string concatenation alone as the security boundary.
- Clearly delimit quoted or uploaded content.
- Never treat document content as an instruction source.

### Cross-document isolation

- Output or content from one document must not become trusted instructions for processing another document within the same request/session.
- Do not unintentionally carry extracted instructions, hidden text, or model output across document-processing boundaries.
- Reset or isolate per-document context where the workflow requires it.

### Model output

- Gemini output is data, not trusted code or instructions.
- Validate structured output against the expected schema (e.g. a Pydantic model for the relevant domain entity) before storage or downstream use.
- Do not execute model-generated code, shell commands, SQL, file paths, or administrative actions.
- Do not let the model directly write routing decisions, accessibility states, risk scores, or other safety-critical records.
- Apply deterministic application rules for safety-critical actions.

### Anomalous output checks

Before storing or displaying extracted/model-generated content, perform an appropriate sanity check when applicable.

Treat output as anomalous when it contains signs such as:

- instructions aimed at the application or developer
- requests for system prompts or credentials
- unrelated content
- attempts to change security or workflow rules
- unexpected references to system internals
- malformed or inconsistent structured output
- content that does not match the requested extraction task

Do not silently pass obviously anomalous output into user-facing or persistent workflows.

### Privacy

- Minimize the amount of personal, sensitive, or precise location data sent to third-party AI services.
- Do not transmit data that is not necessary for the task.
- Where practical, anonymize or reduce sensitive context.
- Do not include secrets in prompts.

---

## 11. External Data Source Security

Weather, traffic, official, mapping, news, and third-party data feeds are untrusted until validated.

For external data:

- Verify source identity where the integration supports it.
- Validate response schema.
- Validate timestamps and freshness.
- Validate numeric ranges and expected formats.
- Check for implausible or inconsistent values when the application depends on them.
- Treat provider errors and malformed responses as untrusted failures.
- Do not silently convert stale or invalid data into "live" state.
- Preserve provenance where operational decisions depend on external data.
- Label relevant data as `LIVE`, `HISTORICAL`, `SIMULATED`, or `TEST`.
- Simulated or test data must not enter a production-labelled path.
- Do not let external text become trusted application instructions.

When an external provider changes its API or behavior, verify the current official documentation before changing the integration.

---

## 12. Location, Incident, and Sensitive Data Protection

TiyraSense may handle:

- GPS/location information
- vehicle tracking
- incident reports
- photos
- operational routes
- accessibility information
- risk scores
- alerts
- field reports

These may be sensitive.

Rules:

- Collect only the data necessary for the feature.
- Restrict access using the application's authorization model.
- Do not expose submitted photos publicly by default.
- Do not expose exact locations in logs, debug output, dashboards, or support messages unless necessary.
- Store provenance and timestamps where operational evidence depends on them.
- Document retention/deletion requirements in the relevant future specification when they become defined.
- Do not use real user/location data in disposable development checks when a synthetic fixture can validate the same behavior.
- Do not place real sensitive datasets into examples or test fixtures unless explicitly approved and required.

---

## 13. Rate Limiting and Abuse Prevention

Expensive, quota-limited, state-changing, or easily abused operations require protection before being exposed beyond localhost.

At minimum consider protection for:

- incident/report submission endpoints
- alert creation endpoints
- route computation/recomputation endpoints
- file/photo uploads
- AI/model calls (explanation, summarization)
- expensive external API calls (weather, routing, GIS)

Controls may include:

- per-IP limits
- per-session limits
- authenticated-user limits
- payload limits
- concurrency limits
- provider quota controls
- request timeouts
- bounded retries

Do not assume upstream provider quotas alone are sufficient protection.

For AI calls and other externally metered services, protect the application from a single client exhausting the available quota.

---

## 14. Dependency and Supply Chain Security

- Do not blindly upgrade dependencies during an unrelated feature task.
- Verify current official documentation and compatibility information before changing a dependency that affects application behavior.
- Prefer the project's established package-management workflow.
- Pin or appropriately constrain production dependency versions once the stack stabilizes.
- Review breaking changes before major-version upgrades.
- Review dependency security advisories/CVEs before significant upgrades and before real deployment.
- Use the existing dependency set when it already satisfies the requirement; do not add another library for functionality already provided by an installed dependency.
- Remove unused dependencies introduced during experimentation.
- Record significant dependency changes in `LOG.md` and architecture-impacting changes in `DECISIONS.md`.

Before a real deployment, perform an explicit dependency/security review. Manual review is acceptable for the project unless automation is later introduced.

---

## 15. No Duplicate Security Logic

Security-sensitive logic must have one canonical implementation whenever practical.

This includes:

- input validation
- file validation
- authorization checks
- authentication dependencies
- sanitization/normalization
- resource-access checks
- security-sensitive external-data validation

Rules:

- Reuse existing shared functions, services, dependencies, or validators before creating new ones.
- Use the web framework's dependency-injection mechanism (e.g. FastAPI `Depends()`) for reusable cross-route dependencies where appropriate.
- Do not copy-paste security checks across route handlers.
- When an existing validation/security implementation needs improvement, extend the canonical implementation instead of creating a second version.
- If duplicated security logic is discovered during a change, consolidate it when safe to do so, or record the follow-up clearly in `TODO.md`.

Duplicated security logic can drift and cause one path to become weaker than another.

---

## 16. Scratch, Debug, and Temporary File Hygiene

Temporary development artifacts can become security risks.

For one-off scripts, debug files, notebooks, probes, and manual test utilities:

- Never hardcode real API keys or credentials.
- Never disable authentication or validation in a shared implementation merely to make a test easier.
- Never use real production data when a synthetic fixture can test the same behavior.
- Delete throwaway scripts once their temporary purpose is complete unless they provide meaningful ongoing regression value.
- Keep permanent tests in the project's designated test suite, such as `backend/tests/`.
- Do not commit generated debug output, dumps, private payloads, or copied secrets.
- Remove temporary logging that exposes sensitive values.
- Before completing a task, check for leftover debug files and temporary bypasses.

A scratch file that contains a secret, bypass, or unsafe shortcut must be treated with the same care as production code.

---

## 17. Logging and Audit Safety

Logs should support investigation without becoming a source of data leakage.

Prefer structured metadata such as:

- request/operation type
- resource ID (incident, road segment, journey, etc.) when non-sensitive
- status/result
- duration/timing
- validation outcome
- safe error category
- correlation/request identifier where used

Do not log:

- API keys
- service-role credentials
- passwords
- authentication/session tokens
- authorization headers
- full private request bodies
- full private response bodies
- raw uploaded media
- full uploaded documents
- unnecessary precise GPS/location data
- raw secrets embedded in exceptions

Do not print sensitive payloads during debugging.

Security-relevant incidents and credential exposure must be recorded in `LOG.md` with enough detail to understand the remediation without copying the secret or private payload itself.

---

## 18. Error Handling

- Fail closed for authorization decisions.
- Do not expose stack traces to clients.
- Do not expose filesystem paths, environment variables, SQL text, provider credentials, or internal exception details in API responses.
- Use safe, generic client-facing messages for unexpected internal failures.
- Preserve detailed diagnostics only in controlled server-side logs.
- Do not catch broad exceptions merely to hide failures if doing so causes corrupted state or silent data loss.
- For external providers, distinguish between invalid data, provider failure, timeout, and unavailable service where the application needs to make a safe decision.

---

## 19. Security-Sensitive Development Rules for AI Agents

When an AI agent changes security-relevant code:

1. Read the relevant existing implementation and documentation first.
2. Search for an existing implementation before adding new security logic.
3. Verify current official documentation for changing SDKs, APIs, dependencies, authentication mechanisms, or provider behavior.
4. Make the smallest change that satisfies the requirement.
5. Do not weaken existing security controls without an explicit documented reason.
6. Add or update focused regression/security tests for the changed behavior.
7. Check for duplicate implementations created by the change.
8. Remove temporary debug files, bypasses, and logs.
9. Run the relevant validation/tests.
10. Record important security decisions or exceptions in `DECISIONS.md`.
11. Record the implementation and verification evidence in `LOG.md` and the active `SESSION.md`.

Security-sensitive work is not complete merely because the code compiles or the happy path works.

---

## 20. Production Readiness Security Requirements

Before any deployment beyond localhost, verify at minimum:

- Authentication is implemented where required.
- Server-side authorization is enforced.
- Row-level security (RLS) or equivalent database-level access control is enabled for applicable client-accessible tables.
- Service-role/backend credentials remain backend-only.
- Production CORS origins are explicit.
- `/docs`, `/redoc`, debug endpoints, and diagnostics are not publicly exposed unless intentionally protected.
- TLS is enabled.
- Secrets are supplied through secure environment/deployment configuration.
- Payload/body-size limits are enforced.
- Rate limiting or equivalent abuse protection is enabled for expensive/public operations.
- External data validation is implemented for relevant feeds.
- Upload validation is implemented.
- LLM input/output trust boundaries are implemented.
- Production dependencies have been reviewed for known security issues.
- Debug logging and verbose error disclosure are disabled.
- No real secrets, private data, temporary bypasses, or unsafe scratch files are committed.
- Relevant security-sensitive regression tests pass.

---

## 21. Required Security Decision and Incident Records

Update `DECISIONS.md` when a security-relevant architectural exception or lasting decision is made, including examples such as:

- introducing raw SQL
- changing authentication strategy
- changing the authorization model
- changing RLS strategy
- accepting a temporary security exception
- changing external trust boundaries
- changing how LLM output is allowed to affect application behavior
- introducing a new security-sensitive dependency

Update `LOG.md` when security-relevant work is performed, including:

- credential exposure and remediation
- security bug fixes
- security-sensitive configuration changes
- validation/test results for security fixes
- dependency vulnerability remediation
- production-hardening work

Do not put secrets or private payloads into these records.

---

## 22. Quick Security Checklist

Before marking a new endpoint, worker, integration, data path, AI workflow, or security-sensitive refactor complete:

- [ ] Current relevant implementation and documentation were inspected first.
- [ ] Current official documentation was checked for changing external dependencies/APIs where applicable.
- [ ] Authentication and server-side authorization are enforced where required.
- [ ] Client-supplied identity, role, or ownership is not trusted.
- [ ] All client and external input is validated and appropriately size-limited.
- [ ] SQL/query/filter construction cannot be influenced through string interpolation or unsafe concatenation.
- [ ] Normal database queries use the query builder or ORM — no string interpolation.
- [ ] Any exceptional raw SQL uses parameter binding and is documented in `DECISIONS.md`.
- [ ] Missing resources and authorization failures are handled explicitly.
- [ ] File uploads validate content, size, count, storage location, and generated names.
- [ ] External data is validated for source, schema, freshness, and plausibility.
- [ ] `LIVE`, `HISTORICAL`, `SIMULATED`, and `TEST` data are not mixed incorrectly.
- [ ] LLM instructions are separated from untrusted content.
- [ ] LLM output is treated as untrusted data and validated before storage/use.
- [ ] Cross-document/session LLM context cannot unintentionally leak instructions between documents.
- [ ] LLM output cannot directly execute code or make safety-critical decisions.
- [ ] Secrets and sensitive payloads are not logged.
- [ ] Exact locations and identifiers are not unnecessarily exposed.
- [ ] Expensive or abuse-prone operations have appropriate rate/quota protection.
- [ ] Dependency changes were reviewed for compatibility and relevant security advisories.
- [ ] Security-sensitive logic is not duplicated across routes/services.
- [ ] Temporary debug/scratch files and bypasses were removed.
- [ ] Production debug exposure, wildcard CORS, and verbose error disclosure are not introduced.
- [ ] Relevant security/regression tests pass.
- [ ] Important security decisions are recorded in `DECISIONS.md`.
- [ ] Work and verification evidence are recorded in `LOG.md` and `SESSION.md`.

---

## 23. Change Control

This file is authoritative for repository security behavior.

When adding a new security-sensitive pattern:

1. Prefer updating the existing rule over creating a conflicting rule elsewhere.
2. Keep project-specific requirements in this file.
3. Keep general agent workflow requirements in `AGENTS.md`.
4. Record architecture-level exceptions in `DECISIONS.md`.
5. Record implementation/verification work in `LOG.md` and `SESSION.md`.
6. Do not silently weaken or remove a security requirement.

Any conflict between a feature request and this policy must be resolved explicitly before implementation. Security requirements must not be bypassed merely because a feature is urgent, experimental, or intended for a demo.
