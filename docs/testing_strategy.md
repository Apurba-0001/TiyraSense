# Testing & Quality Assurance Strategy — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Authoritative Standards:** `AGENTS.md` (Definition of Done), `SECURITY.md` (Checklist), `TiyraSense_SELECTION_ACCEPTANCE_CHECKLIST.md`

---

## 1. Testing Pyramid & Verification Gates

TiyraSense enforces a strict multi-tier testing pyramid to guarantee deterministic safety calculations, spatial precision, and zero regression:

```
                  / \
                 / E2E \       --> 20-Step Canonical Evaluation Scenario
                /-------\
               / Security\     --> RBAC, Injection, Provenance, Auth boundaries
              /-----------\
             / Integration \   --> PostGIS spatial queries, OSRM API, DB transactions
            /---------------\
           /   Unit Tests    \ --> Risk engine formulas, Conflict decay, Pydantic schemas
          +-------------------+
```

---

## 2. Unit Testing Suite (`backend/tests/unit/`)

Unit tests execute hermetically in $< 5\text{ seconds}$ without external network dependencies.

### 2.1 Risk Engine Verification (`test_risk_engine.py`)
- **Weight Sum Invariant:** Asserts that configured factor weights strictly sum to $1.000$ ($w_r + w_s + w_h + w_o = 1.00$).
- **Boundary Invariants:** Verifies that for all extreme inputs ($\text{rain} = 500\text{ mm/hr}, \text{slope} = 85^\circ$), $0.000 \le R_{\text{seg}} \le 1.000$.
- **Blocked State Override:** Asserts that any segment with an active verified `BLOCKED` status immediately evaluates to $R = 1.000$ and triggers an infinite route penalty.
- **Route Penalty Monotonicity:** Verifies that adding an impassable or high-risk segment to a path strictly increases $R_{\text{route}}$.

### 2.2 Conflict Resolution Verification (`test_conflict_resolver.py`)
- **Exponential Decay:** Asserts that evidence weight halves every 60 minutes ($\tau_{1/2} = 60\text{m}$).
- **Role Authority:** Verifies that official disaster admin evidence ($R=1.0$) overrides uncorroborated driver reports ($R=0.65$).
- **Spatial Plausibility:** Confirms reports submitted $> 1000\text{ meters}$ away from the target road segment receive an arbitration score of $0.0$.

### 2.3 Schema Validation & Data Boundaries (`test_schemas.py`)
- Rejects negative rainfall or extreme coordinates outside the NER bounding box ($[20^\circ \text{N}, 30^\circ \text{N}]$, $[88^\circ \text{E}, 98^\circ \text{E}]$).
- Validates that every model output carries a valid `data_label` (`LIVE`, `HISTORICAL`, `SIMULATED`, `TEST`).

---

## 3. Integration Testing Suite (`backend/tests/integration/`)

Requires a local PostGIS test container.

### 3.1 Spatial Query Correctness (`test_spatial_queries.py`)
- Verifies `ST_DWithin` geofencing correctly identifies active drivers within 30 km of a hazard.
- Tests R-Tree GIST spatial index performance across 10,000 synthetic road segments.

### 3.2 Routing & Optimization Integration (`test_routing_service.py`)
- Mocks OSRM route response; verifies that PostGIS segment-weight calculation correctly flips the default recommendation from the fastest route to the safest bypass route when the main corridor is blocked.

### 3.3 Database Integrity & Rollbacks (`test_db_transactions.py`)
- Asserts that failing a report upload cleanly rolls back without orphaned `incident_evidence` records.

---

## 4. Security & Compliance Tests (`backend/tests/security/`)

- **RBAC Gating:** Confirms `DRIVER` credentials receive HTTP 403 Forbidden when attempting `POST /api/v1/incidents/{id}/verify` or `POST /api/v1/alerts/broadcast`.
- **SQL Injection Fuzzing:** Feeds SQL injection payloads (`' OR 1=1 --`, `UNION SELECT`) into all search, filter, and segment ID query parameters; asserts zero syntax errors or unescaped queries.
- **Header Tampering:** Rejects requests with invalid or tampered JWT signatures.
- **LLM Safety Isolation:** Verifies that the LLM response service cannot directly write to `road_segments` or `routes` tables.

---

## 5. Mobile & Offline Sync Verification

- **Batch Idempotency:** Submits the same queued batch of 5 offline reports twice; verifies the server processes them exactly once without creating duplicate records.
- **Clock Drift Compensation:** Feeds reports with client timestamps set 24 hours into the future; verifies server clamps them to `server_received_at`.

---

## 6. Canonical 20-Step Demonstration Test

The master end-to-end integration test (`tests/scenarios/test_canonical_evaluation.py`) automates the full 20-step demonstration scenario:
1. Seed Guwahati $\leftrightarrow$ Shillong NH-6 road segments in PostGIS.
2. Create driver user, vehicle, and initiate journey.
3. Simulate cloudburst weather observation ($55\text{ mm/hr}$).
4. Submit high-severity mudslide field report.
5. Execute conflict resolution $\rightarrow$ assert segment state changes to `BLOCKED`.
6. Run journey monitor $\rightarrow$ assert high-priority alert generated.
7. Invoke Gemini advisory generator (or fallback template) $\rightarrow$ verify Assamese/English text.
8. Accept reroute $\rightarrow$ verify active journey route switches to secondary bypass.
9. Verify all audit logs generated with `SIMULATED` or `TEST` provenance tags.
