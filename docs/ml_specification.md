# Machine Learning Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Task Definition:** Short-Term Road Disruption Likelihood Prediction  
**Module Location:** `ml/` (Training & Evaluation) $\rightarrow$ `backend/` (Read-only Inference)

---

## 1. Objective & Operational Definition

The machine learning subsystem predicts the **Disruption Probability ($P_{\text{disrupt}} \in [0.0, 1.0]$)** that a given road segment will experience an impassable transit cut-off (e.g. debris flow, boulder collapse, flash flooding, structural subsidence) within a forward **2-hour prediction horizon**.

### Architectural Placement
- The ML model outputs a **pure probability with feature attributions**.
- It **does not** set the operational state (which belongs to the Conflict Resolver).
- It **does not** select the route (which belongs to the Route Optimizer).
- Provenance is strictly preserved: every prediction records `model_version`, `timestamp`, and `data_label`.

---

## 2. Feature Schema & Engineering

The feature pipeline ingests spatial, geological, meteorological, and community signals:

| Feature Name | Type | Unit / Range | Source | Rationale |
|---|---|---|---|---|
| `precip_1h_mm` | Float | $0.0 - 150.0\text{ mm}$ | Open-Meteo | Immediate antecedent rainfall triggers topsoil detachment |
| `precip_forecast_2h_mm` | Float | $0.0 - 200.0\text{ mm}$ | Open-Meteo Forecast | Imminent cloudburst hazard |
| `soil_moisture_pct` | Float | $0.0 - 100.0\%$ | Open-Meteo ECMWF | Saturated slopes have dramatically reduced shear strength |
| `slope_degrees` | Float | $0.0 - 65.0^\circ$ | PostGIS DEM / Segment | Mountain gradient directly correlates with gravitational shear |
| `landslide_susceptibility` | Float | $0.0 - 1.0$ | Geological Survey of India | Static lithological & fracture zone susceptibility |
| `historical_cuts_count` | Integer | $0 - 50$ | Historical Ingestion | Repeat failure points along known fault lines |
| `road_class_encoded` | Categorical | `[NH, SH, MDR, RURAL]` | OSM Highway Tag | Engineering standard & retaining wall fortification quality |
| `recent_unverified_reports` | Integer | $0 - 20$ | `field_reports` (last 30m) | Early crowd-sourced friction indicators |

---

## 3. Model Architecture & Selection

### Baseline & Production Classifier
- **Algorithm:** **Histogram-based Gradient Boosting (`HistGradientBoostingClassifier`)** or **XGBoost**.
- **Why GBDT:**
  - Robust handling of tabular, heterogeneous feature types (geospatial slope + continuous weather + categorical highway tier).
  - Native support for missing values (e.g. when soil moisture sensor is temporarily unavailable).
  - High inference efficiency: $< 5\text{ milliseconds}$ per 100 segments on standard CPU cores.
  - Transparent feature importance and SHAP value extractability for LLM explanation generation.

### Baseline Hyperparameters
```python
model = HistGradientBoostingClassifier(
    max_iter=150,
    learning_rate=0.08,
    max_depth=6,
    min_samples_leaf=20,
    l2_regularization=1.5,
    random_state=42
)
```

---

## 4. Training, Validation & Anti-Leakage Protocol

### 4.1 Strict Temporal Splitting
Random $k$-fold cross-validation is **strictly prohibited** in TiyraSense due to temporal autocorrelation of monsoon weather patterns.
- **Training Window:** Historical monsoon seasons (e.g. May–September 2023, 2024).
- **Validation Window:** Early monsoon 2025 (June 2025).
- **Test / Benchmark Window:** Peak monsoon 2025 (July–August 2025).

### 4.2 Spatial Corridor Cross-Validation
To test generalizability across unseen valleys, models are also evaluated using **Group K-Fold** partitioned by distinct geographic corridors (e.g. Train on NH-6 GS Road + NH-27; Test on NH-29 Dimapur–Kohima).

---

## 5. Evaluation Metrics & Operational Thresholds

Because false negatives in hill logistics risk lives, the model is tuned for high sensitivity at low false-alarm rates:

| Metric | Target Minimum | Operational Justification |
|---|:---:|---|
| **ROC-AUC** | $\ge 0.85$ | General discriminatory capacity across wet/dry conditions |
| **PR-AUC (Precision-Recall)** | $\ge 0.72$ | Critical for severe class imbalance (disruptions represent $< 3\%$ of segment-hours) |
| **Recall @ Precision = 0.70** | $\ge 0.80$ | Ensures 8 out of 10 genuine road closures are anticipated |
| **Brier Score** | $\le 0.08$ | Strict probability calibration (ensures $P=0.60$ means 60% chance) |

---

## 6. Model Serialization, Export & Registry

1. Trained models are serialized using `joblib` into `ml/models/disruption_vX.Y.joblib`.
2. A metadata descriptor JSON is generated alongside:
```json
{
  "model_tag": "xgb-disruption-v1.0.0",
  "created_at": "2026-09-04T00:00:00Z",
  "feature_order": ["precip_1h_mm", "precip_forecast_2h_mm", "soil_moisture_pct", "slope_degrees", "landslide_susceptibility", "historical_cuts_count", "road_class_encoded", "recent_unverified_reports"],
  "roc_auc": 0.884,
  "pr_auc": 0.741,
  "calibration_method": "isotonic"
}
```
3. Backend service loads the model artifact at startup in read-only mode and executes inference without network overhead.
