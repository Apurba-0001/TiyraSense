# TiyraSense Machine Learning Pipeline — Disruption Prediction

The `ml/` module of **TiyraSense** provides the training, evaluation, validation, serialization, and high-speed forward inference pipeline for predicting the short-term likelihood of road disruptions across the North Eastern Region (NER).

---

## 1. Machine Learning Task Definition

- **Objective:** Predict the **Disruption Probability ($P_{\text{disrupt}} \in [0.0, 1.0]$)** that a specific road segment will experience an impassable transit closure (e.g. mudslide, rockfall, flash waterlogging, structural collapse) within a **2-hour prediction horizon**.
- **Scope & Architectural Isolation:**
  - The model outputs a continuous calibrated probability with data provenance and feature attribution.
  - **Invariable Safety Rule:** The ML model **never** determines the operational accessibility state (which belongs to the Conflict Resolver) and **never** makes route choices (which belongs to the deterministic Route Optimizer). It acts strictly as an informational input to the risk engine — a feature that influences risk scoring, not the decision itself.

---

## 2. Feature Schema & Engineering

The pipeline processes 8 canonical physical, meteorological, and crowd features:

| Feature Name | Type | Range / Domain | Source | Physical Rationale |
|---|---|:---:|---|---|
| `precip_1h_mm` | Float | $0.0 – 150.0\text{ mm}$ | Open-Meteo | Immediate antecedent rainfall volume saturating topsoil |
| `precip_forecast_2h_mm` | Float | $0.0 – 200.0\text{ mm}$ | Open-Meteo Forecast | Imminent heavy precipitation / cloudburst threat |
| `soil_moisture_pct` | Float | $0.0 – 100.0\%$ | Open-Meteo ECMWF | Pore water pressure reducing internal soil shear strength |
| `slope_degrees` | Float | $0.0 – 65.0^\circ$ | PostGIS DEM / Terrain | Mountain terrain gradient increasing gravitational shear stress |
| `landslide_susceptibility` | Float | $0.0 – 1.0$ | GSI Geological Survey | Bedrock lithology, fault fracture density, and weathering index |
| `historical_cuts_count` | Integer | $0 – 50$ | Historical ingestion | Frequency of previous disruptions along the specific segment |
| `road_class_encoded` | Integer | $0 – 3$ | OSM highway tag | Road tier (0: Rural, 1: MDR, 2: SH, 3: NH) reflecting fortification quality |
| `recent_unverified_reports` | Integer | $0 – 20$ | `field_reports` (last 30m) | Early crowdsourced friction signals before official verification |

---

## 3. Strict Anti-Leakage Temporal Splitting

To prevent temporal autocorrelation leakage common in monsoon weather systems, random $k$-fold cross-validation is **strictly prohibited**. Chronological cutoffs are enforced:

- **Training Window:** Historical monsoon seasons (May–September 2023 and May–September 2024).
- **Validation Window:** Early monsoon 2025 (June 2025).
- **Test / Benchmark Window:** Peak monsoon 2025 (July–August 2025).
- **Verified:** `test_ml.py` includes a regression test that asserts zero future-dated records appear in the training split.

Spatial corridor representation spans primary logistical arteries:
- **NH-06 (GS Road):** Guwahati Logistics Hub $\rightarrow$ Shillong Command Terminal
- **NH-27:** Guwahati $\rightarrow$ Silchar / Lumding
- **NH-10:** Siliguri $\rightarrow$ Gangtok hill highway

---

## 4. Model Architecture & Calibration

- **Algorithm:** `HistGradientBoostingClassifier` with `CalibratedClassifierCV` (Sigmoid calibration).
- **Rationale:**
  - Robust handling of tabular, heterogeneous feature types.
  - Native handling of missing weather sensor inputs without artificial imputation.
  - Blistering forward inference latency: $< 5\text{ milliseconds}$ per 100 segments on standard CPU cores.
  - Transparent feature importance and explainability.

### Verified Production Performance on Held-Out Test Set
- **ROC-AUC:** **0.856** (Target: $\ge 0.85$ — **MET**)
- **PR-AUC:** **0.775** (Target: $\ge 0.72$ — **MET**)
- **Test Samples:** 426 held-out peak monsoon observations.
- **Model metadata** (metrics, feature list, training date, data_label) is persisted in `ml/models/disruption_v1.0.json`.

---

## 5. Physics-Based Fallback

When the serialized model artifact is unavailable, `predict.py` falls back to a deterministic physics formula:
$$P_{\text{fallback}} = \text{clip}\left(0.35 \cdot \frac{\text{precip\_1h}}{100} + 0.30 \cdot \frac{\text{soil\_moisture}}{100} + 0.25 \cdot \frac{\text{slope}}{60} + 0.10 \cdot \text{susceptibility}, 0.0, 1.0\right)$$
The fallback is labeled with `"provenance": "PHYSICS_FALLBACK"` in the inference response, and never presented as ML inference.

---

## 6. Directory Structure

```text
ml/
├── models/
│   ├── disruption_v1.0.joblib      # Serialized scikit-learn CalibratedClassifierCV model artifact
│   └── disruption_v1.0.json        # Metadata descriptor (metrics, features, timestamp, data_label)
├── dataset.py                      # Anti-leakage temporal dataset generator & feature engineer
├── predict.py                      # Sub-5ms forward inference service with physics fallback
├── requirements.txt                # Pinned ML dependencies (scikit-learn, joblib, numpy, scipy)
└── train.py                        # Model training, probability calibration, and export script
```

---

## 7. Usage & Execution

### Installation
```bash
pip install -r ml/requirements.txt
```

### Generating Dataset & Training the Model
```bash
python ml/train.py
```
This trains the model against the anti-leakage temporal split, evaluates ROC-AUC and PR-AUC, and exports the serialized model to `ml/models/disruption_v1.0.joblib` and metadata to `ml/models/disruption_v1.0.json`.

### Programmatic Forward Inference
```python
from ml.predict import predict_segment_disruption

# Feature dictionary for a road segment
segment_features = {
    "precip_1h_mm": 45.2,
    "precip_forecast_2h_mm": 38.0,
    "soil_moisture_pct": 82.5,
    "slope_degrees": 34.0,
    "landslide_susceptibility": 0.82,
    "historical_cuts_count": 5,
    "road_class_encoded": 3,
    "recent_unverified_reports": 2,
}

result = predict_segment_disruption(segment_features)
print(result)
# Output:
# {
#   "disruption_probability": 0.764,
#   "risk_tier": "HIGH_RISK",
#   "model_version": "disruption_v1.0",
#   "latency_ms": 1.8,
#   "provenance": "LIVE_INFERENCE"
# }
```

Possible `provenance` values: `LIVE_INFERENCE` (ML model) | `PHYSICS_FALLBACK` (deterministic formula when model unavailable).

### Running ML Unit & Regression Tests
```bash
python -m pytest backend/tests/test_ml.py -v
```
Verifies dataset structure, checks that temporal training cutoffs contain zero future samples, and confirms deterministic inference output is within expected probability range.
