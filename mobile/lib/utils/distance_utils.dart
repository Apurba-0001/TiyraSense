import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Single applied regulatory or terrain distance clause.
class DistanceClauseItem {
  final String clauseCode;
  final String title;
  final String regulatoryRef;
  final double deltaKm;
  final String percentageText;
  final String explanation;
  final IconData icon;
  final Color badgeColor;

  const DistanceClauseItem({
    required this.clauseCode,
    required this.title,
    required this.regulatoryRef,
    required this.deltaKm,
    required this.percentageText,
    required this.explanation,
    required this.icon,
    this.badgeColor = const Color(0xFF1E3A8A),
  });
}

/// Comprehensive distance breakdown detailing how the final road distance
/// is computed from base aerial coordinates using applicable NER engineering clauses.
class DistanceBreakdown {
  final double baseAerialKm;
  final double terrainCurvatureKm;
  final double vehicleAxleKm;
  final double hazardDetourKm;
  final double cargoBufferKm;
  final double totalRoadKm;
  final List<DistanceClauseItem> clauses;
  final String estimatedEtaText;
  final double nominalSpeedKmh;

  const DistanceBreakdown({
    required this.baseAerialKm,
    required this.terrainCurvatureKm,
    required this.vehicleAxleKm,
    required this.hazardDetourKm,
    required this.cargoBufferKm,
    required this.totalRoadKm,
    required this.clauses,
    required this.estimatedEtaText,
    required this.nominalSpeedKmh,
  });
}

/// Utility class for precise geographical distance calculations and North Eastern Region
/// (NER) terrain curvature adjustments.
class DistanceUtils {
  static const double earthRadiusKm = 6371.0;

  /// NER hill terrain multiplier accounting for winding mountain roads,
  /// elevation gradients, and hairpin turns (IRC:SP:48 / D-015 standard).
  static const double nerTerrainMultiplier = 1.38;

  /// Calculates great-circle Haversine distance in kilometers between two GPS coordinates.
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates realistic road distance in kilometers including NER terrain multiplier.
  static double calculateRoadDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double terrainMultiplier = nerTerrainMultiplier,
  }) {
    final directDist = haversineKm(lat1, lon1, lat2, lon2);
    return directDist * terrainMultiplier;
  }

  /// Computes a comprehensive breakdown of actual road distance with all applied clauses:
  /// 1. Base Aerial Geodesic (WGS-84 Haversine)
  /// 2. IRC:SP:48 Hill Road Topography & Curvature Clause (+38%)
  /// 3. Vehicle Axle & Weight Clearance Clause (HCV freight corridor vs LCV shortcut)
  /// 4. Safety Hazard & Landslide Detour Clause (Bypassing high-risk sectors)
  /// 5. Cargo Protocol Buffer Clause (HAZMAT/POL mandatory perimeter bypass)
  static DistanceBreakdown computeDetailedBreakdown({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    String? vehicleTitle,
    String? cargoTitle,
    bool isSafestRoute = true,
    int disruptionProbPct = 15,
    double? overrideRoadKm,
    double? overrideDetourKm,
    String? overrideEtaText,
  }) {
    final aerial = haversineKm(lat1, lon1, lat2, lon2);
    final aerialRounded = (aerial * 10).round() / 10.0;

    // Clause 2: Hill Topography & Curvature Clause (+38% IRC:SP:48)
    final curvatureDelta = (aerial * 0.38 * 10).round() / 10.0;

    // Clause 3: Vehicle Axle & GVW Clearance Clause
    final vLower = (vehicleTitle ?? '').toLowerCase();
    double vehicleDelta = 0.0;
    String vehicleExpl = 'Standard 2-axle carrier allowed on regional hill corridors.';
    String vehiclePct = '0%';

    if (vLower.contains('31t') || vLower.contains('prima') || vLower.contains('multi-axle') || vLower.contains('heavy')) {
      vehicleDelta = (aerial * 0.12 * 10).round() / 10.0;
      vehiclePct = '+12%';
      vehicleExpl = 'Heavy Multi-Axle Truck (>25T GVW): Restricted from steep hairpin bypasses (<15m radius); routed via designated NH heavy freight corridor.';
    } else if (vLower.contains('1618') || vLower.contains('medium') || vLower.contains('16 ton')) {
      vehicleDelta = (aerial * 0.06 * 10).round() / 10.0;
      vehiclePct = '+6%';
      vehicleExpl = 'Medium Cargo Carrier (16T GVW): Compliant with intermediate NH corridors and dual-lane hill state highways.';
    } else {
      vehicleDelta = (aerial * 0.01 * 10).round() / 10.0;
      vehiclePct = '+1%';
      vehicleExpl = 'Light 4x4 / LCV (<5T GVW): High hill clearance permits narrow single-lane mountain bypasses and tight hairpins.';
    }

    // Clause 4: Safety Hazard & Landslide Avoidance Detour Clause
    double hazardDetourDelta = 0.0;
    String hazardExpl = '';
    String hazardPct = '0%';

    if (overrideDetourKm != null) {
      hazardDetourDelta = (overrideDetourKm * 10).round() / 10.0;
      final pct = aerial > 0 ? (hazardDetourDelta / aerial * 100).round() : 0;
      hazardPct = hazardDetourDelta > 0 ? '+$pct%' : '0%';
      hazardExpl = hazardDetourDelta > 0
          ? 'Terrain & Safety Bypass Detour: Alternate valley/ridge corridor bypassing high-risk ghat bottlenecks (+${hazardDetourDelta.toStringAsFixed(1)} km).'
          : 'Direct Primary Corridor: Direct pass along national artery without detour.';
    } else if (isSafestRoute) {
      if (disruptionProbPct >= 30) {
        hazardDetourDelta = math.max(12.0, (aerial * 0.16 * 10).round() / 10.0);
        hazardPct = '+16%';
        hazardExpl = 'Active High-Risk Landslide Zone: Safety-first detour routing around unstable slope segment on NH-06/NH-27.';
      } else {
        hazardDetourDelta = math.max(6.0, (aerial * 0.08 * 10).round() / 10.0);
        hazardPct = '+8%';
        hazardExpl = 'Preventive Weather Detour: Circumvents moisture-saturated valley pass with caution alert.';
      }
    } else {
      hazardDetourDelta = 0.0;
      hazardPct = '0%';
      hazardExpl = 'Direct Hill Cut: No safety detour applied. Fast transit through vulnerable landslide corridor (Disruption: $disruptionProbPct%).';
    }

    // Clause 5: Cargo Risk Protocol Buffer Clause
    final cLower = (cargoTitle ?? '').toLowerCase();
    double cargoDelta = 0.0;
    String cargoExpl = 'General cargo: Standard freight speed and route protocol.';
    String cargoPct = '0%';

    if (cLower.contains('petroleum') || cLower.contains('pol') || cLower.contains('hazardous')) {
      cargoDelta = (aerial * 0.03 * 10).round() / 10.0;
      cargoPct = '+3%';
      cargoExpl = 'HAZMAT / POL Liquids: Mandatory perimeter bypass avoiding congested town center ghats and school zones.';
    } else if (cLower.contains('medical') || cLower.contains('relief')) {
      cargoDelta = 0.0;
      cargoExpl = 'Emergency Medical Relief: High-priority green corridor clearance with zero municipal detours.';
    }

    final computedTotal = ((aerial + curvatureDelta + vehicleDelta + hazardDetourDelta + cargoDelta) * 10).round() / 10.0;
    final totalRoad = overrideRoadKm != null && overrideRoadKm > 0 ? overrideRoadKm : computedTotal;

    // Nominal speed in hill terrain
    double speedKmh = 35.0;
    if (vLower.contains('31t') || vLower.contains('heavy')) {
      speedKmh = 28.0;
    } else if (vLower.contains('bolero') || vLower.contains('4x4')) {
      speedKmh = 42.0;
    }

    final etaText = overrideEtaText != null && overrideEtaText.isNotEmpty
        ? overrideEtaText
        : formatEta(totalRoad, averageSpeedKmh: speedKmh);

    final clauses = <DistanceClauseItem>[
      DistanceClauseItem(
        clauseCode: 'BASE_AERIAL',
        title: 'Geodesic Aerial Base',
        regulatoryRef: 'WGS-84 / Haversine Spherical Model',
        deltaKm: aerialRounded,
        percentageText: 'Base',
        explanation: 'Pure straight-line distance between source and destination GPS coordinates.',
        icon: Icons.straighten_rounded,
        badgeColor: const Color(0xFF2563EB),
      ),
      DistanceClauseItem(
        clauseCode: 'IRC_TERRAIN',
        title: 'IRC:SP:48 Mountain Curvature Clause',
        regulatoryRef: 'Indian Road Congress IRC:SP:48 / D-015',
        deltaKm: curvatureDelta,
        percentageText: '+38%',
        explanation: 'Topographic contour winding factor for North Eastern Region ghats, hairpins, and elevation gradients.',
        icon: Icons.terrain_rounded,
        badgeColor: const Color(0xFF0D9488),
      ),
      DistanceClauseItem(
        clauseCode: 'VEHICLE_AXLE',
        title: 'Vehicle Axle & Weight Clearance Clause',
        regulatoryRef: 'MoRTH Heavy Vehicle Axle Rules & Bridge Limits',
        deltaKm: vehicleDelta,
        percentageText: vehiclePct,
        explanation: vehicleExpl,
        icon: Icons.local_shipping_rounded,
        badgeColor: const Color(0xFF7C3AED),
      ),
      DistanceClauseItem(
        clauseCode: 'HAZARD_DETOUR',
        title: isSafestRoute ? 'Safety Hazard Detour Clause' : 'Direct Pass Clause (No Detour)',
        regulatoryRef: 'TiyraSense D-006 Safety-First Routing Protocol',
        deltaKm: hazardDetourDelta,
        percentageText: hazardPct,
        explanation: hazardExpl,
        icon: isSafestRoute ? Icons.shield_rounded : Icons.flash_on_rounded,
        badgeColor: isSafestRoute ? const Color(0xFF16A34A) : const Color(0xFFD97706),
      ),
    ];

    if (cargoDelta > 0.0) {
      clauses.add(
        DistanceClauseItem(
          clauseCode: 'CARGO_BUFFER',
          title: 'Cargo HAZMAT Protocol Clause',
          regulatoryRef: 'Central Motor Vehicles Rules (CMVR Rule 131)',
          deltaKm: cargoDelta,
          percentageText: cargoPct,
          explanation: cargoExpl,
          icon: Icons.warning_amber_rounded,
          badgeColor: const Color(0xFFDC2626),
        ),
      );
    }

    return DistanceBreakdown(
      baseAerialKm: aerialRounded,
      terrainCurvatureKm: curvatureDelta,
      vehicleAxleKm: vehicleDelta,
      hazardDetourKm: hazardDetourDelta,
      cargoBufferKm: cargoDelta,
      totalRoadKm: totalRoad,
      clauses: clauses,
      estimatedEtaText: etaText,
      nominalSpeedKmh: speedKmh,
    );
  }

  /// Calculates the total length of a polyline in kilometers.
  static double calculatePolylineDistanceKm(List<List<double>> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += haversineKm(
        points[i][0],
        points[i][1],
        points[i + 1][0],
        points[i + 1][1],
      );
    }
    return total;
  }

  /// Formats distance in kilometers or meters with clear readability.
  static String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Estimates travel duration string from distance and average hill speed (km/h).
  static String formatEta(double distanceKm, {double averageSpeedKmh = 35.0}) {
    final totalHours = distanceKm / averageSpeedKmh;
    final hours = totalHours.floor();
    final mins = ((totalHours - hours) * 60).round();
    if (hours > 0) {
      return 'ETA ${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return 'ETA ${mins}m';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
