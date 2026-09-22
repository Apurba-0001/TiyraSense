"""
TiyraSense — Machine Learning Pipeline Tests
Authoritative Specification: docs/ml_specification.md (Sections 1, 2, 4, 5, 6)
"""
import pytest
import datetime
from ml.dataset import (
    generate_synthetic_historical_observations,
    temporal_train_test_split,
    extract_features_and_labels,
    FEATURE_NAMES,
)
from ml.predict import predict_disruption


class TestMLPipeline:
    def test_dataset_generation_and_schema(self):
        """Verify observations contain all 8 canonical features and valid target."""
        obs = generate_synthetic_historical_observations(n_samples=50, seed=123)
        assert len(obs) == 50
        for item in obs:
            for fname in FEATURE_NAMES:
                assert fname in item, f"Missing feature {fname}"
                assert isinstance(item[fname], (int, float))
            assert item["is_disrupted"] in (0, 1)

    def test_anti_leakage_temporal_split(self):
        """Verify temporal train/test split has zero forward data leakage."""
        obs = generate_synthetic_historical_observations(n_samples=200, seed=456)
        train_set, val_set, test_set = temporal_train_test_split(obs)

        cutoff_train = datetime.date(2025, 6, 1)
        cutoff_val = datetime.date(2025, 7, 1)

        for item in train_set:
            d = datetime.date.fromisoformat(item["date"])
            assert d < cutoff_train, f"Leakage: train observation {d} >= {cutoff_train}"

        for item in val_set:
            d = datetime.date.fromisoformat(item["date"])
            assert cutoff_train <= d < cutoff_val

        for item in test_set:
            d = datetime.date.fromisoformat(item["date"])
            assert d >= cutoff_val

    def test_disruption_inference_service(self):
        """Verify inference output format, model version provenance, and probability bounds."""
        # 1. Benign dry conditions on gentle terrain
        dry_pred = predict_disruption(
            precip_1h_mm=0.0,
            precip_forecast_2h_mm=0.0,
            soil_moisture_pct=20.0,
            slope_degrees=5.0,
            landslide_susceptibility=0.10,
            historical_cuts_count=0,
            road_class="NATIONAL_HIGHWAY",
        )
        assert "disruption_probability" in dry_pred
        assert 0.0 <= dry_pred["disruption_probability"] <= 0.25
        assert dry_pred["horizon_hours"] == 2
        assert dry_pred["model_version"] == "xgb-disruption-v1.0.0"
        assert dry_pred["data_label"] == "LIVE"
        assert dry_pred["confidence"] >= 0.50

        # 2. Severe monsoon cloudburst on steep slope
        monsoon_pred = predict_disruption(
            precip_1h_mm=65.0,
            precip_forecast_2h_mm=85.0,
            soil_moisture_pct=92.0,
            slope_degrees=38.0,
            landslide_susceptibility=0.85,
            historical_cuts_count=8,
            road_class="STATE_HIGHWAY",
            recent_unverified_reports=3,
        )
        assert monsoon_pred["disruption_probability"] > dry_pred["disruption_probability"]
        assert monsoon_pred["disruption_probability"] >= 0.60
