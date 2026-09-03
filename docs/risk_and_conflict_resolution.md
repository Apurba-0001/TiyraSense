# Risk Modeling & Conflict Resolution Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Authoritative Decisions:** D-005 (Three Separate Concepts), D-006 (Safety-First Routing), D-015 (Prototype Multi-Factor Weights)

---

## 1. Architectural Separation: The Three Risk Concepts

TiyraSense strictly isolates three distinct analytical dimensions to prevent ambiguity and preserve explainability:

```
+-----------------------------------------------------------------------------------------------+
| 1. Current Accessibility State (Observed Ground Truth / State)                                |
|    - Type: Discrete Operational Status                                                        |
|    - Values: OPEN, CAUTION, RESTRICTED, HIGH_RISK, BLOCKED, UNKNOWN                           |
|    - Provenance: Verified field reports, official closures, physical sensor readings          |
+-----------------------------------------------------------------------------------------------+
| 2. Disruption Probability (Forward-Looking Prediction)                                        |
|    - Type: Continuous Likelihood: P in [0.000, 1.000]                                         |
|    - Time Horizon: Forward 2-hour window                                                      |
|    - Provenance: ML Gradient Boosting model (Rainfall surge + Slope + Historical incidence)   |
+-----------------------------------------------------------------------------------------------+
| 3. Route Risk (Composite Path Assessment)                                                     |
|    - Type: Continuous Route Index: R_route in [0.000, 1.000]                                  |
|    - Purpose: Compares candidate routes (Safest Viable vs Fastest Available)                  |
|    - Provenance: Deterministic distance-weighted segment hazard evaluation                    |
+-----------------------------------------------------------------------------------------------+
```

---

## 2. Road Segment Risk Calculation (D-015 Formulation)

Each atomic road segment $i$ evaluates a continuous hazard score $R_{\text{seg}, i} \in [0.0, 1.0]$:

$$R_{\text{seg}, i} = w_r \cdot S_{\text{rain}, i} + w_s \cdot S_{\text{slope}, i} + w_h \cdot S_{\text{hist}, i} + w_o \cdot S_{\text{obstruct}, i}$$

### Factor Normalization & Weight Allocation

| Factor | Symbol | Weight ($w_k$) | Measurement Source | Normalization Function |
|---|:---:|:---:|---|---|
| **Precipitation Intensity** | $S_{\text{rain}}$ | **0.35** | Open-Meteo hourly rain $r$ (mm/hr) | $\min(1.0, \frac{r}{60.0})$ |
| **Terrain Susceptibility** | $S_{\text{slope}}$ | **0.25** | Segment gradient $\theta$ & geological hazard index $H_{\text{geo}}$ | $0.5 \cdot \min(1.0, \frac{\theta}{45^\circ}) + 0.5 \cdot H_{\text{geo}}$ |
| **Historical Incident Frequency** | $S_{\text{hist}}$ | **0.15** | Verified cuts on this segment over past 3 monsoons ($N_{\text{cuts}}$) | $\min(1.0, \frac{N_{\text{cuts}}}{10})$ |
| **Active Field Obstruction** | $S_{\text{obstruct}}$ | **0.25** | Severity of active verified reports on segment | $\text{Low}=0.25, \text{Med}=0.50, \text{High}=0.85, \text{Crit}=1.0$ |

$$\sum w_k = 0.35 + 0.25 + 0.15 + 0.25 = 1.00$$

### Critical State Override Rule
If a segment has an active verified status of `BLOCKED`, the calculation bypasses continuous scoring and sets:
$$R_{\text{seg}, i} = 1.000 \quad \text{and} \quad \text{TransitMultiplier}_i = \infty$$

---

## 3. Composite Route Risk & Route Recommendation

For a candidate route $A$ comprising an ordered set of segments $\{s_1, s_2, \dots, s_n\}$ with lengths $L_1, L_2, \dots, L_n$:

### Step 1: Base Distance-Weighted Risk
$$\bar{R}_A = \frac{\sum_{i=1}^n R_{\text{seg}, i} \cdot L_i}{\sum_{i=1}^n L_i}$$

### Step 2: Critical Segment Penalty Multiplier
A route that traverses an active `HIGH_RISK` or `RESTRICTED` segment receives an escalating hazard penalty to prevent "averaging away" a deadly bottleneck:

$$R_{\text{route}, A} = 1.0 - (1.0 - \bar{R}_A) \cdot \prod_{i=1}^n \left(1.0 - P_{\text{penalty}, i}\right)$$

where:
- $P_{\text{penalty}} = 0.00$ for `OPEN` segments
- $P_{\text{penalty}} = 0.15$ for `CAUTION` segments
- $P_{\text{penalty}} = 0.40$ for `RESTRICTED` segments
- $P_{\text{penalty}} = 0.85$ for `HIGH_RISK` segments
- If any segment is `BLOCKED`, $R_{\text{route}, A} = 1.000$ and the route is marked **NON-VIABLE**.

### Step 3: Recommendation Policy (D-006)
- The routing engine identifies all **VIABLE** candidate routes (where no segment is `BLOCKED`).
- **Safest Viable Route:** The candidate that minimizes $R_{\text{route}}$.
- **Fastest Available Route:** The candidate that minimizes nominal travel duration.
- If the Safest Viable Route differs from the Fastest Route:
  - Default selection = **Safest Viable Route**.
  - UI displays an explicit comparison banner highlighting the risk delta (e.g. *"+18 mins transit saves 42% hazard exposure"*).

---

## 4. Conflict Resolution Engine

When multiple contradictory reports arrive for the same road segment (e.g. Driver A reports "OPEN" at 10:00 AM, Driver B reports "MUDSLIDE" at 10:15 AM, Official confirms "PARTIAL CLOSURE" at 10:20 AM), TiyraSense executes a deterministic arbitration algorithm:

### 4.1 Evidence Score Formula
Each incoming piece of evidence $E$ receives an arbitration score:

$$\text{EvidenceScore}(E) = R_{\text{source}} \cdot e^{-\lambda \cdot \Delta t} \cdot C_{\text{corrob}} \cdot P_{\text{geo}}$$

Where:
1. **Source Reliability Weight ($R_{\text{source}}$):**
   - Official Disaster / Police Admin: $1.00$
   - Verified Field Worker (with geotagged photo): $0.90$
   - Commercial Fleet Driver: $0.65$
   - Unauthenticated / Anonymous user: $0.30$
2. **Temporal Decay ($e^{-\lambda \cdot \Delta t}$):**
   - $\Delta t$ is elapsed time in minutes since observation.
   - Half-life $\tau_{1/2} = 60 \text{ minutes} \implies \lambda = \frac{\ln(2)}{60} \approx 0.01155$.
   - A report from 2 hours ago retains only $25\%$ of its initial weight.
3. **Corroboration Factor ($C_{\text{corrob}}$):**
   - $1.0$ for a single isolated report.
   - $1.35$ if two independent users submit matching hazard categories within 30 minutes.
   - $1.60$ if $\ge 3$ independent users corroborate the hazard.
4. **Physical Plausibility ($P_{\text{geo}}$):**
   - Validates that submitter GPS coordinate is within 150 meters of the claimed `road_segment_id`.
   - $P_{\text{geo}} = 1.0$ if distance $\le 50\text{m}$; decays to $0.2$ at $500\text{m}$; $0.0$ if $> 1000\text{m}$.

### 4.2 State Arbitration Table

| Highest Scoring Evidence Category | Aggregate Score Threshold | Resulting `accessibility_state` |
|---|:---:|---|
| Active Clearance / Reopening | $\ge 0.70$ | `OPEN` |
| Moderate Congestion / Debris on shoulder | $0.40 \le S < 0.70$ | `CAUTION` |
| Single-lane cut / Heavy Waterlogging | $\ge 0.50$ | `RESTRICTED` |
| Active Mudslide / Structural risk | $\ge 0.60$ | `HIGH_RISK` |
| Full Road Washout / Bridge Down | $\ge 0.75$ | `BLOCKED` |
| Unverified single conflicting report | $< 0.40$ | Keep existing state, flag `NEEDS_VERIFICATION` |

---

## 5. Auditability & Provenance Guarantee

- Every state transition on `road_segments.current_accessibility` generates a permanent record in `audit_logs`.
- The system never mutates or deletes historic raw reports in `field_reports`.
- Downstream responses return the list of `contributing_report_ids` so operators can inspect the exact evidence chain behind any state.
