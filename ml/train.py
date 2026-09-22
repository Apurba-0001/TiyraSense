"""
TiyraSense — Disruption Prediction Model Trainer
Authoritative Specification: docs/ml_specification.md (Sections 3, 4, 5, 6)

Trains, evaluates, and registers the baseline HistGradientBoosting disruption classifier.
Enforces anti-leakage temporal splitting and probability calibration.
"""
from pathlib import Path
import datetime
import json
import joblib
import numpy as np

from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score, brier_score_loss, average_precision_score
from ml.dataset import (
    FEATURE_NAMES,
    generate_synthetic_historical_observations,
    temporal_train_test_split,
    extract_features_and_labels,
)


def train_and_evaluate_model(
    output_dir: Path = Path("ml/models"),
    random_state: int = 42,
) -> dict:
    """Train HistGradientBoostingClassifier with strict temporal split and serialization."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Generate historical observations with physical hill failure physics
    observations = generate_synthetic_historical_observations(n_samples=6000, seed=random_state)

    # 2. Strict Temporal Anti-Leakage Split
    train_obs, val_obs, test_obs = temporal_train_test_split(observations)
    assert len(train_obs) > 0, "Train set must not be empty"
    assert len(test_obs) > 0, "Test set must not be empty"

    X_train, y_train = extract_features_and_labels(train_obs)
    X_val, y_val = extract_features_and_labels(val_obs)
    X_test, y_test = extract_features_and_labels(test_obs)

    # Combine train and early validation for final model fit, holding out peak monsoon test
    X_fit = np.array(X_train + X_val)
    y_fit = np.array(y_train + y_val)
    X_eval = np.array(X_test)
    y_eval = np.array(y_test)

    from sklearn.calibration import CalibratedClassifierCV

    base_model = HistGradientBoostingClassifier(
        max_iter=200,
        learning_rate=0.06,
        max_depth=5,
        min_samples_leaf=15,
        l2_regularization=2.0,
        random_state=random_state,
    )
    model = CalibratedClassifierCV(estimator=base_model, method="sigmoid", cv=3)
    model.fit(X_fit, y_fit)

    # 4. Evaluation on Held-out Temporal Test Window
    probs = model.predict_proba(X_eval)[:, 1]
    roc_auc = float(roc_auc_score(y_eval, probs))
    brier = float(brier_score_loss(y_eval, probs))
    pr_auc = float(average_precision_score(y_eval, probs))

    # 5. Serialization per Section 6
    model_path = output_dir / "disruption_v1.0.joblib"
    joblib.dump(model, model_path)

    metadata = {
        "model_tag": "xgb-disruption-v1.0.0",
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "algorithm": "HistGradientBoostingClassifier",
        "feature_order": FEATURE_NAMES,
        "train_samples": len(X_fit),
        "test_samples": len(X_eval),
        "roc_auc": round(roc_auc, 4),
        "brier_score": round(brier, 4),
        "pr_auc": round(pr_auc, 4),
        "targets_met": {
            "roc_auc_target_met": roc_auc >= 0.85,
            "brier_target_met": brier <= 0.08,
        },
        "model_artifact": str(model_path.name),
        "data_label": "HISTORICAL_SIMULATED",
    }

    metadata_path = output_dir / "disruption_v1.0.json"
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    return metadata


if __name__ == "__main__":
    results = train_and_evaluate_model()
    print("Training Complete. Evaluation Metrics on Held-out Monsoon Test Set:")
    print(json.dumps(results, indent=2))
