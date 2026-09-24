import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/offline_storage_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_logo.dart';
import '../widgets/journey_planning_sheet.dart';
import '../widgets/live_notification_card.dart';
import '../widgets/map_layer_sheet.dart';
import '../widgets/slippy_tile_layer.dart';

class NavigationManeuver {
  final IconData icon;
  final String instruction;
  final String subInstruction;
  final double distanceMeters;
  final String roadName;
  final List<String> lanes;
  final int activeLaneIndex;
  final bool isHazard;
  final String? hazardDetails;

  const NavigationManeuver({
    required this.icon,
    required this.instruction,
    required this.subInstruction,
    required this.distanceMeters,
    required this.roadName,
    this.lanes = const ['straight', 'straight'],
    this.activeLaneIndex = 0,
    this.isHazard = false,
    this.hazardDetails,
  });
}

class DriverMapScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ApiService? apiServiceOverride;
  final Map<String, dynamic>? initialRouteData;

  const DriverMapScreen({
    super.key,
    this.onOpenDrawer,
    this.apiServiceOverride,
    this.initialRouteData,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  bool _isNavigating = false;
  int _selectedRoute = 0; // 0 = Recommended, 1 = Faster
  late ApiService _apiService;
  Timer? _telemetryTimer;
  StreamSubscription<LocationResult>? _locationSubscription;
  String? _activeJourneyId;
  Map<String, dynamic>? _selectedRouteData;

  String _originName = 'Guwahati';
  String _destName = 'Shillong';
  String _routeName = 'NH-06 via Nongpoh';
  String _etaText = 'ETA 6h 05m';
  double _originLat = 26.1445;
  double _originLng = 91.7362;
  double _destLat = 25.5788;
  double _destLng = 91.8933;
  double _distanceKm = 98.4;
  double _remainingDistanceKm = 98.4;
  double _currentLat = 26.1445;
  double _currentLng = 91.7362;
  double _currentSpeed = 0.0;
  
  // Camera & Navigation Viewport state (World GIS)
  double _cameraLat = 25.8616;
  double _cameraLng = 91.8147;
  double _cameraZoom = 10.5;
  double _basePinchZoom = 10.5;
  List<dynamic> _forwardHazards = [];
  String? _lastNotifiedHazardKey;
  DistanceBreakdown? _distanceBreakdown;

  AppMapType _mapType = AppMapType.road;
  bool _showAlertsLayer = true;
  bool _showIncidentsLayer = true;

  int _voiceGuidanceMode = 0; // 0 = Sound On, 1 = Alerts Only, 2 = Muted
  int _activeManeuverIndex = 0;
  List<List<double>> _routeCoordinates = [];
  List<NavigationManeuver> _serverManeuvers = [];
  bool _isSafest = true;

  bool _hasLiveGpsFix = false;

  static IconData _getManeuverIcon(String? type, {bool isHazard = false}) {
    if (isHazard) return Icons.warning_amber_rounded;
    switch (type?.toLowerCase()) {
      case 'turn_right':
      case 'right':
        return Icons.turn_right_rounded;
      case 'turn_left':
      case 'left':
        return Icons.turn_left_rounded;
      case 'slight_right':
        return Icons.turn_slight_right_rounded;
      case 'slight_left':
        return Icons.turn_slight_left_rounded;
      case 'sharp_right':
      case 'hairpin_right':
        return Icons.turn_sharp_right_rounded;
      case 'sharp_left':
      case 'hairpin_left':
        return Icons.turn_sharp_left_rounded;
      case 'fork_left':
        return Icons.fork_left_rounded;
      case 'fork_right':
        return Icons.fork_right_rounded;
      case 'roundabout':
        return Icons.roundabout_right_rounded;
      case 'u_turn':
        return Icons.u_turn_left_rounded;
      case 'destination':
      case 'arrive':
        return Icons.place_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  void _applyRouteData(Map<String, dynamic>? data) {
    if (data == null) return;
    _selectedRouteData = data;
    if (data['origin_name'] != null) {
      final o = data['origin_name'].toString();
      _originName = o.split(' ').first;
    }
    if (data['destination_name'] != null) {
      final d = data['destination_name'].toString();
      _destName = d.split(' ').first;
    }
    if (data['name'] != null) _routeName = data['name'].toString();

    if (data['is_recommended_safest'] != null) {
      _isSafest = data['is_recommended_safest'] == true;
    }

    if (data['origin_coords'] != null) {
      final o = data['origin_coords'] as List;
      if (o.length >= 2) {
        _originLat = (o[0] as num).toDouble();
        _originLng = (o[1] as num).toDouble();
        if (!_isNavigating && !_hasLiveGpsFix) {
          _currentLat = _originLat;
          _currentLng = _originLng;
        }
      }
    }
    if (data['destination_coords'] != null) {
      final d = data['destination_coords'] as List;
      if (d.length >= 2) {
        _destLat = (d[0] as num).toDouble();
        _destLng = (d[1] as num).toDouble();
      }
    }

    // Extract true route coordinates (GeoJSON [lng, lat] or [lat, lng])
    final geojson = data['geometry_geojson'];
    List<dynamic>? rawCoords;
    if (geojson is Map && geojson['coordinates'] is List) {
      rawCoords = geojson['coordinates'] as List;
    } else if (data['coordinates'] is List) {
      rawCoords = data['coordinates'] as List;
    }
    if (rawCoords != null && rawCoords.isNotEmpty) {
      _routeCoordinates = rawCoords.map<List<double>>((pt) {
        if (pt is List && pt.length >= 2) {
          final v0 = (pt[0] as num).toDouble();
          final v1 = (pt[1] as num).toDouble();
          if (v0 > 50.0 && v1 < 40.0) {
            return [v1, v0]; // Normalized to [lat, lng]
          }
          return [v0, v1];
        }
        return [0.0, 0.0];
      }).where((pt) => pt[0] != 0.0).toList();
    }

    // Extract server analyzed navigation steps
    if (data['steps'] is List && (data['steps'] as List).isNotEmpty) {
      _serverManeuvers = (data['steps'] as List).map<NavigationManeuver>((s) {
        if (s is Map<String, dynamic>) {
          final mType = s['maneuver_type']?.toString() ?? 'straight';
          final isHaz = s['is_hazard'] == true;
          return NavigationManeuver(
            icon: _getManeuverIcon(mType, isHazard: isHaz),
            instruction: s['instruction']?.toString() ?? 'Proceed on route',
            subInstruction: s['sub_instruction']?.toString() ?? '',
            distanceMeters: (s['distance_meters'] as num?)?.toDouble() ?? 500.0,
            roadName: s['road_name']?.toString() ?? _routeName,
            isHazard: isHaz,
            hazardDetails: s['hazard_alert']?.toString(),
          );
        }
        return const NavigationManeuver(
          icon: Icons.straight_rounded,
          instruction: 'Continue on route',
          subInstruction: 'Follow designated freight corridor',
          distanceMeters: 500,
          roadName: '',
        );
      }).toList();
    }

    if (data['breakdown'] is DistanceBreakdown) {
      _distanceBreakdown = data['breakdown'] as DistanceBreakdown;
    } else {
      _distanceBreakdown = DistanceUtils.computeDetailedBreakdown(
        lat1: _originLat,
        lon1: _originLng,
        lat2: _destLat,
        lon2: _destLng,
        vehicleTitle: vehicleService.selectedVehicle.title,
        cargoTitle: vehicleService.selectedCargo.title,
        isSafestRoute: _selectedRoute == 0,
      );
    }

    if (data['distance_km'] != null) {
      _distanceKm = (data['distance_km'] as num).toDouble();
    } else {
      _distanceKm = _distanceBreakdown?.totalRoadKm ?? DistanceUtils.calculateRoadDistanceKm(_originLat, _originLng, _destLat, _destLng);
    }
    _remainingDistanceKm = _distanceKm;

    if (data['estimated_duration_seconds'] != null) {
      final secs = (data['estimated_duration_seconds'] as num).toDouble();
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      _etaText = 'ETA ${h}h ${m}m';
    } else {
      _etaText = _distanceBreakdown?.estimatedEtaText ?? DistanceUtils.formatEta(_distanceKm, averageSpeedKmh: 35.0);
    }

    _cameraLat = (_originLat + _destLat) / 2.0;
    _cameraLng = (_originLng + _destLng) / 2.0;
    _cameraZoom = 10.5;
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiServiceOverride ?? ApiService();
    _applyRouteData(widget.initialRouteData);
    if (_routeCoordinates.isEmpty && widget.initialRouteData?['geometry_geojson'] == null && widget.initialRouteData?['coordinates'] == null) {
      _fetchRealRoute();
    }
    _fetchCurrentGps(silent: true);
  }

  Future<void> _fetchRealRoute() async {
    try {
      final res = await _apiService.evaluateRoutes(
        origin: {'latitude': _originLat, 'longitude': _originLng, 'label': _originName},
        destination: {'latitude': _destLat, 'longitude': _destLng, 'label': _destName},
      );
      final routes = res['candidate_routes'] ?? res['routes'];
      if (routes is List && routes.isNotEmpty && mounted) {
        setState(() {
          _applyRouteData(routes.first as Map<String, dynamic>);
        });
      }
    } catch (e) {
      // In offline conditions or test environments without backend, gracefully retain default corridor
    }
  }

  @override
  void didUpdateWidget(DriverMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRouteData != oldWidget.initialRouteData) {
      setState(() {
        _applyRouteData(widget.initialRouteData);
      });
    }
  }

  @override
  void dispose() {
    NotificationService().cancelLiveNavigationNotification();
    _locationSubscription?.cancel();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _cameraZoom = (_cameraZoom + 1.0).clamp(5.0, 18.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _cameraZoom = (_cameraZoom - 1.0).clamp(5.0, 18.0);
    });
  }

  void _fitCorridor() {
    setState(() {
      _cameraLat = (_originLat + _destLat) / 2.0;
      _cameraLng = (_originLng + _destLng) / 2.0;
      _cameraZoom = 10.5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.crop_free_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Map centered on active corridor')),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _resetCompassNorth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Map re-oriented to True North (0°)')),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _centerOnVehicleLiveLocation({bool silent = false}) async {
    final loc = await LocationService().getCurrentLocation();
    if (!mounted) return;
    if (loc.isSuccess) {
      final wasDefaultOrigin = _originName == 'Guwahati' || _originName == 'Current Location';
      setState(() {
        _hasLiveGpsFix = true;
        _currentLat = loc.latitude;
        _currentLng = loc.longitude;
        _cameraLat = _currentLat;
        _cameraLng = _currentLng;
        _cameraZoom = 15.0; // Street / vehicle navigation level zoom
        if (wasDefaultOrigin) {
          _originLat = _currentLat;
          _originLng = _currentLng;
        }
      });
      if (wasDefaultOrigin && !_isNavigating) {
        _fetchRealRoute();
      }
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS Locked: Vehicle at ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _cameraLat = _currentLat;
        _cameraLng = _currentLng;
        _cameraZoom = 15.0;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered on active vehicle (${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E)'),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _fetchCurrentGps({bool silent = false}) async {
    await _centerOnVehicleLiveLocation(silent: silent);
  }

  void _toggleNavigation() {
    if (!_isNavigating) {
      // 1. Ensure route coordinates align with current live GPS position
      final double distanceToStart = _routeCoordinates.isNotEmpty
          ? DistanceUtils.calculateRoadDistanceKm(_currentLat, _currentLng, _routeCoordinates.first[0], _routeCoordinates.first[1])
          : 999.0;
      if (distanceToStart > 0.25 && _hasLiveGpsFix) {
        _originLat = _currentLat;
        _originLng = _currentLng;
        _fetchRealRoute();
      }

      setState(() {
        _isNavigating = true;
        _currentSpeed = math.max(_currentSpeed, 40.0);
        _updateManeuverStep();
      });
      final isOnline = offlineStorageService.isOnline;
      final maneuvers = _getManeuvers();
      final firstRoad = maneuvers.isNotEmpty && maneuvers.first.roadName.isNotEmpty
          ? maneuvers.first.roadName
          : (_originName == 'Guwahati' ? 'Ramkrishnapur Rd' : '$_originName Rd');

      NotificationService().showLiveNavigationNotification(
        distanceText: '20 m',
        roadName: firstRoad,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? 'Active guidance engaged: streaming GPS telemetry'
                : '🛰️ Autonomous GPS Satellite Navigation Active (0 Data Required)',
          ),
          backgroundColor: isOnline ? AppTheme.primaryBlue : const Color(0xFF0D652D),
          duration: const Duration(seconds: 2),
        ),
      );

      _initiateJourneySession(isOnline);

      // Cancel previous streams
      _locationSubscription?.cancel();
      _telemetryTimer?.cancel();

      // Listen to hardware GPS updates
      _locationSubscription = LocationService().getPositionStream().listen((loc) async {
        if (!_isNavigating || !mounted) return;
        _hasLiveGpsFix = true;
        setState(() {
          _currentLat = loc.latitude;
          _currentLng = loc.longitude;
          _cameraLat = _currentLat;
          _cameraLng = _currentLng;
          if (loc.speedKmh > 0) _currentSpeed = loc.speedKmh;

          // Off-route check
          if (_routeCoordinates.length > 2) {
            double minDeviationKm = double.infinity;
            for (final pt in _routeCoordinates) {
              final d = DistanceUtils.calculateRoadDistanceKm(_currentLat, _currentLng, pt[0], pt[1]);
              if (d < minDeviationKm) minDeviationKm = d;
            }
            if (minDeviationKm > 0.35) {
              _originLat = _currentLat;
              _originLng = _currentLng;
              _fetchRealRoute();
            }
          }

          // Remaining distance calculation along route polyline
          double remainingKm = 0.0;
          if (_routeCoordinates.length > 1) {
            int closestIndex = 0;
            double minDist = double.infinity;
            for (int i = 0; i < _routeCoordinates.length; i++) {
              final d = DistanceUtils.calculateRoadDistanceKm(
                _currentLat, _currentLng, _routeCoordinates[i][0], _routeCoordinates[i][1]
              );
              if (d < minDist) {
                minDist = d;
                closestIndex = i;
              }
            }
            for (int i = closestIndex; i < _routeCoordinates.length - 1; i++) {
              remainingKm += DistanceUtils.calculateRoadDistanceKm(
                _routeCoordinates[i][0], _routeCoordinates[i][1],
                _routeCoordinates[i + 1][0], _routeCoordinates[i + 1][1]
              );
            }
          }
          if (remainingKm <= 0.1) {
            remainingKm = DistanceUtils.calculateRoadDistanceKm(_currentLat, _currentLng, _destLat, _destLng);
          }
          _remainingDistanceKm = remainingKm.clamp(0.0, _distanceKm);
          _etaText = DistanceUtils.formatEta(_remainingDistanceKm, averageSpeedKmh: math.max(_currentSpeed, 35.0));
          _updateManeuverStep();
        });

        if (_activeJourneyId != null && offlineStorageService.isOnline) {
          try {
            await _apiService.sendTelemetry(
              journeyId: _activeJourneyId!,
              latitude: _currentLat,
              longitude: _currentLng,
              speedKmh: _currentSpeed,
              headingDegrees: loc.heading,
            );

            final tracking = await _apiService.getJourneyTracking(_activeJourneyId!);
            if (mounted) {
              setState(() {
                final hazards = tracking['forward_hazards'] as List<dynamic>?;
                if (hazards != null) {
                  _forwardHazards = hazards;
                  if (hazards.isNotEmpty) {
                    final top = hazards.first;
                    final hType = top['hazard_type'] ?? 'Obstruction';
                    final dist = top['distance_ahead_km'] != null ? (top['distance_ahead_km'] as num).toDouble() : 3.5;
                    final segKey = top['segment_id']?.toString() ?? '$hType-${dist.toStringAsFixed(0)}';
                    if (_lastNotifiedHazardKey != segKey) {
                      _lastNotifiedHazardKey = segKey;
                      NotificationService().showHazardAlert(
                        title: '⚠️ ROAD HAZARD AHEAD ($hType)',
                        body: '$hType detected ${dist.toStringAsFixed(1)} km ahead on active corridor.',
                        payload: top['segment_id']?.toString(),
                      );
                    }
                  } else {
                    _lastNotifiedHazardKey = null;
                  }
                }
              });
            }
          } catch (_) {}
        }
      });

      // Simulation periodic ticker when navigating (heartbeat)
      _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        if (!_isNavigating || !mounted) {
          timer.cancel();
          return;
        }
        if (!_hasLiveGpsFix) {
          setState(() {
            final step = 0.02;
            _currentLat += (_destLat - _currentLat) * step;
            _currentLng += (_destLng - _currentLng) * step;
            _cameraLat = _currentLat;
            _cameraLng = _currentLng;
            _currentSpeed = 42.0;
            final realRemaining = DistanceUtils.calculateRoadDistanceKm(
              _currentLat,
              _currentLng,
              _destLat,
              _destLng,
            );
            _remainingDistanceKm = realRemaining.clamp(0.0, _distanceKm);
            _etaText = DistanceUtils.formatEta(_remainingDistanceKm, averageSpeedKmh: _currentSpeed);
            _updateManeuverStep();
          });
        }

        if (_activeJourneyId != null && offlineStorageService.isOnline) {
          await _apiService.sendTelemetry(
            journeyId: _activeJourneyId!,
            latitude: _currentLat,
            longitude: _currentLng,
            speedKmh: _currentSpeed,
          );
        }
      });
    } else {
      _locationSubscription?.cancel();
      _telemetryTimer?.cancel();
      NotificationService().cancelLiveNavigationNotification();
      setState(() {
        _isNavigating = false;
        _currentSpeed = 0.0;
        _lastNotifiedHazardKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guidance paused'),
          backgroundColor: AppTheme.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _initiateJourneySession(bool isOnline) async {
    try {
      if (isOnline) {
        final res = await _apiService.startJourney(
          routeId: _selectedRouteData?['id']?.toString() ?? 'route-live-safest',
          originCoords: {'latitude': _originLat, 'longitude': _originLng},
          destinationCoords: {'latitude': _destLat, 'longitude': _destLng},
          originName: _originName,
          destinationName: _destName,
          routeName: _routeName,
          routeGeometry: _routeCoordinates.map((c) => [c[1], c[0]]).toList(),
        );
        _activeJourneyId = res['id']?.toString();
        if (_activeJourneyId != null) {
          await _apiService.sendTelemetry(
            journeyId: _activeJourneyId!,
            latitude: _currentLat,
            longitude: _currentLng,
            speedKmh: _currentSpeed,
            headingDegrees: 0.0,
          );
        }
      }
    } catch (_) {}
  }

  void _showLiveNotificationModal() {
    final maneuvers = _getManeuvers();
    final currentManeuver = maneuvers.isNotEmpty ? maneuvers[_activeManeuverIndex] : null;
    final dist = currentManeuver != null ? _getNextManeuverDistanceText(currentManeuver) : '20 m';
    final road = currentManeuver != null && currentManeuver.roadName.isNotEmpty
        ? currentManeuver.roadName
        : (_originName == 'Guwahati' ? 'Ramkrishnapur Rd' : '$_originName Rd');

    // Clean display distance (e.g. "In 20 m" -> "20 m", "Now" -> "20 m")
    String cleanDist = dist;
    if (cleanDist.startsWith('In ')) {
      cleanDist = cleanDist.substring(3);
    } else if (cleanDist.toLowerCase() == 'now') {
      cleanDist = '20 m';
    }

    LiveNotificationLockscreenSheet.show(
      context,
      distanceText: cleanDist,
      roadName: road,
      onExitNavigation: () {
        Navigator.of(context).pop();
        if (_isNavigating) {
          _toggleNavigation();
        }
      },
      onReturnToMap: () => Navigator.of(context).pop(),
    );
  }

  void _openRoutePlanner() {
    JourneyPlanningSheet.show(
      context,
      apiServiceOverride: _apiService,
      onConfirmRoute: (selectedRoute) {
        setState(() {
          _applyRouteData(selectedRoute);
        });
      },
    );
  }

  void _showDistanceClausesModal() {
    final breakdown = _distanceBreakdown ?? DistanceUtils.computeDetailedBreakdown(
      lat1: _originLat,
      lon1: _originLng,
      lat2: _destLat,
      lon2: _destLng,
      vehicleTitle: vehicleService.selectedVehicle.title,
      cargoTitle: vehicleService.selectedCargo.title,
      isSafestRoute: _selectedRoute == 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distance Clauses & Terrain Audit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_originName → $_destName ($_routeName)',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLow),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.container,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${breakdown.totalRoadKm} km',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ROAD DISTANCE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: AppTheme.borderMed),
                    Column(
                      children: [
                        Text(
                          '${breakdown.baseAerialKm} km',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'AERIAL BASE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: AppTheme.borderMed),
                    Column(
                      children: [
                        Text(
                          '+${(breakdown.totalRoadKm - breakdown.baseAerialKm).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'CLAUSES DELTA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'APPLIED CLAUSES BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLow,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: ListView.separated(
                  itemCount: breakdown.clauses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final c = breakdown.clauses[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: c.badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(c.icon, size: 18, color: c.badgeColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textHigh,
                                      ),
                                    ),
                                    Text(
                                      c.regulatoryRef,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: c.badgeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.clauseCode == 'BASE_AERIAL' ? '${c.deltaKm} km' : '+${c.deltaKm} km (${c.percentageText})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: c.badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.explanation,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.3),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close Audit View'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NavigationManeuver> _getManeuvers() {
    if (_serverManeuvers.isNotEmpty) {
      return _serverManeuvers;
    }
    final isSafest = _selectedRoute == 0 || _isSafest;
    return [
      NavigationManeuver(
        icon: Icons.straight_rounded,
        instruction: 'Head towards $_routeName',
        subInstruction: 'Continue straight from $_originName hub',
        distanceMeters: 450,
        roadName: '$_originName Terminal Link',
        lanes: const ['straight', 'straight', 'right'],
        activeLaneIndex: 1,
      ),
      NavigationManeuver(
        icon: Icons.turn_slight_right_rounded,
        instruction: 'Take the ramp onto $_routeName',
        subInstruction: 'Merge onto primary freight corridor',
        distanceMeters: 1200,
        roadName: '$_routeName Express Link',
        lanes: const ['straight', 'right'],
        activeLaneIndex: 1,
      ),
      NavigationManeuver(
        icon: Icons.turn_sharp_left_rounded,
        instruction: 'Caution: Sharp hairpin ghat curve',
        subInstruction: 'MoRTH hill descent speed limit 30 km/h',
        distanceMeters: 800,
        roadName: 'Jorabat Ghat Km 32',
        lanes: const ['left', 'left'],
        activeLaneIndex: 0,
        isHazard: false,
        hazardDetails: 'MoRTH Ghat Incline · 7% Gradient',
      ),
      NavigationManeuver(
        icon: Icons.straight_rounded,
        instruction: 'Continue straight on $_routeName',
        subInstruction: 'Follow corridor towards mid-point checkpoint',
        distanceMeters: (_distanceKm * 0.45 * 1000).clamp(2500.0, 45000.0),
        roadName: '$_routeName Mountain Highway',
        lanes: const ['straight', 'straight'],
        activeLaneIndex: 0,
      ),
      NavigationManeuver(
        icon: isSafest ? Icons.fork_left_rounded : Icons.alt_route_rounded,
        instruction: isSafest
            ? 'Maintain corridor on $_routeName'
            : 'Proceed along direct highway',
        subInstruction: isSafest
            ? 'Designated safe freight alignment'
            : 'Direct express route pass',
        distanceMeters: 1100,
        roadName: 'Freight Corridor Bypass',
        lanes: const ['left', 'straight'],
        activeLaneIndex: 0,
        isHazard: false,
      ),
      NavigationManeuver(
        icon: Icons.turn_right_rounded,
        instruction: 'Turn right towards $_destName Approach',
        subInstruction: 'Incline towards city freight terminus',
        distanceMeters: 750,
        roadName: '$_destName Ridge Corridor',
        lanes: const ['straight', 'right'],
        activeLaneIndex: 1,
      ),
      NavigationManeuver(
        icon: Icons.turn_left_rounded,
        instruction: 'In 350 m, turn left into $_destName Hub',
        subInstruction: 'Final approach to logistics terminal',
        distanceMeters: 350,
        roadName: '$_destName Central Arterial',
        lanes: const ['left', 'straight'],
        activeLaneIndex: 0,
      ),
      NavigationManeuver(
        icon: Icons.place_rounded,
        instruction: 'Arrive at $_destName Hub',
        subInstruction: 'Destination will be on the right',
        distanceMeters: 80,
        roadName: '$_destName Logistics Yard',
        lanes: const ['straight'],
        activeLaneIndex: 0,
      ),
    ];
  }

  void _updateManeuverStep() {
    final maneuvers = _getManeuvers();
    if (maneuvers.isEmpty) return;
    final total = math.max(_distanceKm, 0.1);
    final progress = (1.0 - (_remainingDistanceKm / total)).clamp(0.0, 1.0);
    final idx = (progress * (maneuvers.length - 1)).floor().clamp(0, maneuvers.length - 1);
    _activeManeuverIndex = idx;
  }

  String _getNextManeuverDistanceText(NavigationManeuver m) {
    final maneuvers = _getManeuvers();
    final total = math.max(_distanceKm, 0.1);
    final progress = (1.0 - (_remainingDistanceKm / total)).clamp(0.0, 1.0);
    final totalSteps = maneuvers.length;
    final stepSpan = 1.0 / (totalSteps > 1 ? totalSteps - 1 : 1);
    final stepEndProgress = (_activeManeuverIndex + 1) * stepSpan;
    final stepFractionRemaining = ((stepEndProgress - progress) / stepSpan).clamp(0.0, 1.0);
    final meters = (stepFractionRemaining * m.distanceMeters).round();
    if (meters >= 1000) {
      return '${localizationService.tr('in_distance')} ${(meters / 1000).toStringAsFixed(1)} km';
    } else if (meters <= 40) {
      return localizationService.tr('now');
    } else {
      return '${localizationService.tr('in_distance')} $meters m';
    }
  }

  String _getFormattedArrivalTime() {
    final avgSpeed = math.max(_currentSpeed, 35.0);
    final remainingHours = _remainingDistanceKm / avgSpeed;
    final arrival = DateTime.now().add(Duration(minutes: (remainingHours * 60).round()));
    final hour = arrival.hour > 12 ? arrival.hour - 12 : (arrival.hour == 0 ? 12 : arrival.hour);
    final ampm = arrival.hour >= 12 ? 'PM' : 'AM';
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  String _getFormattedRemainingDuration() {
    final avgSpeed = math.max(_currentSpeed, 35.0);
    final remainingMinutes = ((_remainingDistanceKm / avgSpeed) * 60).round();
    final h = remainingMinutes ~/ 60;
    final m = remainingMinutes % 60;
    if (h > 0) return '${h}h $m min';
    return '$m min';
  }

  void _cycleVoiceGuidance() {
    setState(() {
      _voiceGuidanceMode = (_voiceGuidanceMode + 1) % 3;
    });
    final msg = _voiceGuidanceMode == 0
        ? 'Voice guidance unmuted'
        : (_voiceGuidanceMode == 1 ? 'Voice guidance: Alerts only' : 'Voice guidance muted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showTurnByTurnDirectionsSheet(BuildContext context) {
    final maneuvers = _getManeuvers();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Turn-by-turn Directions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_originName to $_destName via $_routeName',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLow),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: maneuvers.length,
                  separatorBuilder: (_, index) => const Divider(height: 20),
                  itemBuilder: (context, i) {
                    final m = maneuvers[i];
                    final isActive = i == _activeManeuverIndex;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF0D652D)
                                : (m.isHazard ? const Color(0xFFEF4444).withValues(alpha: 0.15) : AppTheme.container),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            m.icon,
                            color: isActive ? Colors.white : (m.isHazard ? const Color(0xFFEF4444) : AppTheme.primaryBlue),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.instruction,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isActive ? const Color(0xFF0D652D) : AppTheme.textHigh,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.subInstruction,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                              ),
                              if (m.roadName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.roadName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLow),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m.distanceMeters >= 1000
                              ? '${(m.distanceMeters / 1000).toStringAsFixed(1)} km'
                              : '${m.distanceMeters.round()} m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? const Color(0xFF0D652D) : AppTheme.textLow,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaneGuidance(List<String> lanes, int activeIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lanes.length, (idx) {
        final isActive = idx == activeIndex;
        IconData laneIcon = Icons.arrow_upward_rounded;
        if (lanes[idx] == 'left') laneIcon = Icons.arrow_back_rounded;
        if (lanes[idx] == 'right') laneIcon = Icons.arrow_forward_rounded;
        if (lanes[idx] == 'slight_right') laneIcon = Icons.turn_slight_right_rounded;
        if (lanes[idx] == 'slight_left') laneIcon = Icons.turn_slight_left_rounded;

        return Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            laneIcon,
            size: 13,
            color: isActive ? const Color(0xFF0D652D) : Colors.white70,
          ),
        );
      }),
    );
  }

  Widget _buildGoogleMapsDirectionHeader() {
    final maneuvers = _getManeuvers();
    final currentManeuver = maneuvers[_activeManeuverIndex];
    final nextManeuver = _activeManeuverIndex + 1 < maneuvers.length
        ? maneuvers[_activeManeuverIndex + 1]
        : null;
    final distanceText = _getNextManeuverDistanceText(currentManeuver);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Deep Teal Green Maneuver Card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF005A53), // Google Maps Rich Teal
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Autonomous GPS Satellite Bar
                ListenableBuilder(
                  listenable: offlineStorageService,
                  builder: (context, _) {
                    final isOnline = offlineStorageService.isOnline;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF00433E) : const Color(0xFF0F172A),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOnline ? Icons.satellite_alt_rounded : Icons.satellite_rounded,
                            size: 13,
                            color: isOnline ? Colors.white70 : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline
                                ? 'ASDMA TELEMETRY ONLINE · CORRIDOR LIVE'
                                : '🛰️ DIRECT SATELLITE GPS · OFFLINE AUTONOMOUS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isOnline ? Colors.white70 : const Color(0xFF38BDF8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.tealAccent.withValues(alpha: 0.25)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOnline ? 'LIVE SYNC' : 'OFFLINE GPS',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isOnline ? Colors.white : const Color(0xFF7DD3FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Primary Turn Guidance Row: Big White Direction Arrow + Instruction Text
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Big white direction arrow (like Google Maps ⬆)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          currentManeuver.icon,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Instruction details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentManeuver.instruction,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentManeuver.roadName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                currentManeuver.roadName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sub-pill with next turn preview (Floating below on left: Then ↰)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004540), // Darker teal sub-pill matching screenshot
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${localizationService.tr('then')}:',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        nextManeuver?.icon ?? Icons.turn_left_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      if (nextManeuver != null) ...[
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            nextManeuver.instruction,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (currentManeuver.lanes.isNotEmpty)
                  _buildLaneGuidance(
                    currentManeuver.lanes,
                    currentManeuver.activeLaneIndex,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerBadge() {
    const speedLimit = 40;
    final isExceeding = _currentSpeed > speedLimit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFDC2626), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizationService.tr('speed_limit'),
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDC2626),
                    height: 1.0,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  '$speedLimit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentSpeed.round()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isExceeding ? const Color(0xFFDC2626) : AppTheme.green,
                  height: 1.0,
                ),
              ),
              const Text(
                'km/h',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLow,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHazardBanner() {
    if (_forwardHazards.isEmpty) return const SizedBox.shrink();
    final top = _forwardHazards.first;
    final hType = top['hazard_type'] ?? 'Obstruction';
    final dist = top['distance_ahead_km'] != null ? (top['distance_ahead_km'] as num).toDouble() : 3.5;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '⚠️ Road Hazard Ahead: $hType (${dist.toStringAsFixed(1)} km)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassButton() {
    return GestureDetector(
      onTap: _resetCompassNorth,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: _CompassNeedlePainter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkNavigationFab({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildGoogleMapsBottomNavigationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF000000), // Pitch Black Google Maps navigation bottom sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Primary Navigation Row: [ ✕ ]  [ Big ETA / Subtitle ]  [ ✨ ]
            Row(
              children: [
                // Left: Circular Close/Cancel navigation button
                InkWell(
                  onTap: _toggleNavigation,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Center: Big Bold ETA and Distance / Arrival Time
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFormattedRemainingDuration(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_remainingDistanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                          Text(
                            _getFormattedArrivalTime().toLowerCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Right: Gemini AI sparkle assistant button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFF60A5FA), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Corridor Copilot: Route clear, optimum hill speed 42 km/h',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF60A5FA), size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Live Telemetry & Guidance Active Pill
            InkWell(
              onTap: _toggleNavigation,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localizationService.tr('live_telemetry_streaming'),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${localizationService.tr('guidance_active')} ($_originName → $_destName)',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF60A5FA),
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary Quick Controls Row: Steps (8), Clauses, Live Notice
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTurnByTurnDirectionsSheet(context),
                    icon: const Icon(Icons.alt_route_rounded, size: 14, color: Colors.white70),
                    label: Text(
                      '${localizationService.tr('steps')} (${_getManeuvers().length})',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDistanceClausesModal,
                    icon: const Icon(Icons.rule_rounded, size: 14, color: Colors.white70),
                    label: Text(
                      localizationService.tr('clauses'),
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showLiveNotificationModal,
                    icon: const Icon(Icons.notifications_active_rounded, size: 14, color: Color(0xFF60A5FA)),
                    label: const Text(
                      'Live Notice',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6), width: 1.1),
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: _isNavigating
          ? null
          : AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              leading: widget.onOpenDrawer != null
                  ? IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppTheme.textHigh),
                      onPressed: widget.onOpenDrawer,
                    )
                  : const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: AppLogo.icon(size: 36, radius: 9),
                    ),
              title: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.my_location_rounded, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        'NH-06 Km 52.4',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: const [
                Icon(Icons.layers_outlined, color: AppTheme.textLow, size: 22),
                SizedBox(width: 12),
                Icon(Icons.search_rounded, color: AppTheme.textLow, size: 22),
                SizedBox(width: 16),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AppTheme.borderLight, height: 1),
              ),
            ),
      body: Stack(
        children: [
          // Interactive Map Canvas Representation with Authentic Slippy Tile Layer
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _zoomIn,
              onScaleStart: (details) {
                _basePinchZoom = _cameraZoom;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Pinch to zoom
                  if (details.scale != 1.0) {
                    _cameraZoom = (_basePinchZoom + (math.log(details.scale) / math.ln2)).clamp(5.0, 18.0);
                  }
                  // Pan drag: translate screen pixels into geographic coordinates
                  final int z = _cameraZoom.floor().clamp(1, 19);
                  final double subScale = math.pow(2.0, _cameraZoom - z).toDouble();
                  final worldCenter = SlippyTileLayer.latLngToWorld(_cameraLat, _cameraLng, z);
                  final newWx = worldCenter.dx - (details.focalPointDelta.dx / subScale);
                  final newWy = worldCenter.dy - (details.focalPointDelta.dy / subScale);
                  final newLatLng = SlippyTileLayer.worldToLatLng(newWx, newWy, z);
                  _cameraLat = newLatLng.dx.clamp(-85.0, 85.0);
                  _cameraLng = newLatLng.dy.clamp(-180.0, 180.0);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SlippyTileLayer(
                    centerLat: _cameraLat,
                    centerLng: _cameraLng,
                    zoom: _cameraZoom,
                    panOffset: Offset.zero,
                    mapType: _mapType,
                  ),
                  CustomPaint(
                    painter: _DriverMapPainter(
                      originLat: _originLat,
                      originLng: _originLng,
                      originName: _originName,
                      destLat: _destLat,
                      destLng: _destLng,
                      destName: _destName,
                      currentLat: _currentLat,
                      currentLng: _currentLng,
                      currentSpeed: _currentSpeed,
                      isNavigating: _isNavigating,
                      distanceKm: _distanceKm,
                      remainingDistanceKm: _remainingDistanceKm,
                      forwardHazards: _forwardHazards,
                      cameraLat: _cameraLat,
                      cameraLng: _cameraLng,
                      cameraZoom: _cameraZoom,
                      zoomLevel: _cameraZoom,
                      panOffset: Offset.zero,
                      routeCoordinates: _routeCoordinates,
                      isSafest: _selectedRoute == 0 || _isSafest,
                      mapType: _mapType,
                      showAlerts: _showAlertsLayer,
                      showIncidents: _showIncidentsLayer,
                      currentRoadName: _getManeuvers().isNotEmpty && _activeManeuverIndex < _getManeuvers().length
                          ? _getManeuvers()[_activeManeuverIndex].roadName
                          : '',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-right floating controls:
          // When navigating: Google Maps dark navigation FABs (Compass, Search, Voice, Fork, Hazard, Layers)
          // When planning: Standard map controls (Layers, North, GPS, Zoom +, Zoom -, Center)
          if (_isNavigating)
            Positioned(
              top: _forwardHazards.isNotEmpty ? 190 : 155,
              right: 14,
              child: Column(
                children: [
                  _buildCompassButton(),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: Icons.search_rounded,
                    tooltip: 'Search along route',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Search along corridor: Fuel, Rest stops, Emergency'),
                          backgroundColor: AppTheme.primaryBlue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: _voiceGuidanceMode == 0
                        ? Icons.volume_up_rounded
                        : (_voiceGuidanceMode == 1
                            ? Icons.notification_important_rounded
                            : Icons.volume_off_rounded),
                    iconColor: _voiceGuidanceMode == 2 ? Colors.white54 : Colors.white,
                    tooltip: 'Voice Guidance',
                    onTap: _cycleVoiceGuidance,
                  ),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: Icons.alt_route_rounded,
                    tooltip: 'Alternative Routes',
                    onTap: () => _showTurnByTurnDirectionsSheet(context),
                  ),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    tooltip: 'Report Road Hazard',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report hazard: Landslide, Waterlogging, Obstruction'),
                          backgroundColor: Color(0xFFD97706),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: Icons.layers_rounded,
                    iconColor: _mapType != AppMapType.road ? const Color(0xFF16A34A) : Colors.white,
                    tooltip: 'Map Layers',
                    onTap: () {
                      MapLayerSheet.show(
                        context: context,
                        currentMapType: _mapType,
                        showAlerts: _showAlertsLayer,
                        showIncidents: _showIncidentsLayer,
                        onMapTypeChanged: (type) => setState(() => _mapType = type),
                        onToggleAlerts: (val) => setState(() => _showAlertsLayer = val),
                        onToggleIncidents: (val) => setState(() => _showIncidentsLayer = val),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDarkNavigationFab(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFF60A5FA),
                    tooltip: 'Live Lockscreen Notification',
                    onTap: _showLiveNotificationModal,
                  ),
                ],
              ),
            )
          else
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapActionButton(
                    icon: Icons.layers_rounded,
                    color: _mapType != AppMapType.road ? const Color(0xFF16A34A) : AppTheme.primaryBlue,
                    onTap: () {
                      MapLayerSheet.show(
                        context: context,
                        currentMapType: _mapType,
                        showAlerts: _showAlertsLayer,
                        showIncidents: _showIncidentsLayer,
                        onMapTypeChanged: (type) => setState(() => _mapType = type),
                        onToggleAlerts: (val) => setState(() => _showAlertsLayer = val),
                        onToggleIncidents: (val) => setState(() => _showIncidentsLayer = val),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMapActionButton(
                    icon: Icons.explore_outlined,
                    color: AppTheme.textMid,
                    onTap: _resetCompassNorth,
                  ),
                  const SizedBox(height: 10),
                  _buildMapActionButton(
                    icon: Icons.my_location_rounded,
                    color: AppTheme.primaryBlue,
                    onTap: () => _centerOnVehicleLiveLocation(silent: false),
                  ),
                  const SizedBox(height: 10),
                  _buildMapActionButton(
                    icon: Icons.add_rounded,
                    color: AppTheme.textHigh,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 10),
                  _buildMapActionButton(
                    icon: Icons.remove_rounded,
                    color: AppTheme.textHigh,
                    onTap: _zoomOut,
                  ),
                  const SizedBox(height: 10),
                  _buildMapActionButton(
                    icon: Icons.center_focus_strong_rounded,
                    color: AppTheme.primaryBlue,
                    onTap: _fitCorridor,
                  ),
                ],
              ),
            ),

          // Left side: Speedometer badge (when navigating) or Legend pill (when planning)
          if (_isNavigating)
            Positioned(
              top: _forwardHazards.isNotEmpty ? 190 : 155,
              left: 14,
              child: _buildSpeedometerBadge(),
            )
          else
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MapLegendRow(color: AppTheme.green, label: 'Open'),
                    SizedBox(height: 6),
                    _MapLegendRow(color: AppTheme.amber, label: 'Caution'),
                    SizedBox(height: 6),
                    _MapLegendRow(color: AppTheme.red, label: 'Risk'),
                  ],
                ),
              ),
            ),

          // Bottom-Left "Re-centre" floating button (when navigating)
          if (_isNavigating)
            Positioned(
              bottom: 140,
              left: 14,
              child: GestureDetector(
                onTap: () {
                  _centerOnVehicleLiveLocation(silent: false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Re-centre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Google Maps Top Green Maneuver Card (When Navigating)
          if (_isNavigating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGoogleMapsDirectionHeader(),
                    if (_forwardHazards.isNotEmpty) _buildHazardBanner(),
                  ],
                ),
              ),
            ),

          // Bottom Peek Card: Google Maps Navigation Card (When Navigating) or Planning Card (When Planning)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isNavigating
                ? _buildGoogleMapsBottomNavigationCard()
                : Center(
                    child: ResponsiveWrapper(
                      maxWidth: 640,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 180),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
                          boxShadow: AppTheme.navShadow,
                        ),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.borderMed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Route title and ETA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$_originName → $_destName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textHigh,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _openRoutePlanner,
                              child: Text(
                                localizationService.tr('change_route'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _selectedRoute == 0 ? '$_etaText  ' : 'ETA 5h 20m  ',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _selectedRoute == 0
                                          ? '· ${_distanceKm.toStringAsFixed(1)} km via $_routeName'
                                          : '· 84.1 km via Bypass',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _showDistanceClausesModal,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.blueLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rule_rounded, size: 12, color: AppTheme.primaryBlue),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clauses',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Route choice chips
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedRoute = 0);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _selectedRoute == 0 ? AppTheme.greenBg : AppTheme.container,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedRoute == 0 ? AppTheme.green : AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Recommended (Safest)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRoute == 0 ? AppTheme.green : AppTheme.textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedRoute = 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _selectedRoute == 1 ? AppTheme.amberBg : AppTheme.container,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedRoute == 1 ? AppTheme.amber : AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(color: AppTheme.amber, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Faster (+Risk)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRoute == 1 ? AppTheme.amber : AppTheme.textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Navigate Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _toggleNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  localizationService.tr('navigate'),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

class _MapLegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textHigh,
          ),
        ),
      ],
    );
  }
}

class _DriverMapPainter extends CustomPainter {
  final double originLat;
  final double originLng;
  final String originName;
  final double destLat;
  final double destLng;
  final String destName;
  final double currentLat;
  final double currentLng;
  final double currentSpeed;
  final bool isNavigating;
  final double distanceKm;
  final double remainingDistanceKm;
  final List<dynamic> forwardHazards;
  final double? cameraLat;
  final double? cameraLng;
  final double? cameraZoom;
  final double zoomLevel;
  final Offset panOffset;
  final List<List<double>> routeCoordinates;
  final bool isSafest;

  final AppMapType mapType;
  final bool showAlerts;
  final bool showIncidents;
  final String? currentRoadName;

  _DriverMapPainter({
    required this.originLat,
    required this.originLng,
    required this.originName,
    required this.destLat,
    required this.destLng,
    required this.destName,
    required this.currentLat,
    required this.currentLng,
    required this.currentSpeed,
    required this.isNavigating,
    required this.distanceKm,
    required this.remainingDistanceKm,
    required this.forwardHazards,
    this.cameraLat,
    this.cameraLng,
    this.cameraZoom,
    required this.zoomLevel,
    required this.panOffset,
    this.routeCoordinates = const [],
    this.isSafest = true,
    this.mapType = AppMapType.road,
    this.showAlerts = true,
    this.showIncidents = true,
    this.currentRoadName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerLat = cameraLat ?? ((originLat + destLat) / 2.0);
    final double centerLng = cameraLng ?? ((originLng + destLng) / 2.0);
    final double effectiveZoom = cameraZoom ?? (10.0 + (math.log(zoomLevel) / math.ln2)).clamp(5.0, 18.0);
    final double cosLat = math.cos(centerLat * math.pi / 180.0);

    Offset toScreen(double lat, double lng) {
      return SlippyTileLayer.toScreenCoord(
        lat: lat,
        lng: lng,
        centerLat: centerLat,
        centerLng: centerLng,
        zoom: effectiveZoom,
        screenSize: size,
        panOffset: panOffset,
      );
    }

    // Mountain Elevation Peaks (Highlighted specifically in Terrain mode)
    if (mapType == AppMapType.terrain) {
      _drawPeakMarker(canvas, toScreen(25.54, 91.88), '▲ Mt. Shillong 1,961m');
      _drawPeakMarker(canvas, toScreen(25.15, 93.02), '▲ Barail Range 1,850m');
    }

    // Regional Highway Network (Connective Arteries)
    _drawRegionalRoadNetwork(canvas, toScreen, mapType);

    // Project Origin, Destination, and Current Location
    final originPos = toScreen(originLat, originLng);
    final destPos = toScreen(destLat, destLng);
    final currentPos = toScreen(currentLat, currentLng);

    // 7. Vector road geometry for Active Route
    final safePath = Path();
    if (routeCoordinates.length >= 2) {
      final pts = routeCoordinates.map((c) => toScreen(c[0], c[1])).toList();
      safePath.moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        safePath.lineTo(pts[i].dx, pts[i].dy);
      }
    } else {
      final dx = destPos.dx - originPos.dx;
      final dy = destPos.dy - originPos.dy;
      final perpX = -dy * 0.15;
      final perpY = dx * 0.15;

      final cp1 = Offset(originPos.dx * 0.6 + destPos.dx * 0.4 + perpX, originPos.dy * 0.6 + destPos.dy * 0.4 + perpY);
      final cp2 = Offset(originPos.dx * 0.3 + destPos.dx * 0.7 - perpX * 0.8, originPos.dy * 0.3 + destPos.dy * 0.7 - perpY * 0.8);

      safePath.moveTo(originPos.dx, originPos.dy);
      safePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, destPos.dx, destPos.dy);
    }

    // Active Highway Styling
    final roadCasingPaint = Paint()
      ..color = (mapType == AppMapType.satellite ? const Color(0xFF0F172A) : const Color(0xFF1E293B)).withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Color routeCoreColor;
    if (mapType == AppMapType.satellite) {
      routeCoreColor = isSafest ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B);
    } else if (mapType == AppMapType.terrain) {
      routeCoreColor = isSafest ? const Color(0xFF047857) : const Color(0xFFD97706);
    } else {
      routeCoreColor = isSafest ? const Color(0xFF059669) : const Color(0xFF0284C7);
    }

    final safeGlowPaint = Paint()
      ..color = routeCoreColor.withValues(alpha: mapType == AppMapType.satellite ? 0.45 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final safeRoutePaint = Paint()
      ..color = routeCoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final laneStripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(safePath, safeGlowPaint);
    canvas.drawPath(safePath, roadCasingPaint);
    canvas.drawPath(safePath, safeRoutePaint);
    canvas.drawPath(safePath, laneStripePaint);

    // Direction chevrons in navigation mode
    if (isNavigating) {
      final chevronPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pathMetrics = safePath.computeMetrics();
      for (final metric in pathMetrics) {
        final length = metric.length;
        for (double d = 25.0; d < length - 15.0; d += 40.0) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) {
            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            canvas.rotate(tangent.angle);
            final chevron = Path()
              ..moveTo(-4, -4)
              ..lineTo(3, 0)
              ..lineTo(-4, 4);
            canvas.drawPath(chevron, chevronPaint);
            canvas.restore();
          }
        }
      }
    }

    // 8. Alerts Layer (Only rendered when showAlerts == true)
    if (showAlerts) {
      // Forward Hazards
      if (forwardHazards.isNotEmpty) {
        final midX = (originPos.dx + destPos.dx) / 2;
        final midY = (originPos.dy + destPos.dy) / 2;
        final hazardPos = Offset(midX, midY - 20);
        _drawHazardBeacon(canvas, hazardPos, const Color(0xFFEF4444), 'ALT: Ahead Hazard');
      }

      // Live Corridor Alerts
      _drawHazardBeacon(canvas, toScreen(25.9820, 91.8850), const Color(0xFFF59E0B), 'ALT: Nongpoh Landslide');
      _drawHazardBeacon(canvas, toScreen(25.6812, 93.7145), const Color(0xFF38BDF8), 'ALT: Zubza Flood Watch');
    }

    // 9. Incidents Layer (Only rendered when showIncidents == true)
    if (showIncidents) {
      _drawIncidentBeacon(canvas, toScreen(26.0124, 91.8901), const Color(0xFFDC2626), 'INC: Boulder Roll');
      _drawIncidentBeacon(canvas, toScreen(25.7500, 91.9010), const Color(0xFFEA580C), 'INC: Heavy Fog Sector');
    }

    // 10. Origin and Destination Pins
    if (!isNavigating) {
      _drawPin(canvas, originPos, AppTheme.green, originName, 'START');
    }
    _drawPin(canvas, destPos, AppTheme.primaryBlue, destName, 'DEST');

    // 8. Draw Live Vehicle Position Beacon (Google Maps 3D navigation arrow when navigating)
    if (isNavigating) {
      final headingAngle = math.atan2(destPos.dy - currentPos.dy, destPos.dx - currentPos.dx);

      // Radar pulse wave
      canvas.drawCircle(currentPos, 24, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.2));
      canvas.drawCircle(currentPos, 16, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.15));

      // 3D Navigation Arrow rotated along heading
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(headingAngle);

      // Drop shadow
      final shadowArrow = Path()
        ..moveTo(14, 0)
        ..lineTo(-10, -9)
        ..lineTo(-5, 0)
        ..lineTo(-10, 9)
        ..close();
      canvas.drawPath(shadowArrow, Paint()..color = Colors.black.withValues(alpha: 0.35));

      // White boundary
      final outlineArrow = Path()
        ..moveTo(15, 0)
        ..lineTo(-10, -10)
        ..lineTo(-5, 0)
        ..lineTo(-10, 10)
        ..close();
      canvas.drawPath(outlineArrow, Paint()..color = Colors.white..style = PaintingStyle.fill);

      // Cyan / Royal Blue Navigation Pointer
      final navArrow = Path()
        ..moveTo(13, 0)
        ..lineTo(-8, -8)
        ..lineTo(-4, 0)
        ..lineTo(-8, 8)
        ..close();
      canvas.drawPath(navArrow, Paint()..color = const Color(0xFF0284C7)..style = PaintingStyle.fill);

      canvas.restore();

      // Draw road name tag on vehicle callout (like Google Maps "Ramkrishnapur Rd")
      final displayRoad = (currentRoadName != null && currentRoadName!.isNotEmpty)
          ? currentRoadName!
          : (originName == 'Guwahati' ? 'Ramkrishnapur Rd' : '$originName Express');
      _drawVehicleRoadTag(canvas, currentPos, displayRoad);

      // Road hazard caution badge on corridor ("⚠️ Narrow road")
      final hazardMid = Offset((originPos.dx + destPos.dx) / 2 + 35, (originPos.dy + destPos.dy) / 2 - 25);
      _drawRoadHazardPill(canvas, hazardMid, 'Narrow road');
    } else {
      // Standard standby beacon
      canvas.drawCircle(currentPos, 18, Paint()..color = AppTheme.primaryBlue.withValues(alpha: 0.2));
      canvas.drawCircle(currentPos, 10, Paint()..color = Colors.white);
      canvas.drawCircle(currentPos, 7, Paint()..color = AppTheme.primaryBlue);
      canvas.drawCircle(currentPos, 3, Paint()..color = Colors.white);
    }

    // 9. Draw GIS Scale Bar (bottom left)
    _drawScaleBar(canvas, size, effectiveZoom, cosLat);
  }

  void _drawRegionalRoadNetwork(Canvas canvas, Offset Function(double, double) toScreen, AppMapType type) {
    final Color roadColor;
    final Color casingColor;
    final double roadWidth;

    if (type == AppMapType.satellite) {
      roadColor = const Color(0xFF64748B).withValues(alpha: 0.85);
      casingColor = const Color(0xFF0F172A).withValues(alpha: 0.95);
      roadWidth = 2.8;
    } else if (type == AppMapType.terrain) {
      roadColor = const Color(0xFF78716C);
      casingColor = const Color(0xFFE7E5E4);
      roadWidth = 2.6;
    } else {
      roadColor = const Color(0xFF94A3B8);
      casingColor = Colors.white;
      roadWidth = 3.0;
    }

    final casingPaint = Paint()
      ..color = casingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth + 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Actual North-Eastern Region National Highways
    final highways = [
      // NH-06: Guwahati -> Jorabat -> Nongpoh -> Shillong -> Jowai
      [
        [26.1445, 91.7362],
        [26.1102, 91.8900],
        [25.9015, 91.8805],
        [25.6800, 91.9050],
        [25.5788, 91.8933],
        [25.4500, 92.2000],
      ],
      // NH-27: Guwahati -> Nagaon -> Lumding
      [
        [26.1445, 91.7362],
        [26.1800, 92.1500],
        [26.3500, 92.6800],
        [25.7500, 93.1700],
      ],
      // NH-29: Dimapur -> Kohima
      [
        [25.9064, 93.7275],
        [25.8200, 93.8500],
        [25.6751, 94.1086],
      ],
      // NH-37: Nagaon -> Kaziranga -> Jorhat
      [
        [26.3500, 92.6800],
        [26.5800, 93.1700],
        [26.7509, 94.2037],
      ],
    ];

    for (final hwy in highways) {
      final path = Path();
      final pts = hwy.map((pt) => toScreen(pt[0], pt[1])).toList();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        final prev = pts[i - 1];
        final curr = pts[i];
        final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
      canvas.drawPath(path, casingPaint);
      canvas.drawPath(path, roadPaint);
    }
  }

  void _drawPeakMarker(Canvas canvas, Offset pos, String label) {
    final peakPaint = Paint()
      ..color = const Color(0xFF4D7C0F)
      ..style = PaintingStyle.fill;

    final peakPath = Path()
      ..moveTo(pos.dx, pos.dy - 10)
      ..lineTo(pos.dx - 8, pos.dy + 4)
      ..lineTo(pos.dx + 8, pos.dy + 4)
      ..close();
    canvas.drawPath(peakPath, peakPaint);

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xFF365314),
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + 6));
  }

  void _drawHazardBeacon(Canvas canvas, Offset pos, Color color, String label) {
    // Pulse ring
    canvas.drawCircle(pos, 16, Paint()..color = color.withValues(alpha: 0.20));
    canvas.drawCircle(pos, 10, Paint()..color = color.withValues(alpha: 0.35));
    // Core dot
    canvas.drawCircle(pos, 6, Paint()..color = color);
    canvas.drawCircle(pos, 2, Paint()..color = Colors.white);

    // Label pill
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pos.dx - (textPainter.width / 2) - 6,
        pos.dy - 24,
        textPainter.width + 12,
        16,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(pillRect, Paint()..color = color.withValues(alpha: 0.90));
    textPainter.paint(
      canvas,
      Offset(pos.dx - (textPainter.width / 2), pos.dy - 22),
    );
  }

  void _drawIncidentBeacon(Canvas canvas, Offset pos, Color color, String label) {
    // Diamond hazard icon
    final diamondPath = Path()
      ..moveTo(pos.dx, pos.dy - 10)
      ..lineTo(pos.dx + 8, pos.dy)
      ..lineTo(pos.dx, pos.dy + 10)
      ..lineTo(pos.dx - 8, pos.dy)
      ..close();

    canvas.drawPath(diamondPath, Paint()..color = color);
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);

    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pos.dx - (textPainter.width / 2) - 5,
        pos.dy + 12,
        textPainter.width + 10,
        15,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    textPainter.paint(
      canvas,
      Offset(pos.dx - (textPainter.width / 2), pos.dy + 13),
    );
  }

  void _drawPin(Canvas canvas, Offset pos, Color color, String name, String tag) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawCircle(pos.translate(0, 2), 9, shadowPaint);

    final pinPaint = Paint()..color = color;
    canvas.drawCircle(pos, 8, pinPaint);
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);

    final textSpan = TextSpan(
      text: '$name ($tag)',
      style: const TextStyle(
        color: AppTheme.textHigh,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        backgroundColor: Colors.transparent,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pos.dx - (textPainter.width / 2) - 6,
        pos.dy - 26,
        textPainter.width + 12,
        18,
      ),
      const Radius.circular(9),
    );

    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = AppTheme.borderLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    textPainter.paint(
      canvas,
      Offset(pos.dx - (textPainter.width / 2), pos.dy - 24),
    );
  }

  void _drawScaleBar(Canvas canvas, Size size, double zoom, double cosLat) {
    final metersPerPixel = (156543.03392 * math.max(cosLat, 0.1)) / math.pow(2.0, zoom);
    double targetKm = 10.0;
    if (metersPerPixel * 100 > 25000) {
      targetKm = 50.0;
    } else if (metersPerPixel * 100 < 5000) {
      targetKm = 2.0;
    }
    final barPx = (targetKm * 1000.0 / metersPerPixel).clamp(35.0, 120.0);
    final actualKm = (barPx * metersPerPixel / 1000.0).round();

    final barLeft = 16.0;
    final barTop = size.height - 180.0;
    final barColor = mapType == AppMapType.satellite ? Colors.white70 : AppTheme.textHigh;

    final barPaint = Paint()
      ..color = barColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(barLeft, barTop - 4)
      ..lineTo(barLeft, barTop)
      ..lineTo(barLeft + barPx, barTop)
      ..lineTo(barLeft + barPx, barTop - 4);
    canvas.drawPath(path, barPaint);

    final textSpan = TextSpan(
      text: '$actualKm km',
      style: TextStyle(
        color: barColor,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(barLeft + (barPx - textPainter.width) / 2, barTop + 4));
  }

  void _drawRoadHazardPill(Canvas canvas, Offset pos, String label) {
    final textSpan = TextSpan(
      children: [
        const TextSpan(
          text: '⚠️ ',
          style: TextStyle(fontSize: 9),
        ),
        TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillW = textPainter.width + 16;
    const pillH = 20.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx - pillW / 2, pos.dy - pillH / 2, pillW, pillH),
      const Radius.circular(10),
    );

    // Drop shadow
    canvas.drawRRect(
      pillRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Yellow Caution fill
    canvas.drawRRect(pillRect, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  void _drawVehicleRoadTag(Canvas canvas, Offset pos, String roadName) {
    final textSpan = TextSpan(
      text: roadName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillW = textPainter.width + 14;
    const pillH = 19.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx + 16, pos.dy - pillH / 2, pillW, pillH),
      const Radius.circular(5),
    );

    // Blue pill tag (#1D4ED8)
    canvas.drawRRect(
      pillRect.shift(const Offset(0, 1.2)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRRect(pillRect, Paint()..color = const Color(0xFF1D4ED8));
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    textPainter.paint(
      canvas,
      Offset(pos.dx + 23, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DriverMapPainter old) {
    return old.cameraLat != cameraLat ||
        old.cameraLng != cameraLng ||
        old.cameraZoom != cameraZoom ||
        old.currentLat != currentLat ||
        old.currentLng != currentLng ||
        old.zoomLevel != zoomLevel ||
        old.panOffset != panOffset ||
        old.originLat != originLat ||
        old.destLat != destLat ||
        old.isNavigating != isNavigating ||
        old.routeCoordinates != routeCoordinates ||
        old.isSafest != isSafest ||
        old.mapType != mapType ||
        old.showAlerts != showAlerts ||
        old.showIncidents != showIncidents;
  }
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.32;
    final h = size.height * 0.46;

    // North needle (Red)
    final northRightPath = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(northRightPath, Paint()..color = const Color(0xFFEF4444));

    final northLeftPath = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx - w, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(northLeftPath, Paint()..color = const Color(0xFFDC2626));

    // South needle (White/Light grey)
    final southRightPath = Path()
      ..moveTo(cx, cy + h)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(southRightPath, Paint()..color = const Color(0xFFF1F5F9));

    final southLeftPath = Path()
      ..moveTo(cx, cy + h)
      ..lineTo(cx - w, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(southLeftPath, Paint()..color = const Color(0xFFCBD5E1));

    // Center pivot dot
    canvas.drawCircle(Offset(cx, cy), 2.2, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

