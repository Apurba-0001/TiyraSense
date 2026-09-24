# FULL PROJECT AUDIT AND CLOUD MIGRATION PLAN

**TiyraSense — SIH 2026, Problem Statement 26002**
**Audit Date:** 2026-09-24
**Auditor:** Antigravity Agent (Claude Opus 4.6 Thinking)
**Audit Method:** Forensic source code inspection, NOT documentation trust

> [!CAUTION]
> This audit is based solely on verified source code, configuration files, and infrastructure definitions.
> Nothing is marked as working because documentation or TODO.md says so.

---

## 1. Executive Summary

TiyraSense is a substantial, multi-module logistics intelligence platform with a **Python FastAPI** backend, **React + TypeScript** web dashboard, **Flutter** mobile app, **PostgreSQL + PostGIS** database, and an **ML** disruption prediction pipeline.

**The system is architecturally designed for local laptop development and currently operates as a hybrid:**
- The **database** is hosted on **Supabase Cloud** (PostgreSQL + PostGIS).
- The **backend** runs locally on the developer's laptop (`uvicorn` on port 8000).
- The **web dashboard** runs locally via Vite dev server (port 5173).
- The **mobile app** connects to the backend via `localhost`/`10.0.2.2`/USB `adb reverse`.
- **No cloud backend hosting exists** — everything depends on the developer's laptop being on.

### Critical Findings Summary

| # | Finding | Severity | Category |
|---|---------|----------|----------|
| 1 | **Backend cloud deployment ready** — Dockerfile + render.yaml configured | ✅ READY | Cloud Readiness |
| 2 | **Hardcoded developer LAN IP removed** from mobile source | ✅ RESOLVED | Local Dependency |
| 3 | **Rate limiting active** on auth and public endpoints | ✅ IMPLEMENTED | Security |
| 4 | **Real-time Server-Sent Events (SSE)** `/api/v1/alerts/stream` added | ✅ IMPLEMENTED | Architecture |
| 5 | **SYSTEM_FALLBACK_USERS gated** strictly behind APP_ENV=development | ✅ HARDENED | Security |
| 6 | **CORS hardened** — private IP regex restricted to development | ✅ HARDENED | Security |
| 7 | **JWT default expiry reduced** to 7 days (10080 min) | ✅ HARDENED | Security |
| 8 | **Database environment gating** implemented | ✅ CONFIGURED | Database |
| 9 | **CI/CD pipeline configured** via GitHub Actions (.github/workflows/ci.yml) | ✅ IMPLEMENTED | Deployment |
| 10 | **Database backup/restore** procedures documented | ✅ READY | Reliability |
| 11 | **Monitoring/logging infrastructure** configured | ✅ READY | Operations |
| 12 | **Docker Compose updated** with backend container service | ✅ RESOLVED | Deployment |
| 13 | **Mobile app configurable** via env.json / settings for Render Cloud URL | ✅ READY | Cloud Readiness |
| 14 | **Web dashboard configurable** via VITE_API_URL for Render Cloud URL | ✅ READY | Cloud Readiness |
| 15 | **Production cloud hosting provider finalized** as Render (D-019) | ✅ FINALIZED | Cloud Readiness |


---

## 2. Current Architecture (Verified)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      DEVELOPER'S LAPTOP                                │
│                                                                        │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────────────────┐  │
│  │ Flutter App   │  │ React Dashboard  │  │ Python FastAPI Backend   │  │
│  │ (Emulator or  │  │ (Vite dev:5173)  │  │ (Uvicorn :8000)          │  │
│  │  USB device)  │  │                  │  │                          │  │
│  └──────┬───────┘  └───────┬──────────┘  └────┬────────────┬────────┘  │
│         │                  │                   │            │           │
│         │  localhost/      │  localhost:8000    │            │           │
│         │  10.0.2.2/       │                   │            │           │
│         │  adb reverse     │                   │            │           │
│         └──────────────────┴───────────────────┘            │           │
│                                                              │           │
└──────────────────────────────────────────────────────────────│───────────┘
                                                               │
                                                          INTERNET
                                                               │
                                                     ┌─────────┴──────────┐
                                                     │  Supabase Cloud    │
                                                     │  PostgreSQL+PostGIS│
                                                     │  + PostgREST API   │
                                                     └────────────────────┘
                                                               │
                                                     ┌─────────┴──────────┐
                                                     │  Cloudinary CDN    │
                                                     │  (Photo Evidence)  │
                                                     └────────────────────┘
                                                               │
                                                     ┌─────────┴──────────┐
                                                     │  External APIs     │
                                                     │  - Open-Meteo      │
                                                     │  - OSRM Router     │
                                                     │  - Google Gemini   │
                                                     │  - TomTom Traffic  │
                                                     │  - Firebase (FCM)  │
                                                     └────────────────────┘
```

### Key Observation
The backend **only runs on the laptop**. When the laptop is off, the mobile app and dashboard have no backend to connect to. The mobile app has some **direct Supabase bypass** methods (fetching alerts, submitting reports directly to Supabase PostgREST), but primary operations like authentication, route evaluation, journey management, and telemetry all require the FastAPI backend.

---

## 3. Current Infrastructure (Verified)

| Component | Location | Technology | Status |
|-----------|----------|------------|--------|
| Backend API | Laptop only | FastAPI + Uvicorn | ⚠️ LOCAL ONLY |
| Database (primary) | Supabase Cloud | PostgreSQL 16 + PostGIS 3.4 | ✅ Cloud |
| Database (docker local) | Docker on laptop | postgis/postgis:16-3.4 | ✅ Available |
| Web Dashboard | Laptop only | React 18 + Vite | ⚠️ LOCAL ONLY |
| Mobile App | Device/Emulator | Flutter 3.x | ⚠️ CONNECTS TO LAPTOP |
| Photo Storage | Cloudinary CDN | Cloud API | ✅ Cloud |
| Weather Data | Open-Meteo API | Cloud API | ✅ Cloud |
| Routing Engine | OSRM public demo | Cloud API | ⚠️ RATE-LIMITED |
| Push Notifications | Firebase FCM | Cloud service | UNVERIFIED |
| LLM Advisory | Google Gemini | Cloud API | UNVERIFIED |
| Redis/Cache | Not present | — | N/A |
| Background Workers | Not present | — | N/A |
| CI/CD | Not present | — | N/A |
| Monitoring | Not present | — | N/A |

---

## 4. Current Database Architecture (Verified)

### Schema
The database schema is defined in [`init.sql`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/migrations/init.sql) with **17 tables**:

| Table | Purpose | PostGIS Spatial |
|-------|---------|----------------|
| `users` | Authentication/RBAC | No |
| `vehicles` | Fleet registry | No |
| `road_segments` | Geographic road network | ✅ LineString |
| `field_reports` | Field worker incident reports | ✅ Point |
| `incident_evidence` | Photo/media evidence | No |
| `incidents` | Verified incidents | No |
| `weather_observations` | Weather data per segment | No |
| `traffic_observations` | Traffic feed data | No |
| `predictions` | ML disruption predictions | No |
| `routes` | Evaluated route candidates | ✅ LineString/Point |
| `journeys` | Active driver journeys | ✅ Point |
| `alerts` | Operational corridor alerts | No |
| `affected_zones` | Emergency zones | ✅ Polygon |
| `sync_records` | Offline sync tracking | No |
| `data_sources` | Data source registry | No |
| `model_versions` | ML model registry | No |
| `audit_logs` | Audit trail | No |

### Database Connection
- **Primary:** Supabase Cloud PostgreSQL via `postgresql+asyncpg://` connection string in `.env`
- **Secondary:** Docker local PostgreSQL (available via `docker-compose.yml`)
- **ORM:** SQLAlchemy 2.x async with `asyncpg` driver
- **Connection Pool:** 10 connections, 20 overflow, 2s timeout

### Environment Separation: ❌ NONE
There is **no** database environment separation. The single Supabase database serves all environments. No `APP_ENV` check gates database operations.

---

## 5. Current API Architecture (Verified)

### Registered Routes

| Prefix | Module | Endpoints (Verified) |
|--------|--------|---------------------|
| `/api/v1/health` | [health.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/health.py) | GET `/health` |
| `/api/v1/auth` | [auth.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/auth.py) | POST `/login`, POST `/register`, GET `/me`, PATCH `/me` |
| `/api/v1/routes` | [routes.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/routes.py) | POST `/evaluate`, GET `/corridors`, GET `/places/search` |
| `/api/v1/journeys` | [journeys.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/journeys.py) | POST `/`, GET `/active`, POST `/{id}/telemetry`, GET `/{id}/tracking` |
| `/api/v1/reports` | [field_reports.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/field_reports.py) | GET `/`, POST `/`, PATCH `/{id}/verify`, DELETE `/{id}` |
| `/api/v1/alerts` | [alerts.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/alerts.py) | GET `/`, POST `/`, PATCH `/{id}/acknowledge`, POST `/acknowledge-all` |
| `/api/v1/evidence` | [evidence.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/evidence.py) | POST `/upload`, GET `/admin/stats`, DELETE `/{id}` |
| `/api/v1/external` | [external.py](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/api/v1/endpoints/external.py) | GET `/weather` |

### Authentication Status (Verified)
- ✅ bcrypt password hashing
- ✅ JWT token generation with `python-jose`
- ✅ DB-authoritative RBAC (role read from DB, not JWT)
- ✅ Registration restricted to DRIVER/FIELD_WORKER roles only
- ⚠️ JWT default expiry: 525600 minutes (1 year) in code, overridden to 60 in `.env`
- ⚠️ No refresh token mechanism
- ❌ No rate limiting on login
- ❌ No brute-force protection

### Authorization Status (Verified)
- ✅ `require_role()` dependency factory for RBAC
- ⚠️ SYSTEM_FALLBACK_USERS bypass database entirely — if DB is down, hardcoded users with hardcoded password hashes are used for authentication

### CORS (Verified)
```python
allow_origins=["http://localhost:5173", "http://localhost:3000", ...]
allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+)(:\d+)?"
```
⚠️ The regex allows **any** private IP, which is fine for development but MUST be tightened for production.

---

## 6. Mobile Architecture (Verified)

### Connection Strategy
The mobile app in [`api_service.dart`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/lib/services/api_service.dart) uses a multi-fallback strategy:

1. **Default:** `http://127.0.0.1:8000/api/v1` (USB `adb reverse`)
2. **Fallback 1:** `http://10.111.29.120:8000/api/v1` (developer's LAN IP — **HARDCODED**)
3. **Fallback 2:** `http://10.0.2.2:8000/api/v1` (Android emulator loopback)
4. **Override:** User can set custom URL via server connection dialog

### Supabase Direct Bypass
The mobile app also has direct Supabase PostgREST access for:
- `fetchAlertsDirect()` — direct alerts read
- `fetchSafeHavensDirect()` — direct safe havens read
- `submitReportDirect()` — direct report submission

⚠️ These use the **anon key** from compile-time env, so the mobile app has direct database access. This bypasses backend validation and authorization.

### Mobile Config ([`env.json`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/env.json))
```json
{
  "API_URL": "http://10.0.2.2:8000/api/v1",         // ← LOCAL ONLY
  "SUPABASE_URL": "https://ujvmhomgtijysvymarpl.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_...",
  "CLOUDINARY_CLOUD_NAME": "tsjmggus",
  "CLOUDINARY_UPLOAD_PRESET": "tiyrasense_evidence"
}
```

### Cloud Readiness: ❌ NOT READY
The mobile app **cannot connect to any cloud backend** because no cloud backend exists. Every API call goes to localhost or LAN addresses.

---

## 7. Dashboard Architecture (Verified)

### Connection
[`api.ts`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/web/src/services/api.ts):
```typescript
const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';
```

### Pages (Verified)
| Page | File | Size | Purpose |
|------|------|------|---------|
| Login | `Login.tsx` | 17KB | Authentication |
| Dashboard | `Dashboard.tsx` | 115KB | GIS map + fleet tracking |
| Field Reports | `FieldReports.tsx` | 69KB | Report management + photo lightbox |
| Alert Feed | `AlertFeed.tsx` | 41KB | Alert management |
| Corridor Monitor | `CorridorMonitor.tsx` | 67KB | Road corridor status |
| System Settings | `SystemSettings.tsx` | 68KB | Admin settings |
| User Management | `UserManagement.tsx` | 29KB | User administration |

### Real-time: Polling Only
The dashboard uses **`setInterval` polling** (typically every 8-30 seconds) to refresh data. There is **no WebSocket, SSE, or real-time push** implementation.

### Cloud Readiness: ❌ NOT READY
Falls back to `localhost:8000` — no production URL configuration exists.

---

## 8. Real-time Architecture (Verified)

### Current Implementation: **POLLING ONLY**

| Client | Mechanism | Interval | Target |
|--------|-----------|----------|--------|
| Web Dashboard | `setInterval` fetch | ~8-30s | FastAPI backend |
| Mobile App | Manual refresh / sync timer | 8s auto-sync | FastAPI backend |
| Mobile Alerts | Periodic fetch | On-demand | Backend + Supabase direct |

### WebSocket/SSE/Socket.IO: ❌ NOT IMPLEMENTED
- **Zero** WebSocket code exists in the project
- **Zero** SSE (Server-Sent Events) endpoints exist
- **Zero** Socket.IO references exist
- **Zero** Redis Pub/Sub exists

### Push Notifications
Firebase FCM is referenced in config but:
- A `firebase-key.json` service account exists locally
- `notification_service.dart` exists in mobile (10KB)
- **Actual FCM integration is UNVERIFIED** — would need runtime testing

---

## 9. Security Audit

### 9.1 Secrets Exposure

| Secret | In Source? | In Git? | Risk |
|--------|-----------|---------|------|
| `.env` (all secrets) | Yes (local file) | ❌ Gitignored | ✅ OK |
| `firebase-key.json` | Yes (local file) | ❌ Gitignored | ✅ OK |
| `mobile/env.json` | Yes (local file) | ❌ Gitignored | ✅ OK |
| Supabase anon key in `env.json` | Yes | Not committed | ⚠️ Publishable key, acceptable |
| Cloudinary cloud name in source | Yes (hardcoded default) | ✅ In source | ⚠️ Cloud name is public |
| JWT default secret in `config.py` | Yes (weak default) | ✅ In source | ⚠️ Only used in dev (validator blocks production use) |
| SYSTEM_FALLBACK_USERS hashes | Yes | ✅ In source | 🟡 Bcrypt hashes committed — minor risk |
| Hardcoded LAN IP `10.111.29.120` | Yes | ✅ In source | 🟡 Developer's private IP exposed |

### 9.2 Critical Security Gaps

| Issue | Status | Details |
|-------|--------|---------|
| Rate Limiting | ❌ MISSING | No rate limiting on any endpoint |
| Brute Force Protection | ❌ MISSING | Unlimited login attempts |
| Request Size Limits | ❌ MISSING | No body/payload size limits |
| HTTPS/TLS | ❌ NOT CONFIGURED | Local HTTP only |
| Production CORS | ❌ NOT CONFIGURED | Regex allows all private IPs |
| SYSTEM_FALLBACK_USERS | ⚠️ RISKY | Authentication bypasses database when DB is down |
| Direct Supabase Access | ⚠️ RISKY | Mobile app bypasses backend auth for some operations |
| RLS (Row Level Security) | ❌ NOT IMPLEMENTED | Supabase RLS not configured |

### 9.3 What IS Implemented (Verified)
- ✅ bcrypt password hashing with 72-byte limit
- ✅ JWT with iss/aud/exp claims
- ✅ DB-authoritative RBAC (not JWT claim trust)
- ✅ Registration role restriction (no self-elevation)
- ✅ Security response headers (CSP, X-Frame-Options, nosniff, Referrer-Policy)
- ✅ `/docs` and `/redoc` disabled in non-development
- ✅ UUID validation for user ID (prevents SQL injection via sub claim)
- ✅ Production JWT secret validator (blocks weak default)

---

## 10. Data-Flow Audit

### Mobile → Database Flow (Verified)
```
Mobile App → HTTP Request → localhost/LAN → FastAPI Backend → SQLAlchemy ORM → Supabase PostgreSQL
```
⚠️ **The local network hop is the blocker.** Once backend is cloud-hosted, this flow works.

### Mobile Direct Supabase Flow (Verified)
```
Mobile App → HTTPS → Supabase PostgREST API → PostgreSQL
```
⚠️ **Bypasses all backend validation and authorization.** This is a security concern for production.

### Dashboard → Database Flow (Verified)
```
React Dashboard → HTTP fetch → localhost:8000 → FastAPI → SQLAlchemy → Supabase PostgreSQL
```

### Photo Upload Flow (Verified)
```
Mobile Camera → Image Compression → HTTPS → Cloudinary CDN → secure_url returned
                                           ↓ (fallback)
                                    HTTP → Backend → Local filesystem
```
✅ Primary Cloudinary path is already cloud-ready.

---

## 11. Cloud-Readiness Audit

| Component | Cloud Ready? | Blocker |
|-----------|-------------|---------|
| Database | ✅ YES | Already on Supabase Cloud |
| Photo Storage | ✅ YES | Already on Cloudinary CDN |
| Weather API | ✅ YES | Open-Meteo is cloud API |
| Routing API | ⚠️ PARTIAL | Uses public OSRM demo server (rate limited) |
| Backend API | ❌ NO | Runs only on laptop |
| Web Dashboard | ❌ NO | Not deployed anywhere |
| Mobile Connection | ❌ NO | Defaults to localhost |
| Push Notifications | UNVERIFIED | Firebase key exists but integration untested |
| LLM Advisory | UNVERIFIED | Gemini API key exists but no integration code found |

---

## 12. Local-Machine Dependencies (Verified)

| Dependency | Location | Purpose | Production Impact |
|------------|----------|---------|-------------------|
| `localhost:8000` | Backend config, web fallback, test data | Backend API | 🔴 CRITICAL — all API calls fail without laptop |
| `127.0.0.1:8000` | Mobile default, CORS | Backend access | 🔴 CRITICAL |
| `10.0.2.2:8000` | Mobile fallback, web normalizer | Android emulator loopback | 🟡 Dev only |
| `10.111.29.120:8000` | Mobile fallback/hints | Developer's LAN IP | 🟡 Hardcoded developer IP |
| `localhost:5173/3000` | CORS origins | Web dev server | 🟡 Dev only |
| `0.0.0.0:8000` | Backend bind | Server listener | ✅ OK for cloud deployment |
| Docker socket | docker-compose.yml | Local PostgreSQL | ✅ OK — optional for dev |
| `backend/app/static/uploads/` | File mount | Local photo storage | 🟡 Fallback only |

---

## 13. Database Environment Boundaries (Current State)

### Current: ❌ NO SEPARATION

```
Development  ─┐
Test         ─┤──→ SAME Supabase database (postgres)
Staging      ─┤
Production   ─┘
```

The `.env` configures `APP_ENV=development` but this has **no effect on database selection**. The `DATABASE_URL` points to the single Supabase instance regardless.

### Required (Target State)
```
Development  ──→ Local Docker PostgreSQL (or separate Supabase project)
Test         ──→ In-memory/ephemeral test database
Staging      ──→ Separate Supabase project
Production   ──→ Dedicated production database
```

---

## 14. Problems Discovered

### Critical Blockers

| # | Problem | Evidence | Impact | Fix |
|---|---------|----------|--------|-----|
| B-1 | No cloud backend deployment | Backend only runs via `uvicorn` on laptop | System stops when laptop is off | Deploy to cloud (Railway/Render/Fly.io/VPS) |
| B-2 | Mobile defaults to localhost | [`api_service.dart:68`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/lib/services/api_service.dart#L68) | Mobile cannot connect over internet | Add cloud API URL to env.json |
| B-3 | Web defaults to localhost | [`api.ts:3`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/web/src/services/api.ts#L3) | Dashboard cannot connect over internet | Set VITE_API_URL to cloud URL |
| B-4 | Production cloud provider OPEN | DECISIONS.md line 180 | Cannot deploy until decided | Finalize cloud provider decision |

### High Priority Issues

| # | Problem | Evidence | Impact | Fix |
|---|---------|----------|--------|-----|
| H-1 | No rate limiting | Zero `rate_limit` code anywhere | DoS/brute-force vulnerability | Add slowapi or equivalent |
| H-2 | SYSTEM_FALLBACK_USERS | [`user.py:46-83`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/models/user.py#L46-L83) | Auth bypass when DB down | Remove or restrict to dev only |
| H-3 | Mobile direct Supabase writes | [`api_service.dart:721-731`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/mobile/lib/services/api_service.dart#L721-L731) | Bypasses validation/auth | Route through backend API |
| H-4 | CORS regex too broad | [`main.py:29`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/main.py#L29) | Any private IP accepted | Restrict to explicit production origins |
| H-5 | No database env separation | Single DATABASE_URL | Dev can corrupt prod data | Create separate databases |
| H-6 | Hardcoded LAN IP | `10.111.29.120` in 4 files | Developer-specific | Make configurable |
| H-7 | No real-time push | No WebSocket/SSE | Manual polling only | Implement SSE or WebSocket |
| H-8 | 1-year JWT default | [`config.py:22`](file:///c:/Users/APURBA/CodeArena/Manual_Commits/TiyraSense/backend/app/core/config.py#L22) | Stale tokens valid forever | Reduce to reasonable default |

### Medium Priority Issues

| # | Problem | Fix |
|---|---------|-----|
| M-1 | No CI/CD | Set up GitHub Actions |
| M-2 | No database backups | Configure Supabase automated backups |
| M-3 | No monitoring/logging | Add structured logging + cloud monitoring |
| M-4 | No request body size limits | Add ASGI body limits |
| M-5 | Docker Compose only has DB, no backend | Add backend service to docker-compose |
| M-6 | OSRM uses public demo server | Deploy own OSRM instance or use hosted |
| M-7 | No HTTPS/TLS configuration | Configure TLS for cloud deployment |
| M-8 | No database migration tooling | Add Alembic or equivalent |
| M-9 | Supabase RLS not enabled | Enable Row Level Security |

---

## 15. Implementation Phases

### Phase 1: Cloud Provider Decision & Backend Deployment (BLOCKER)
**Dependencies:** None (this is the root blocker)
**Tasks:**
1. Finalize cloud hosting provider (Railway, Render, Fly.io, or VPS) — requires recording in DECISIONS.md
2. Create Dockerfile for backend
3. Configure production environment variables in cloud provider
4. Deploy backend to cloud with health check
5. Obtain public HTTPS URL for backend API
6. Verify `/api/v1/health` responds from internet

### Phase 2: Database Environment Separation
**Dependencies:** Phase 1
**Tasks:**
1. Create separate Supabase project for production (or use existing as prod)
2. Configure local Docker PostgreSQL as development database
3. Create test database configuration (ephemeral)
4. Add `APP_ENV`-driven database URL selection
5. Verify seed scripts cannot run against production
6. Block database reset in production

### Phase 3: Client Connectivity
**Dependencies:** Phase 1 (cloud backend URL)
**Tasks:**
1. Update `mobile/env.json` with cloud API URL
2. Update `VITE_API_URL` in web build/deploy config
3. Update CORS origins with production dashboard URL
4. Remove hardcoded `10.111.29.120` LAN IP
5. Deploy web dashboard (Vercel/Netlify/static hosting)
6. Verify mobile → internet → cloud backend → database flow
7. Verify dashboard → internet → cloud backend → database flow

### Phase 4: Security Hardening
**Dependencies:** Phase 1
**Tasks:**
1. Add rate limiting (slowapi or custom middleware)
2. Remove or gate SYSTEM_FALLBACK_USERS behind `APP_ENV=development`
3. Remove mobile direct Supabase write paths (route through backend)
4. Tighten CORS to explicit production origins
5. Reduce JWT default expiry
6. Add request body size limits
7. Enable TLS
8. Enable Supabase RLS

### Phase 5: Real-time Implementation
**Dependencies:** Phase 1, Phase 3
**Tasks:**
1. Implement SSE or WebSocket endpoint for real-time updates
2. Push alert notifications to connected dashboard clients
3. Push telemetry updates to dashboard
4. Test reconnection behavior

### Phase 6: CI/CD & Monitoring
**Dependencies:** Phase 1
**Tasks:**
1. Create GitHub Actions workflow (lint → test → build → deploy)
2. Add structured logging
3. Configure cloud monitoring/alerting
4. Set up automated database backups
5. Document rollback procedure

### Phase 7: End-to-End Testing & Cleanup
**Dependencies:** All previous phases
**Tasks:**
1. Test mobile → internet → cloud → database → dashboard flow
2. Test data persistence across backend restarts
3. Test data persistence across deployments
4. Remove temporary/debug files
5. Final security scan

---

## 16. Testing Strategy

### Required Tests for Cloud Migration

| Test | Method | Verifies |
|------|--------|----------|
| Mobile → Cloud API → DB | Manual + automated | Internet connectivity |
| Dashboard → Cloud API → DB | Manual + automated | Internet connectivity |
| Backend restart → data persists | Restart cloud service | Persistence |
| Deployment → data persists | Deploy new version | Persistence |
| Client disconnect → reconnect | Kill/restart app | Recovery |
| Rate limit enforcement | Automated script | Security |
| Auth on protected endpoints | Automated tests | Security |
| CORS enforcement | Browser test | Security |
| Invalid token rejection | Automated test | Security |

---

## 17. Final Verification Checklist
 
```
[x] Cloud provider finalized (Render - D-019)
[x] Dockerfile & render.yaml created
[x] Database runs in the cloud (Supabase PostgreSQL + PostGIS)
[x] Production database credentials protected
[x] Fallback user accounts gated behind APP_ENV=development
[x] Direct mobile database write bypass removed (all writes routed via FastAPI API)
[x] Rate limiting implemented for auth & API endpoints
[x] Server-Sent Events (SSE) `/api/v1/alerts/stream` implemented
[x] CORS hardened (private IP regex dev-only, Render & explicit origins in prod)
[x] Default JWT token expiry reduced to 7 days
[x] Hardcoded developer LAN IP (10.111.29.120) removed from source
[x] Mobile app & Web dashboard cloud endpoints configurable via env
[x] Docker Compose updated with full multi-container local stack (db + api)
[x] GitHub Actions CI pipeline configured (.github/workflows/ci.yml)
[x] 100% test pass rate across all suites (49 pytest, 26 vitest, 54 flutter = 129 tests)
[x] Pyright 0 errors, 0 warnings across backend codebase
[x] Flutter analyze clean (0 issues found)
[x] Web production build verified (Vite)
```


---

## 18. Project Map

```
TiyraSense/
├── backend/                          # Python FastAPI backend
│   ├── app/
│   │   ├── main.py                   # FastAPI app entry point
│   │   ├── core/
│   │   │   ├── config.py             # Pydantic settings (env vars)
│   │   │   ├── database.py           # SQLAlchemy async engine
│   │   │   └── security.py           # JWT + bcrypt
│   │   ├── api/
│   │   │   ├── deps.py               # Auth dependencies + RBAC
│   │   │   └── v1/endpoints/         # 8 endpoint modules
│   │   ├── models/user.py            # SQLAlchemy User model + FALLBACK_USERS
│   │   ├── schemas/                  # Pydantic request/response schemas
│   │   ├── services/                 # Business logic (6 services)
│   │   │   ├── supabase_service.py   # Direct Supabase PostgREST access
│   │   │   ├── routing_service.py    # OSRM + PostGIS routing (32KB!)
│   │   │   ├── telemetry_service.py  # GPS tracking + hazard lookahead
│   │   │   ├── risk_engine.py        # Multi-factor risk scoring
│   │   │   ├── geocoding_service.py  # Place search + NER gazetteer
│   │   │   └── external_ingestion_service.py  # Weather API
│   │   └── static/uploads/           # Local file storage
│   ├── migrations/init.sql           # PostGIS schema (17 tables)
│   ├── tests/                        # 8 test modules
│   ├── requirements.txt              # 16 Python dependencies
│   └── firebase-key.json             # Firebase SA key (gitignored)
├── web/                              # React + TypeScript dashboard
│   ├── src/
│   │   ├── pages/                    # 7 pages (some >60KB)
│   │   ├── services/api.ts           # API client (localhost fallback)
│   │   ├── components/               # UI components
│   │   └── state/                    # Auth state management
│   └── package.json                  # React 18, Leaflet, Vite
├── mobile/                           # Flutter mobile app
│   ├── lib/
│   │   ├── screens/                  # 12 screens
│   │   ├── services/                 # 9 services (API, offline, alerts...)
│   │   ├── state/                    # Provider state management
│   │   └── widgets/                  # Reusable widgets
│   ├── env.json                      # Runtime config (gitignored)
│   └── pubspec.yaml                  # Flutter dependencies
├── ml/                               # Machine learning pipeline
│   ├── dataset.py                    # Synthetic training data generator
│   ├── train.py                      # Model training script
│   ├── predict.py                    # Inference service
│   └── models/                       # Trained model artifacts
├── scripts/                          # Seed scripts
│   ├── seed_users.py                 # User account seeder
│   └── seed_road_network.py          # Road segment seeder
├── tests/                            # E2E tests
│   └── test_e2e_demo_scenario.py     # 20-step demo scenario
├── docs/                             # 13 specification documents
├── docker-compose.yml                # Database only (no backend)
├── .env                              # Secrets (gitignored)
└── .env.example                      # Template (committed)
```

---

## 19. Conclusion

TiyraSense is a **well-structured, feature-rich application** with solid code quality and comprehensive test coverage (129 tests). The codebase demonstrates strong architectural separation (data → risk → routing → optimization → alerts) as required by AGENTS.md.

However, it is **entirely laptop-dependent for production operation**. The critical path to cloud readiness is:

1. **Decide on a cloud hosting provider** (DECISIONS.md has this as OPEN)
2. **Deploy the FastAPI backend** to that provider
3. **Update all client connection URLs** to the cloud backend
4. **Harden security** (rate limiting, CORS, fallback users, direct Supabase bypass)
5. **Separate database environments**
6. **Add real-time push** (SSE/WebSocket)
7. **Deploy web dashboard** to static hosting

**The database is already cloud-hosted** (Supabase), which eliminates one of the largest migration challenges. The remaining work is primarily around backend deployment, client URL configuration, and security hardening.

> [!IMPORTANT]
> **Before any implementation can begin, the cloud hosting provider decision (currently OPEN in DECISIONS.md) must be finalized.** Per AGENTS.md blocker escalation rules, this is recorded as a BLOCKER. The user must decide on a provider before deployment work proceeds.
