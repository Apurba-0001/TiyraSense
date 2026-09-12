import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_utils.dart';

class JourneyPlanningSheet extends StatefulWidget {
  final VoidCallback? onConfirmRoute;
  final ValueChanged<Map<String, dynamic>>? onRouteSelected;
  final ApiService? apiServiceOverride;

  const JourneyPlanningSheet({
    super.key,
    this.onConfirmRoute,
    this.onRouteSelected,
    this.apiServiceOverride,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onConfirm,
    ValueChanged<Map<String, dynamic>>? onConfirmRoute,
    ValueChanged<Map<String, dynamic>>? onRouteSelected,
    ApiService? apiServiceOverride,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JourneyPlanningSheet(
        onConfirmRoute: onConfirm,
        onRouteSelected: onRouteSelected ?? onConfirmRoute,
        apiServiceOverride: apiServiceOverride,
      ),
    );
  }

  @override
  State<JourneyPlanningSheet> createState() => _JourneyPlanningSheetState();
}

class _JourneyPlanningSheetState extends State<JourneyPlanningSheet> {
  String _origin = 'Guwahati Port Hub';
  String _destination = 'Shillong Terminal Hub';
  List<double>? _originCoords = [26.1445, 91.7362];
  List<double>? _destinationCoords = [25.5788, 91.8933];
  String _vehicle = 'Tata Prima 31T';
  String _cargo = 'FMCG Critical';
  int _selectedRoute = 0; // 0 = Recommended, 1 = Faster
  bool _isLoadingRoutes = false;
  late ApiService _apiService;
  late List<Map<String, dynamic>> _candidateRoutes;

  static const Map<String, List<double>> _knownHubCoords = {
    'Guwahati': [26.1445, 91.7362],
    'Shillong': [25.5788, 91.8933],
    'Silchar': [24.8333, 92.7789],
    'Dimapur': [25.9060, 93.7270],
    'Kohima': [25.6751, 94.1086],
    'Aizawl': [23.7271, 92.7176],
    'Imphal': [24.8170, 93.9368],
    'Tezpur': [26.6528, 92.7926],
    'Jorhat': [26.7509, 94.2037],
    'Agartala': [23.8315, 91.2868],
  };

  @override
  void initState() {
    super.initState();
    _vehicle = vehicleService.selectedVehicle.title;
    _cargo = vehicleService.selectedCargo.title;
    _apiService = widget.apiServiceOverride ?? ApiService();
    _initializeFallbackRoutes();
    _fetchLiveCandidateRoutes();
  }

  void _initializeFallbackRoutes() {
    final oCoords = _resolveCoordinates(_origin, isOrigin: true);
    final dCoords = _resolveCoordinates(_destination, isOrigin: false);

    final safestBreakdown = DistanceUtils.computeDetailedBreakdown(
      lat1: oCoords[0],
      lon1: oCoords[1],
      lat2: dCoords[0],
      lon2: dCoords[1],
      vehicleTitle: _vehicle,
      cargoTitle: _cargo,
      isSafestRoute: true,
      disruptionProbPct: 14,
    );

    final fasterBreakdown = DistanceUtils.computeDetailedBreakdown(
      lat1: oCoords[0],
      lon1: oCoords[1],
      lat2: dCoords[0],
      lon2: dCoords[1],
      vehicleTitle: _vehicle,
      cargoTitle: _cargo,
      isSafestRoute: false,
      disruptionProbPct: 18,
    );

    _candidateRoutes = [
      {
        'id': 'route-safest-default',
        'name': 'Route A · NH-06 via Nongpoh',
        'classification': 'SAFEST_VIABLE',
        'distance_km': safestBreakdown.totalRoadKm,
        'eta_text': safestBreakdown.estimatedEtaText,
        'disruption_prob_pct': 14,
        'risk_level': 'LOW',
        'is_recommended': true,
        'is_recommended_safest': true,
        'is_fastest_available': false,
        'origin_name': _origin,
        'destination_name': _destination,
        'origin_coords': oCoords,
        'destination_coords': dCoords,
        'breakdown': safestBreakdown,
      },
      {
        'id': 'route-faster-default',
        'name': 'Route B · Direct Expressway Corridor',
        'classification': 'FASTEST_AVAILABLE',
        'distance_km': fasterBreakdown.totalRoadKm,
        'eta_text': fasterBreakdown.estimatedEtaText,
        'disruption_prob_pct': 18,
        'risk_level': 'LOW',
        'is_recommended': false,
        'is_recommended_safest': false,
        'is_fastest_available': true,
        'origin_name': _origin,
        'destination_name': _destination,
        'origin_coords': oCoords,
        'destination_coords': dCoords,
        'breakdown': fasterBreakdown,
      },
    ];
  }

  List<double> _resolveCoordinates(String location, {bool isOrigin = true}) {
    if (isOrigin && _originCoords != null) return _originCoords!;
    if (!isOrigin && _destinationCoords != null) return _destinationCoords!;

    final regex = RegExp(r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)');
    final match = regex.firstMatch(location.trim());
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) {
        return [lat, lng];
      }
    }
    for (final entry in _knownHubCoords.entries) {
      if (location.toLowerCase().contains(entry.key.split(' ').first.toLowerCase())) {
        return entry.value;
      }
    }
    return isOrigin ? [26.1445, 91.7362] : [25.5788, 91.8933];
  }

  Future<void> _fetchLiveCandidateRoutes() async {
    final oCoords = _resolveCoordinates(_origin, isOrigin: true);
    final dCoords = _resolveCoordinates(_destination, isOrigin: false);
    if (mounted) setState(() => _isLoadingRoutes = true);
    try {
      final response = await _apiService.evaluateRoutes(
        origin: {'latitude': oCoords[0], 'longitude': oCoords[1], 'name': _origin},
        destination: {'latitude': dCoords[0], 'longitude': dCoords[1], 'name': _destination},
        vehicleClass: _vehicle.toLowerCase().contains('prima') || _vehicle.toLowerCase().contains('truck')
            ? 'HEAVY_TRUCK'
            : 'FOUR_WHEELER',
        preferSafety: true,
      );

      final rawRoutes = (response['routes'] as List<dynamic>?) ??
          (response['candidate_routes'] as List<dynamic>?) ??
          [];
      if (rawRoutes.isNotEmpty && mounted) {
        setState(() {
          // Determine minimum road distance across candidates to compute true physical detour
          double minDistance = double.infinity;
          for (final r in rawRoutes) {
            final d = (r['total_distance_km'] as num?)?.toDouble() ??
                (r['distance_km'] as num?)?.toDouble();
            if (d != null && d > 0 && d < minDistance) {
              minDistance = d;
            }
          }
          if (minDistance == double.infinity) minDistance = 0.0;

          _candidateRoutes = rawRoutes.map((r) {
            final isSafest = r['is_recommended_safest'] == true ||
                r['classification'] == 'SAFEST_VIABLE' ||
                r['classification'] == 'SAFEST_AND_FASTEST';
            final isFastest = r['is_fastest_available'] == true ||
                r['classification'] == 'FASTEST_AVAILABLE' ||
                r['classification'] == 'SAFEST_AND_FASTEST';
            final riskScore = (r['composite_risk_score'] as num?)?.toDouble() ?? 0.0;
            final riskLevel = riskScore > 0.6 ? 'HIGH' : (riskScore > 0.35 ? 'MODERATE' : 'LOW');
            final disruptionProb = ((r['bottleneck_disruption_prob'] as num?)?.toDouble() ?? riskScore) * 100;
            final distKm = (r['total_distance_km'] as num?)?.toDouble() ??
                (r['distance_km'] as num?)?.toDouble();
            final durMins = (r['estimated_duration_mins'] as num?)?.toDouble();

            final routeDist = distKm != null && distKm > 0 ? distKm : 0.0;
            final detourKm = (routeDist > minDistance && minDistance > 0)
                ? (routeDist - minDistance)
                : 0.0;

            final finalEta = durMins != null && durMins > 0
                ? 'ETA ${durMins ~/ 60}h ${(durMins % 60).round()}m'
                : null;

            final breakdown = DistanceUtils.computeDetailedBreakdown(
              lat1: oCoords[0],
              lon1: oCoords[1],
              lat2: dCoords[0],
              lon2: dCoords[1],
              vehicleTitle: _vehicle,
              cargoTitle: _cargo,
              isSafestRoute: isSafest,
              disruptionProbPct: disruptionProb.round(),
              overrideRoadKm: routeDist > 0 ? routeDist : null,
              overrideDetourKm: detourKm,
              overrideEtaText: finalEta,
            );

            final finalDist = routeDist > 0 ? routeDist : breakdown.totalRoadKm;
            final finalEtaText = finalEta ?? breakdown.estimatedEtaText;

            String classification = r['classification'] ?? 'ALTERNATIVE_BYPASS';
            if (isSafest && isFastest) {
              classification = 'SAFEST_AND_FASTEST';
            } else if (isSafest) {
              classification = 'SAFEST_VIABLE';
            } else if (isFastest) {
              classification = 'FASTEST_AVAILABLE';
            }

            return {
              'id': r['id']?.toString() ?? 'route-${r['name']}',
              'name': r['name'] ?? (isSafest ? 'Route A · Safest Viable' : 'Route B · Alternate Corridor'),
              'classification': classification,
              'distance_km': finalDist,
              'estimated_duration_seconds': durMins != null ? durMins * 60.0 : null,
              'estimated_duration_mins': durMins,
              'eta_text': finalEtaText,
              'disruption_prob_pct': disruptionProb.round(),
              'risk_level': riskLevel,
              'is_recommended': isSafest,
              'is_recommended_safest': isSafest,
              'is_fastest_available': isFastest,
              'origin_name': _origin,
              'destination_name': _destination,
              'origin_coords': oCoords,
              'destination_coords': dCoords,
              'breakdown': breakdown,
              'geometry_geojson': r['geometry_geojson'],
              'steps': r['steps'],
            };
          }).toList();
          _isLoadingRoutes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoutes = false);
    }
  }

  final List<String> _commonHubs = [
    'Guwahati Port Hub (Assam)',
    'Shillong Terminal Hub (Meghalaya)',
    'Silchar Logistics Depot (Assam)',
    'Dimapur Railhead Hub (Nagaland)',
    'Kohima Central Depot (Nagaland)',
    'Aizawl Wholesale Mart (Mizoram)',
    'Imphal Supply Depot (Manipur)',
    'Tezpur Northern Depot (Assam)',
    'Jorhat Multi-Modal Hub (Assam)',
    'Agartala Integrated Checkpost (Tripura)',
  ];

  void _swapLocations() {
    setState(() {
      final temp = _origin;
      _origin = _destination;
      _destination = temp;
      final tempCoords = _originCoords;
      _originCoords = _destinationCoords;
      _destinationCoords = tempCoords;
      _initializeFallbackRoutes();
    });
    _fetchLiveCandidateRoutes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swapped: $_origin ↔ $_destination'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showLocationPicker({required bool isOrigin}) {
    final searchController = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filteredHubs = _commonHubs
              .where((hub) => hub.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return Material(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOrigin ? localizationService.tr('select_origin') : localizationService.tr('select_dest'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (val) {
                      setModalState(() => query = val.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Type ANY town, village, hub or lat, lng...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() => query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Live GPS option
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.my_location_rounded, color: AppTheme.primaryBlue),
                    title: Text(
                      localizationService.tr('use_current_gps'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                    ),
                    subtitle: const Text('Acquire device hardware GPS coordinates'),
                    tileColor: AppTheme.blueLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Acquiring satellite GPS fix...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppTheme.primaryBlue,
                        ),
                      );

                      final loc = await LocationService().getCurrentLocation();
                      if (!mounted) return;

                      if (loc.errorMessage != null && loc.isMock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.errorMessage!),
                            backgroundColor: AppTheme.amber,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Settings',
                              textColor: Colors.white,
                              onPressed: () => LocationService().openLocationSettings(),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'GPS Locked: ${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E',
                            ),
                            backgroundColor: AppTheme.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }

                      setState(() {
                        final label = 'Current GPS (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})';
                        if (isOrigin) {
                          _origin = label;
                          _originCoords = [loc.latitude, loc.longitude];
                        } else {
                          _destination = label;
                          _destinationCoords = [loc.latitude, loc.longitude];
                        }
                        _initializeFallbackRoutes();
                      });

                      _fetchLiveCandidateRoutes();
                    },
                  ),
                  const SizedBox(height: 10),
                  if (query.isNotEmpty && !filteredHubs.any((h) => h.toLowerCase() == query.toLowerCase())) ...[
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_location_alt_outlined, color: AppTheme.primaryBlue),
                      title: Text(
                        'Set "$query"',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                      ),
                      subtitle: const Text('Custom North Eastern Region Location / GPS Coordinates'),
                      tileColor: AppTheme.blueLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        final regex = RegExp(r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)');
                        final match = regex.firstMatch(query);
                        List<double>? parsed;
                        if (match != null) {
                          final lat = double.tryParse(match.group(1)!);
                          final lng = double.tryParse(match.group(2)!);
                          if (lat != null && lng != null) parsed = [lat, lng];
                        }
                        setState(() {
                          if (isOrigin) {
                            _origin = query;
                            if (parsed != null) _originCoords = parsed;
                          } else {
                            _destination = query;
                            if (parsed != null) _destinationCoords = parsed;
                          }
                          _initializeFallbackRoutes();
                        });
                        Navigator.of(ctx).pop();
                        _fetchLiveCandidateRoutes();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'REGIONAL HUBS & DESTINATIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLow, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredHubs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, i) {
                        final hub = filteredHubs[i];
                        final cleanName = hub.split(' (').first;
                        final isCurrent = (isOrigin ? _origin : _destination).contains(cleanName);
                        final coords = _knownHubCoords[cleanName];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isOrigin ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                            color: isOrigin ? AppTheme.green : AppTheme.primaryBlue,
                            size: 20,
                          ),
                          title: Text(
                            hub,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent ? AppTheme.primaryBlue : AppTheme.textHigh,
                            ),
                          ),
                          subtitle: coords != null
                              ? Text(
                                  '${coords[0].toStringAsFixed(2)}° N, ${coords[1].toStringAsFixed(2)}° E',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                                )
                              : null,
                          trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 18) : null,
                          onTap: () {
                            setState(() {
                              if (isOrigin) {
                                _origin = cleanName;
                                if (coords != null) _originCoords = coords;
                              } else {
                                _destination = cleanName;
                                if (coords != null) _destinationCoords = coords;
                              }
                              _initializeFallbackRoutes();
                            });
                            Navigator.of(ctx).pop();
                            _fetchLiveCandidateRoutes();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _promptCustomVehicle(BuildContext parentCtx) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Add Custom Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Vehicle Name / Model',
            hintText: 'e.g. BharatBenz 2823R',
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newVeh = vehicleService.addCustomVehicle(
                  title: name,
                  category: 'Custom Carrier',
                  grossWeight: '28.0 Tonnes',
                  maxGradient: '16% Incline',
                );
                setState(() => _vehicle = newVeh.title);
                Navigator.of(dlgCtx).pop();
                Navigator.of(parentCtx).pop();
                _fetchLiveCandidateRoutes();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  void _promptCustomCargo(BuildContext parentCtx) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Add Custom Cargo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Cargo Title / Classification',
            hintText: 'e.g. Liquid Nitrogen Tanker',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newCargo = vehicleService.addCustomCargo(
                  title: name,
                  category: 'Custom Consignment',
                  riskPreference: 'Dynamic Safety Preference',
                );
                setState(() => _cargo = newCargo.title);
                Navigator.of(dlgCtx).pop();
                Navigator.of(parentCtx).pop();
                _fetchLiveCandidateRoutes();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  void _showVehiclePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Vehicle Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Text(
                  'Gross vehicle weight and dimensions determine bridge clearance and hairpin safety.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLow, height: 1.4),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => _promptCustomVehicle(ctx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryBlue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '+ Add Custom Vehicle Entry',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...vehicleService.vehicles.map((v) {
                  final isSelected = _vehicle == v.title;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? AppTheme.blueLight : AppTheme.container,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            v.icon,
                            size: 20,
                            color: isSelected ? Colors.white : AppTheme.primaryBlue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                v.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textHigh,
                                ),
                              ),
                            ),
                            if (v.isCustom)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.amber, width: 0.8),
                                ),
                                child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          v.category,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                            : null,
                        onTap: () {
                          final title = v.title;
                          setState(() {
                            _vehicle = title;
                            _initializeFallbackRoutes();
                          });
                          vehicleService.selectVehicleByTitle(title);
                          Navigator.of(ctx).pop();
                          _fetchLiveCandidateRoutes();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCargoPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Cargo Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Text(
                  'Cargo classification sets the risk threshold and priority during multi-route calculation.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLow, height: 1.4),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => _promptCustomCargo(ctx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryBlue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '+ Add Custom Cargo Entry',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...vehicleService.cargos.map((c) {
                  final isSelected = _cargo == c.title;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? AppTheme.blueLight : AppTheme.container,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            c.icon,
                            size: 20,
                            color: isSelected ? Colors.white : AppTheme.primaryBlue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textHigh,
                                ),
                              ),
                            ),
                            if (c.isCustom)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.amber, width: 0.8),
                                ),
                                child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          c.category,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                            : null,
                        onTap: () {
                          final title = c.title;
                          setState(() {
                            _cargo = title;
                            _initializeFallbackRoutes();
                          });
                          vehicleService.selectCargoByTitle(title);
                          Navigator.of(ctx).pop();
                          _fetchLiveCandidateRoutes();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final originShort = _origin.split(' ').first;
    final destShort = _destination.split(' ').first;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
        boxShadow: AppTheme.navShadow,
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizationService.tr('plan_journey'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textHigh,
                  ),
                ),
                InkWell(
                  onTap: _swapLocations,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$originShort ⇄ $destShort',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.swap_horiz_rounded, size: 16, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.borderLight, height: 24),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Origin & Destination Selector
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Origin
                      InkWell(
                        onTap: () => _showLocationPicker(isOrigin: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppTheme.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _origin,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textHigh,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                      // Dotted connector with interactive swap button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Container(
                                height: 24,
                                width: 2,
                                color: AppTheme.borderMed,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _swapLocations,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_vert_rounded, size: 16, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 4),
                                    Text(
                                      localizationService.tr('swap'),
                                      style: const TextStyle(
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
                      ),
                      // Destination
                      InkWell(
                        onTap: () => _showLocationPicker(isOrigin: false),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _destination,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textHigh,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Section Label
                Text(
                  localizationService.tr('available_candidate_routes'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLow,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),

                // Candidate Route Cards
                if (_isLoadingRoutes) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.borderLight,
                      color: AppTheme.primaryBlue,
                      minHeight: 2,
                    ),
                  ),
                ],
                ...List.generate(_candidateRoutes.length, (index) {
                  final route = _candidateRoutes[index];
                  final isSelected = _selectedRoute == index;
                  final isSafest = route['is_recommended_safest'] == true;
                  final isFastest = route['is_fastest_available'] == true;
                  final riskLevel = (route['risk_level'] ?? 'LOW').toString().toUpperCase();
                  final stripColor = riskLevel == 'HIGH'
                      ? AppTheme.red
                      : (riskLevel == 'MODERATE' ? AppTheme.amber : AppTheme.green);

                  // Dynamically determine badge text and styling from evaluated route properties
                  String badgeText;
                  Color badgeBg;
                  Color badgeColor;

                  if (isSafest && isFastest) {
                    badgeText = localizationService.tr('recommended_fastest');
                    badgeBg = AppTheme.greenBg;
                    badgeColor = AppTheme.green;
                  } else if (isSafest) {
                    badgeText = localizationService.tr('recommended');
                    badgeBg = AppTheme.greenBg;
                    badgeColor = AppTheme.green;
                  } else if (isFastest) {
                    badgeText = localizationService.tr('faster');
                    badgeBg = AppTheme.amberBg;
                    badgeColor = AppTheme.amber;
                  } else {
                    badgeText = localizationService.tr('alternative_bypass');
                    badgeBg = AppTheme.blueLight;
                    badgeColor = AppTheme.primaryBlue;
                  }
                  final etaText = route['eta_text'] ?? 'ETA --';
                  final distanceKm = route['distance_km'] ?? 0.0;
                  final disruptionProb = route['disruption_prob_pct'] ?? 15;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoute = index),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 72,
                              decoration: BoxDecoration(
                                color: stripColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          route['name'] ?? 'Corridor Route',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textHigh,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // ETA, Road Distance & Clauses Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$etaText  ',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textHigh,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '· $distanceKm km',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textMid,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showDistanceClausesSheet(context, route),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.blueLight,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.rule_rounded, size: 11, color: AppTheme.primaryBlue),
                                              const SizedBox(width: 3),
                                              Text(
                                                localizationService.tr('clauses_applied'),
                                                style: const TextStyle(
                                                  fontSize: 10,
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
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: riskLevel == 'HIGH' ? AppTheme.redBg : AppTheme.greenBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$disruptionProb% ${localizationService.tr('disruption')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: riskLevel == 'HIGH' ? AppTheme.red : AppTheme.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        riskLevel == 'LOW'
                                            ? localizationService.tr('risk_low')
                                            : (riskLevel == 'HIGH'
                                                ? localizationService.tr('risk_high')
                                                : localizationService.tr('risk_moderate')),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: stripColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (route['breakdown'] is DistanceBreakdown) ...[
                                    const SizedBox(height: 6),
                                    Builder(
                                      builder: (ctx) {
                                        final breakdown = route['breakdown'] as DistanceBreakdown;
                                        return Wrap(
                                          spacing: 5,
                                          runSpacing: 4,
                                          children: [
                                            _buildClauseMiniBadge('Aerial: ${breakdown.baseAerialKm} km', Colors.blueGrey),
                                            _buildClauseMiniBadge('IRC:SP:48 (+38%): +${breakdown.terrainCurvatureKm} km', const Color(0xFF0D9488)),
                                            if (breakdown.vehicleAxleKm > 0)
                                              _buildClauseMiniBadge('Axle: +${breakdown.vehicleAxleKm} km', const Color(0xFF7C3AED)),
                                            if (breakdown.hazardDetourKm > 0)
                                              _buildClauseMiniBadge('Detour: +${breakdown.hazardDetourKm} km', AppTheme.green)
                                            else
                                              _buildClauseMiniBadge('Direct Pass (0 km Detour)', const Color(0xFFD97706)),
                                            if (breakdown.cargoBufferKm > 0)
                                              _buildClauseMiniBadge('HAZMAT: +${breakdown.cargoBufferKm} km', AppTheme.red),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 14),

                // Risk Legend Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppTheme.green, localizationService.tr('low_risk')),
                    const SizedBox(width: 18),
                    _buildLegendItem(AppTheme.amber, localizationService.tr('moderate')),
                    const SizedBox(width: 18),
                    _buildLegendItem(AppTheme.red, localizationService.tr('high_risk')),
                  ],
                ),

                const SizedBox(height: 14),

                // Vehicle & Cargo Interactive Selectors
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _showVehiclePicker,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.container,
                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _vehicle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.textLow),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _showCargoPicker,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.container,
                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _cargo,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.textLow),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final Map<String, dynamic> selectedRouteData = _candidateRoutes.isNotEmpty && _selectedRoute < _candidateRoutes.length
                          ? Map<String, dynamic>.from(_candidateRoutes[_selectedRoute])
                          : <String, dynamic>{
                              'name': 'Route A · NH-06 via Nongpoh',
                            };
                      selectedRouteData['origin_name'] = _origin;
                      selectedRouteData['destination_name'] = _destination;
                      selectedRouteData['origin_coords'] = _originCoords ?? [26.1445, 91.7362];
                      selectedRouteData['destination_coords'] = _destinationCoords ?? [25.5788, 91.8933];

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Safe Route Confirmed: $_origin → $_destination (${selectedRouteData['name']})',
                          ),
                          backgroundColor: AppTheme.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      widget.onRouteSelected?.call(selectedRouteData);
                      widget.onConfirmRoute?.call();
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                    ),
                    child: Text(
                      localizationService.tr('confirm_route'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
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
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildClauseMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  void _showDistanceClausesSheet(BuildContext context, Map<String, dynamic> route) {
    final oCoords = _resolveCoordinates(_origin, isOrigin: true);
    final dCoords = _resolveCoordinates(_destination, isOrigin: false);
    final isSafest = route['classification'] == 'SAFEST_VIABLE';
    final disruption = (route['disruption_prob_pct'] as num?)?.toInt() ?? 15;

    final DistanceBreakdown breakdown = route['breakdown'] is DistanceBreakdown
        ? route['breakdown'] as DistanceBreakdown
        : DistanceUtils.computeDetailedBreakdown(
            lat1: oCoords[0],
            lon1: oCoords[1],
            lat2: dCoords[0],
            lon2: dCoords[1],
            vehicleTitle: _vehicle,
            cargoTitle: _cargo,
            isSafestRoute: isSafest,
            disruptionProbPct: disruption,
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
                          '$_origin → $_destination (${route['name']})',
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
}
