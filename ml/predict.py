"""
TiyraSense — Machine Learning Disruption Inference Service
Authoritative Specification: docs/ml_specification.md (Sections 1 & 6)

Provides high-efficiency (<5ms) forward disruption probability inference.
Guarantees strict provenance tracking and non-critical fallback.
"""
from pathlib import Path
from typing import Dict, Optional
import json
import joblib
import numpy as np

from ml.dataset import FEATURE_NAMES, ROAD_CLASS_MAP


_MODEL_DIR = Path(__file__).resolve().parent / "models"
_MODEL_FILE = _MODEL_DIR / "disruption_v1.0.joblib"
_METADATA_FILE = _MODEL_DIR / "disruption_v1.0.json"

_CACHED_MODEL = None
_CACHED_METADATA = None


def _load_model_and_metadata():
    global _CACHED_MODEL, _CACHED_METADATA
    if _CACHED_MODEL is None and _MODEL_FILE.exists():
        try:
            _CACHED_MODEL = joblib.load(_MODEL_FILE)
            if _METADATA_FILE.exists():
                with open(_METADATA_FILE, "r", encoding="utf-8") as f:
                    _CACHED_METADATA = json.load(f)
        except Exception:
            _CACHED_MODEL = None
            _CACHED_METADATA = None
    return _CACHED_MODEL, _CACHED_METADATA


def predict_disruption(
    precip_1h_mm: float = 0.0,
    precip_forecast_2h_mm: float = 0.0,
    soil_moisture_pct: float = 50.0,
    slope_degrees: float = 15.0,
    landslide_susceptibility: float = 0.20,
    historical_cuts_count: int = 0,
    road_class: str = "NATIONAL_HIGHWAY",
    recent_unverified_reports: int = 0,
    data_label: str = "LIVE",
) -> Dict:
    """Predict road disruption probability within a 2-hour forward horizon.
    
    Returns a strictly typed dictionary with model provenance and confidence.
    """
    model, metadata = _load_model_and_metadata()
    road_class_encoded = ROAD_CLASS_MAP.get(road_class.upper(), 0)

    feature_vector = [
        float(precip_1h_mm),
        float(precip_forecast_2h_mm),
        float(soil_moisture_pct),
        float(slope_degrees),
        float(landslide_susceptibility),
        float(historical_cuts_count),
        float(road_class_encoded),
        float(recent_unverified_reports),
    ]

    if model is not None:
        X = np.array([feature_vector])
        prob = float(model.predict_proba(X)[0, 1])
        model_version = metadata.get("model_tag", "xgb-disruption-v1.0.0") if metadata else "xgb-disruption-v1.0.0"
        # Confidence score derived from separation from decision boundary
        confidence = round(0.50 + abs(prob - 0.50), 3)
    else:
        # Physics-based baseline fallback if model file is not yet compiled
        z = (
            0.045 * precip_1h_mm
            + 0.035 * precip_forecast_2h_mm
            + 0.030 * (soil_moisture_pct - 50.0)
            + 0.080 * (slope_degrees - 15.0)
            + 2.500 * (landslide_susceptibility - 0.50)
            + 0.120 * historical_cuts_count
            + 0.400 * recent_unverified_reports
            - 3.800
        )
        prob = 1.0 / (1.0 + np.exp(-max(-10.0, min(10.0, z))))
        model_version = "physics-fallback-v0"
        confidence = 0.70

    return {
        "disruption_probability": round(min(1.0, max(0.0, prob)), 3),
        "horizon_hours": 2,
        "confidence": confidence,
        "model_version": model_version,
        "data_label": data_label,
    }
