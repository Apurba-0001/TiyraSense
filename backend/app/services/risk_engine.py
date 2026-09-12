"""
TiyraSense — Deterministic Risk Engine
Authoritative Specification: docs/risk_and_conflict_resolution.md (Decision D-015)
"""
from typing import Dict, List, Optional


class RiskEngine:
    # D-015 Normalized Multi-Factor Weights
    WEIGHT_RAIN = 0.35
    WEIGHT_SLOPE = 0.25
    WEIGHT_HIST = 0.15
    WEIGHT_OBSTRUCT = 0.25

    OBSTRUCTION_SEVERITY_MAP = {
        "LOW": 0.25,
        "MEDIUM": 0.50,
        "HIGH": 0.85,
        "CRITICAL": 1.00,
    }

    @classmethod
    def calculate_segment_risk(
        cls,
        precipitation_mm_hr: float = 0.0,
        slope_degrees: float = 0.0,
        landslide_susceptibility: float = 0.1,
        historical_cuts: int = 0,
        active_obstruction_severity: Optional[str] = None,
        is_blocked: bool = False,
    ) -> float:
        """Calculate continuous hazard score R_seg in [0.0, 1.0] for an atomic road segment."""
        # Critical State Override Rule: Blocked road is absolute maximum risk
        if is_blocked:
            return 1.000

        # 1. Precipitation Factor S_rain
        s_rain = min(1.0, max(0.0, precipitation_mm_hr / 60.0))

        # 2. Terrain Susceptibility Factor S_slope
        slope_normalized = min(1.0, max(0.0, slope_degrees / 45.0))
        s_slope = 0.5 * slope_normalized + 0.5 * min(1.0, max(0.0, landslide_susceptibility))

        # 3. Historical Incident Frequency S_hist
        s_hist = min(1.0, max(0.0, historical_cuts / 10.0))

        # 4. Active Field Obstruction S_obstruct
        s_obstruct = 0.0
        if active_obstruction_severity:
            s_obstruct = cls.OBSTRUCTION_SEVERITY_MAP.get(
                active_obstruction_severity.upper(), 0.0
            )

        # Composite multi-factor sum
        r_seg = (
            cls.WEIGHT_RAIN * s_rain
            + cls.WEIGHT_SLOPE * s_slope
            + cls.WEIGHT_HIST * s_hist
            + cls.WEIGHT_OBSTRUCT * s_obstruct
        )
        return round(min(1.0, max(0.0, r_seg)), 3)

    @classmethod
    def calculate_route_risk(
        cls,
        segments_data: List[Dict],
    ) -> Dict:
        """Compute composite route risk score and viability from traversed segments.
        
        segments_data item format:
        {
            "length_meters": float,
            "risk_score": float,
            "accessibility_state": str ('OPEN', 'CAUTION', 'RESTRICTED', 'HIGH_RISK', 'BLOCKED')
        }
        """
        if not segments_data:
            return {
                "composite_risk_score": 0.0,
                "is_viable": True,
                "max_hazard_state": "OPEN",
                "total_length_km": 0.0,
            }

        total_length = sum(s.get("length_meters", 1000.0) for s in segments_data)
        if total_length <= 0:
            total_length = 1.0

        has_blockage = any(
            s.get("accessibility_state") == "BLOCKED" or s.get("risk_score", 0.0) >= 0.99
            for s in segments_data
        )

        max_seg_risk = max(s.get("risk_score", 0.0) for s in segments_data)

        # Base distance-weighted risk
        weighted_risk_sum = sum(
            s.get("length_meters", 1000.0) * s.get("risk_score", 0.0)
            for s in segments_data
        )
        base_risk = weighted_risk_sum / total_length

        # D-015 Composite Formula: 70% distance-weighted average + 30% bottleneck peak
        composite_risk = 0.70 * base_risk + 0.30 * max_seg_risk

        if has_blockage:
            composite_risk = 1.000
            is_viable = False
            max_hazard_state = "BLOCKED"
        else:
            is_viable = True
            if max_seg_risk >= 0.65:
                max_hazard_state = "HIGH_RISK"
            elif max_seg_risk >= 0.40:
                max_hazard_state = "CAUTION"
            else:
                max_hazard_state = "OPEN"

        return {
            "composite_risk_score": round(composite_risk, 3),
            "is_viable": is_viable,
            "max_hazard_state": max_hazard_state,
            "total_length_km": round(total_length / 1000.0, 1),
        }
