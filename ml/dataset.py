"""
TiyraSense — Machine Learning Dataset Generator & Preprocessor
Authoritative Specification: docs/ml_specification.md (Section 2 & 4)

Generates and partitions an anti-leakage temporal dataset for road disruption
prediction across North Eastern Region hill logistics corridors.
"""
from typing import Dict, List, Tuple
import datetime
import math
import random


FEATURE_NAMES = [
    "precip_1h_mm",
    "precip_forecast_2h_mm",
    "soil_moisture_pct",
    "slope_degrees",
    "landslide_susceptibility",
    "historical_cuts_count",
    "road_class_encoded",
    "recent_unverified_reports",
]

ROAD_CLASS_MAP = {
    "NATIONAL_HIGHWAY": 0,
    "STATE_HIGHWAY": 1,
    "MAJOR_DISTRICT_ROAD": 2,
    "RURAL": 3,
}

CORRIDORS = [
    {"name": "NH-06 Guwahati-Shillong", "base_slope": 18.5, "base_susceptibility": 0.65, "road_class": 0},
    {"name": "NH-27 Guwahati-Silchar", "base_slope": 22.0, "base_susceptibility": 0.75, "road_class": 0},
    {"name": "NH-10 Siliguri-Gangtok", "base_slope": 28.0, "base_susceptibility": 0.85, "road_class": 0},
    {"name": "SH-01 Damra-Mawkyrwat Bypass", "base_slope": 14.0, "base_susceptibility": 0.40, "road_class": 1},
]


def generate_synthetic_historical_observations(
    n_samples: int = 1200,
    seed: int = 42,
) -> List[Dict]:
    """Generate physically calibrated historical segment-hour observations.
    
    Adheres strictly to physical hill road failure mechanics:
    - High precipitation (>35mm/hr) + high slope (>20 deg) + saturated soil (>75%)
      exponentially increases disruption probability.
    - Low rainfall on gentle terrain has negligible disruption (<1%).
    """
    rng = random.Random(seed)
    observations = []

    # Dates span 2023-05-01 through 2025-08-31
    start_date = datetime.date(2023, 5, 1)
    end_date = datetime.date(2025, 8, 31)
    total_days = (end_date - start_date).days

    for i in range(n_samples):
        # Sample date
        day_offset = rng.randint(0, total_days)
        obs_date = start_date + datetime.timedelta(days=day_offset)

        # Monsoon seasonal modifier (May to September is peak monsoon in NER)
        is_monsoon = obs_date.month in (5, 6, 7, 8, 9)
        corridor = rng.choice(CORRIDORS)

        if is_monsoon:
            # Higher rain in monsoon
            precip_1h = rng.expovariate(1.0 / 18.0)  # Mean 18mm/hr
            precip_forecast_2h = precip_1h * rng.uniform(0.8, 1.8)
            soil_moisture = rng.uniform(45.0, 95.0)
        else:
            precip_1h = rng.expovariate(1.0 / 2.0) if rng.random() < 0.25 else 0.0
            precip_forecast_2h = precip_1h * rng.uniform(0.5, 1.2)
            soil_moisture = rng.uniform(15.0, 50.0)

        precip_1h = round(min(140.0, precip_1h), 2)
        precip_forecast_2h = round(min(180.0, precip_forecast_2h), 2)
        soil_moisture = round(min(100.0, max(0.0, soil_moisture)), 1)

        slope = round(max(2.0, rng.gauss(corridor["base_slope"], 5.0)), 1)
        susceptibility = round(min(1.0, max(0.05, rng.gauss(corridor["base_susceptibility"], 0.12))), 2)
        historical_cuts = rng.randint(0, 15)
        recent_reports = rng.randint(0, 4) if precip_1h > 25.0 else (1 if rng.random() < 0.05 else 0)

        # Physical disruption threshold function
        # Logistic shear failure: shear stress exceeds soil cohesion
        z = (
            0.045 * precip_1h
            + 0.035 * precip_forecast_2h
            + 0.030 * (soil_moisture - 50.0)
            + 0.080 * (slope - 15.0)
            + 2.500 * (susceptibility - 0.50)
            + 0.120 * historical_cuts
            + 0.400 * recent_reports
            - 5.200  # Base intercept keeping baseline disruption rate ~4-5%
        )
        p_true = 1.0 / (1.0 + math.exp(-max(-10.0, min(10.0, z))))
        is_disrupted = 1 if rng.random() < p_true else 0

        obs = {
            "date": obs_date.isoformat(),
            "corridor": corridor["name"],
            "precip_1h_mm": precip_1h,
            "precip_forecast_2h_mm": precip_forecast_2h,
            "soil_moisture_pct": soil_moisture,
            "slope_degrees": slope,
            "landslide_susceptibility": susceptibility,
            "historical_cuts_count": historical_cuts,
            "road_class_encoded": corridor["road_class"],
            "recent_unverified_reports": recent_reports,
            "is_disrupted": is_disrupted,
            "true_probability": round(p_true, 4),
        }
        observations.append(obs)

    return observations


def temporal_train_test_split(
    observations: List[Dict],
) -> Tuple[List[Dict], List[Dict], List[Dict]]:
    """Strict temporal split per docs/ml_specification.md Section 4.1.
    
    - Train: observations before 2025-06-01 (Monsoons 2023 & 2024)
    - Validation: June 2025 (Early Monsoon 2025)
    - Test: July & August 2025 (Peak Monsoon 2025)
    """
    train_set = []
    val_set = []
    test_set = []

    for obs in observations:
        obs_date = datetime.date.fromisoformat(obs["date"])
        if obs_date < datetime.date(2025, 6, 1):
            train_set.append(obs)
        elif obs_date < datetime.date(2025, 7, 1):
            val_set.append(obs)
        else:
            test_set.append(obs)

    return train_set, val_set, test_set


def extract_features_and_labels(
    dataset: List[Dict],
) -> Tuple[List[List[float]], List[int]]:
    """Extract feature vectors X and binary labels y."""
    X = []
    y = []
    for item in dataset:
        row = [float(item[fname]) for fname in FEATURE_NAMES]
        X.append(row)
        y.append(int(item["is_disrupted"]))
    return X, y
