# REST API Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Framework Standard:** FastAPI / OpenAPI 3.1  
**Base URL:** `/api/v1`  
**Authentication Scheme:** Bearer JWT in `Authorization` header (`Bearer <token>`)

---

## 1. Global Request / Response Standards

### 1.1 Data Labeling Header
Every response from TiyraSense MUST include the provenance classification header:
```http
X-TiyraSense-Data-Label: LIVE | HISTORICAL | SIMULATED | TEST
```

### 1.2 Standardized Error Envelope
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Road segment 'NER-NH6-042' does not exist in the spatial index.",
    "status_code": 404,
    "timestamp": "2026-09-04T05:30:00Z",
    "details": null
  }
}
```

---

## 2. Authentication Endpoints

### `POST /api/v1/auth/login`
Authenticates a user and issues access and refresh tokens.

- **Request Body:**
```json
{
  "email": "driver.borah@logistics.ner",
  "password": "SecurePassword123!"
}
```
- **Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1Ni...",
  "token_type": "bearer",
  "expires_in_seconds": 3600,
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "email": "driver.borah@logistics.ner",
    "full_name": "Ramen Borah",
    "role": "DRIVER"
  }
}
```

---

## 3. Routing & Evaluation Endpoints

### `POST /api/v1/routes/evaluate`
Generates candidate routes between origin and destination, calculating both nominal duration and multi-factor safety risk.

- **Request Body:**
```json
{
  "origin": {
    "latitude": 26.1445,
    "longitude": 91.7362,
    "label": "Guwahati Inland Container Depot"
  },
  "destination": {
    "latitude": 25.5788,
    "longitude": 91.8933,
    "label": "Shillong Commercial Hub"
  },
  "vehicle_class": "FOUR_WHEELER",
  "prefer_safety": true
}
```

- **Response (200 OK):**
```json
{
  "evaluated_at": "2026-09-04T06:00:00Z",
  "data_label": "LIVE",
  "recommended_route_id": "8f3b6a2e-4c1d-4d2a-9e8f-7c1b5a3d9e2f",
  "routes": [
    {
      "id": "8f3b6a2e-4c1d-4d2a-9e8f-7c1b5a3d9e2f",
      "name": "NH-6 GS Road (Standard Corridor)",
      "total_distance_km": 98.4,
      "estimated_duration_mins": 154.0,
      "composite_risk_score": 0.285,
      "is_recommended_safest": true,
      "is_fastest_available": true,
      "is_viable": true,
      "max_hazard_state": "CAUTION",
      "geometry_geojson": {
        "type": "LineString",
        "coordinates": [[91.7362, 26.1445], [91.7820, 26.1150], [91.8933, 25.5788]]
      },
      "segments_summary": {
        "total_segments": 48,
        "open_count": 45,
        "caution_count": 3,
        "restricted_count": 0,
        "blocked_count": 0
      }
    },
    {
      "id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "name": "Guwahati-Damra Secondary Bypass",
      "total_distance_km": 142.1,
      "estimated_duration_mins": 235.0,
      "composite_risk_score": 0.192,
      "is_recommended_safest": false,
      "is_fastest_available": false,
      "is_viable": true,
      "max_hazard_state": "OPEN"
    }
  ]
}
```

---

## 4. Journey Tracking & Dynamic Rerouting

### `POST /api/v1/journeys`
Starts a tracked active journey.

- **Request Body:**
```json
{
  "route_id": "8f3b6a2e-4c1d-4d2a-9e8f-7c1b5a3d9e2f",
  "vehicle_id": "7b8c9d0e-1f2a-3b4c-5d6e-7f8a9b0c1d2e"
}
```
- **Response (201 Created):**
```json
{
  "journey_id": "d4e5f6a7-b8c9-0123-4567-89abcdef0123",
  "status": "ACTIVE",
  "started_at": "2026-09-04T06:05:00Z"
}
```

### `POST /api/v1/journeys/{id}/telemetry`
Submits real-time driver breadcrumbs.

- **Request Body:**
```json
{
  "coordinates": { "latitude": 25.8921, "longitude": 91.8104 },
  "speed_kmh": 42.5,
  "heading_degrees": 165.0,
  "timestamp": "2026-09-04T06:45:12Z"
}
```
- **Response (200 OK):**
```json
{
  "journey_id": "d4e5f6a7-b8c9-0123-4567-89abcdef0123",
  "current_segment_id": "NER-NH6-042",
  "ahead_hazard_detected": true,
  "critical_alert_pending": true
}
```

### `POST /api/v1/journeys/{id}/reroute`
Accepts a system-recommended diversion.

- **Request Body:**
```json
{
  "new_route_id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
  "accepted_by_driver": true
}
```
- **Response (200 OK):** Returns updated active route geometry.

---

## 5. Field Reporting & Batch Sync Endpoints

### `POST /api/v1/reports`
Submits a single real-time incident observation.

- **Request Body:**
```json
{
  "hazard_type": "MUDSLIDE",
  "severity": "HIGH",
  "description": "Active mud and boulder slip covering southbound lane.",
  "location": { "latitude": 25.9012, "longitude": 91.8841 },
  "client_captured_at": "2026-09-04T06:40:00Z"
}
```
- **Response (202 Accepted):** Returns `report_id` and assigned `road_segment_id`.

### `POST /api/v1/reports/batch`
Reconciles an offline mobile queue upon restoring connectivity.

- **Request Body:**
```json
{
  "sync_session_id": "c1d2e3f4-a5b6-7890-1234-56789abcdef0",
  "reports": [
    {
      "client_uuid": "local-rep-001",
      "hazard_type": "WATERLOGGING",
      "severity": "MEDIUM",
      "location": { "latitude": 25.9100, "longitude": 91.8800 },
      "client_captured_at": "2026-09-04T05:15:30Z"
    },
    {
      "client_uuid": "local-rep-002",
      "hazard_type": "MUDSLIDE",
      "severity": "CRITICAL",
      "location": { "latitude": 25.8950, "longitude": 91.8830 },
      "client_captured_at": "2026-09-04T05:45:10Z"
    }
  ]
}
```
- **Response (200 OK):**
```json
{
  "processed_count": 2,
  "succeeded_count": 2,
  "failed_count": 0,
  "reconciliation_timestamp": "2026-09-04T06:50:00Z"
}
```

---

## 6. Official Verification & Admin Endpoints

### `POST /api/v1/incidents/{id}/verify`
Requires `OFFICIAL` or `ADMIN` role.

- **Request Body:**
```json
{
  "verified_action": "CONFIRM_BLOCKAGE",
  "accessibility_override": "BLOCKED",
  "official_notes": "Project Vartak (BRO) team deployed for earthmoving; highway closed for 4 hours."
}
```
- **Response (200 OK):** Broadcasts corridor state change and logs audit entry.

---

## 7. Multilingual Advisory Endpoint (LLM Isolated)

### `POST /api/v1/advisories/explain`
Generates human-readable localized driver advisories from deterministic risk facts.

- **Request Body:**
```json
{
  "incident_type": "MUDSLIDE",
  "severity": "HIGH",
  "segment_name": "NH-6 near Nongpoh",
  "target_languages": ["as", "bn", "hi", "en"],
  "estimated_delay_mins": 45
}
```
- **Response (200 OK):**
```json
{
  "generated_at": "2026-09-04T06:46:00Z",
  "advisories": {
    "en": "Caution: Severe mudslide reported on NH-6 near Nongpoh. Safe bypass recommended via Umsning (+20 mins).",
    "as": "সাৱধান: নংপোৰ ওচৰত ৰাষ্ট্ৰীয় ঘাইপথ-৬ ত ভূমিস্খলন। উমস্নিং হৈ বিকল্প পথ গ্ৰহণ কৰক।",
    "hi": "सावधान: नोंगपोह के पास NH-6 पर भूस्खलन। उमसिंग के रास्ते सुरक्षित डायवर्जन लें (+20 मिनट)।"
  },
  "disclaimer": "AI-generated explanatory advisory. Operational state verified by ASDMA field evidence."
}
```
