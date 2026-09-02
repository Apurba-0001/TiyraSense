# SECURITY.md — TiyraSense

This is the single authoritative security policy in the repository. It applies before any feature, data-source, or infrastructure work.

## Secrets

- Never commit credentials, keys, tokens, certificates, private connection strings, or production identifiers.
- `.env.example` contains empty placeholders only. Real `.env` files are ignored and must stay local.
- If a secret is exposed, revoke/rotate it, remove it from active use, and record the incident and remediation in `LOG.md` and any lasting policy decision in `DECISIONS.md`.

## Authentication and authorization

- Driver, Field Worker, Official, and Admin capabilities require authenticated access.
- Role-based access control (RBAC) is enforced server-side; clients never grant themselves a role.
- Official/admin operations, user management, source configuration, and sensitive operational data are protected by least privilege and auditable authorization checks.
- Do not add demo bypasses. Any approved temporary exception must be conspicuously isolated, time-limited, and documented.

## Data handling and privacy

- GPS, vehicle tracking, incident reports, and photos are sensitive. Collect the minimum needed, restrict access, and document retention/deletion policy in the relevant future specification.
- Store location and report evidence with provenance, timestamps, and access controls. Do not expose submitted photos publicly by default.
- Label all data `LIVE`, `HISTORICAL`, `SIMULATED`, or `TEST`; simulated data must not enter a production-labelled path.
- Logs, support output, dashboards, and LLM inputs must minimize personal data and never needlessly expose exact locations or identifiers.

## API and external-source security

- Validate, normalize, and sanitize every client and upstream input before storage or use by the risk engine.
- Apply appropriate authentication, authorization, rate limits, payload limits, and abuse protections to write endpoints.
- Treat weather, traffic, official, and third-party feeds as untrusted until validated for freshness, source identity, schema, and plausibility.
- No unauthenticated writes to road segments, incidents, predictions, risk scores, routes, alerts, or administrative configuration.

## File uploads

Incident photos are untrusted input. Before accepting them, enforce file-size and count limits, verify file signatures/content rather than extensions, generate safe server-side names, store outside executable/public paths, and scan/process safely. Never execute uploads or serve them publicly by default. Authorization is required for every retrieval.

## AI and LLM security

- The LLM has no direct authority to write routing decisions, accessibility states, risk scores, or other safety-critical records.
- Treat reports, uploaded metadata, documents, tool output, and external text as untrusted instructions; isolate quoted content from system/workflow instructions to mitigate prompt injection.
- Minimize/anonymize LLM context and do not transmit unnecessary personal or precise location data to third parties.
- LLM explanations must identify their evidence source and must not claim unverified conditions as facts.

## Infrastructure and operations

- Use CORS allowlists, TLS in deployed environments, least-privilege service credentials, and separated environment configuration.
- Keep dependencies patched and review vulnerability/security advisories before upgrades or releases.
- Disable debug endpoints, development credentials, directory listings, and verbose error disclosure in production.
- Log security-relevant events safely: retain useful audit data without tokens, passwords, full private payloads, or unnecessary location data.

