import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/hazard_report_sheet.dart';
import '../widgets/map_layer_sheet.dart';
import '../widgets/slippy_tile_layer.dart';

class FieldWorkerMapScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const FieldWorkerMapScreen({super.key, this.onOpenDrawer});

  @override
  State<FieldWorkerMapScreen> createState() => _FieldWorkerMapScreenState();
}

class _FieldWorkerMapScreenState extends State<FieldWorkerMapScreen> {
  AppMapType _mapType = AppMapType.road;
  bool _showAlertsLayer = true;
  bool _showIncidentsLayer = true;

  // Interactive Viewport Camera state
  double _cameraLat = 25.86;
  double _cameraLng = 91.85;
  double _cameraZoom = 9.8;
  double _basePinchZoom = 9.8;

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
      _cameraLat = 25.86;
      _cameraLng = 91.85;
      _cameraZoom = 9.8;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.crop_free_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Corridor overview: Entire patrol sector fitted to view')),
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
      setState(() {
        _cameraLat = loc.latitude;
        _cameraLng = loc.longitude;
        _cameraZoom = 15.0;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GPS Locked: Patrol at ${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E',
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
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorMessage ?? 'Unable to acquire satellite GPS fix'),
            backgroundColor: AppTheme.amber,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => LocationService().openLocationSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
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
                const Icon(Icons.pin_drop_rounded, size: 14, color: AppTheme.amber),
                const SizedBox(width: 6),
                Text(
                  '${_cameraLat.toStringAsFixed(4)}° N, ${_cameraLng.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: const [
          Icon(Icons.filter_list_rounded, color: AppTheme.textLow, size: 22),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: Stack(
        children: [
          // Authentic Slippy Map Tiles (Default, Satellite, Terrain) + Gestures
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _zoomIn,
              onScaleStart: (details) {
                _basePinchZoom = _cameraZoom;
              },
              onScaleUpdate: (details) {
                setState(() {
                  if (details.scale != 1.0) {
                    _cameraZoom = (_basePinchZoom + (math.log(details.scale) / math.ln2)).clamp(5.0, 18.0);
                  }
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
                    mapType: _mapType,
                  ),
                  CustomPaint(
                    painter: _FieldWorkerHeatmapPainter(
                      mapType: _mapType,
                      showAlerts: _showAlertsLayer,
                      showIncidents: _showIncidentsLayer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-right controls (Layers, Compass, GPS, Zoom In, Zoom Out, Fit)
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

          // Floating Red Action Button (FAB)
          Positioned(
            right: 20,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: 'fw_map_fab',
              onPressed: () => HazardReportSheet.show(context),
              backgroundColor: AppTheme.red,
              elevation: 4,
              child: const Icon(Icons.add_alert_rounded, color: Colors.white, size: 26),
            ),
          ),

          // Bottom Peek Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
                boxShadow: AppTheme.navShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Sector: NH-06 Nongpoh–Sonapur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHigh,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.greenBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Active Patrol',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Last sync: 3m ago · 2 verified hazards in 10km radius',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppTheme.textLow,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => HazardReportSheet.show(context),
                            icon: const Icon(Icons.add_alert_rounded, size: 18),
                            label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _showPatrolIncidentsSheet(context),
                            icon: const Icon(Icons.list_alt_rounded, size: 18, color: AppTheme.primaryBlue),
                            label: const Text(
                              'View Incidents',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatrolIncidentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Patrol Sector Incidents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textHigh,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'NH-06 Nongpoh–Sonapur · 3 verified reports',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLow),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMid),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSectorIncidentCard(
                    ctx,
                    title: 'Landslide Debris at KM 42.8',
                    corridor: 'NH-06 KM 42.8 · 1.4 km from patrol',
                    severity: 'High Blockage',
                    severityColor: AppTheme.red,
                    severityBg: AppTheme.redBg,
                    timestamp: 'Reported 12m ago',
                    notes: 'Both carriageways blocked by mud and boulder collapse. BRO clearing crew active on site.',
                    hazardType: 'Landslide',
                  ),
                  const SizedBox(height: 12),
                  _buildSectorIncidentCard(
                    ctx,
                    title: 'Flash Flood Standing Water',
                    corridor: 'NH-06 KM 51.2 · 7.8 km from patrol',
                    severity: 'Partial Passable',
                    severityColor: AppTheme.amber,
                    severityBg: AppTheme.amberBg,
                    timestamp: 'Reported 35m ago',
                    notes: '1.2 ft overflow at culvert. Heavy trucks passable with pilot convoy escort.',
                    hazardType: 'Flash Flood',
                  ),
                  const SizedBox(height: 12),
                  _buildSectorIncidentCard(
                    ctx,
                    title: 'Fallen Pine Tree Cleared',
                    corridor: 'NH-06 KM 38.6 · 4.2 km from patrol',
                    severity: 'Passable (Shoulder)',
                    severityColor: AppTheme.green,
                    severityBg: AppTheme.greenBg,
                    timestamp: 'Reported 1h ago',
                    notes: 'Tree trunk cut and pushed to side berm. Two-way traffic moving normally.',
                    hazardType: 'Fallen Tree',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  HazardReportSheet.show(context);
                },
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: const Text('Report New Sector Hazard', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorIncidentCard(
    BuildContext ctx, {
    required String title,
    required String corridor,
    required String severity,
    required Color severityColor,
    required Color severityBg,
    required String timestamp,
    required String notes,
    required String hazardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: severityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(corridor, style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(timestamp, style: const TextStyle(fontSize: 10, color: AppTheme.textLow)),
            ],
          ),
          const SizedBox(height: 6),
          Text(notes, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.3)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                HazardReportSheet.show(context, initialHazardType: hazardType);
              },
              icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primaryBlue),
              label: const Text('Update Recon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _FieldWorkerHeatmapPainter extends CustomPainter {
  final AppMapType mapType;
  final bool showAlerts;
  final bool showIncidents;

  _FieldWorkerHeatmapPainter({
    this.mapType = AppMapType.road,
    this.showAlerts = true,
    this.showIncidents = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Mountain Elevation Peaks (Highlighted in Terrain mode)
    if (mapType == AppMapType.terrain) {
      _drawPeakMarker(canvas, Offset(size.width * 0.25, size.height * 0.18), '▲ Mt. Shillong 1,961m');
      _drawPeakMarker(canvas, Offset(size.width * 0.75, size.height * 0.65), '▲ Barail Peak 1,850m');
    }

    // Actual Roads (National Highways across Sector)
    final Color roadColor;
    final Color casingColor;
    if (mapType == AppMapType.satellite) {
      roadColor = const Color(0xFF38BDF8).withValues(alpha: 0.85);
      casingColor = const Color(0xFF0F172A);
    } else if (mapType == AppMapType.terrain) {
      roadColor = const Color(0xFF475569);
      casingColor = const Color(0xFFE2E8F0);
    } else {
      roadColor = const Color(0xFF0284C7);
      casingColor = const Color(0xFFCBD5E1);
    }

    final roadCasing = Paint()
      ..color = casingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final roadCore = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Primary Sector Corridor (NH-06)
    final nh06 = Path();
    nh06.moveTo(size.width * 0.15, 0);
    nh06.cubicTo(size.width * 0.3, size.height * 0.35, size.width * 0.7, size.height * 0.45, size.width * 0.82, size.height);
    canvas.drawPath(nh06, roadCasing);
    canvas.drawPath(nh06, roadCore);

    // Feeder Link Road
    final feeder = Path();
    feeder.moveTo(size.width * 0.82, size.height * 0.3);
    feeder.quadraticBezierTo(size.width * 0.55, size.height * 0.38, size.width * 0.38, size.height * 0.75);
    canvas.drawPath(feeder, roadCasing..strokeWidth = 4.5);
    canvas.drawPath(feeder, roadCore..strokeWidth = 2.2);

    // 6. Hazard & Alert Blobs (Only if showAlerts)
    if (showAlerts) {
      final amberBlob = Paint()..color = AppTheme.amber.withValues(alpha: 0.30);
      canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.35), 45, amberBlob);

      final redBlob = Paint()..color = AppTheme.red.withValues(alpha: 0.28);
      canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.48), 55, redBlob);

      _drawAlertPill(canvas, Offset(size.width * 0.35, size.height * 0.35 - 30), 'ALT: Landslide Watch', const Color(0xFFD97706));
      _drawAlertPill(canvas, Offset(size.width * 0.65, size.height * 0.48 - 36), 'ALT: Boulder Influx', const Color(0xFFDC2626));
    }

    // 7. Incident Pins (Only if showIncidents)
    if (showIncidents) {
      // Incident 1: Verified (Green)
      _drawIncidentPin(canvas, Offset(size.width * 0.35, size.height * 0.35), AppTheme.green, 'INC-881 Verified');

      // Incident 2: Dispatched (Amber)
      _drawIncidentPin(canvas, Offset(size.width * 0.65, size.height * 0.48), AppTheme.amber, 'INC-882 Dispatched');

      // Incident 3: Pending (Blue)
      _drawIncidentPin(canvas, Offset(size.width * 0.48, size.height * 0.2), AppTheme.primaryBlue, 'INC-883 Recon Required');
    }
  }

  void _drawPeakMarker(Canvas canvas, Offset pos, String label) {
    final peakPaint = Paint()
      ..color = const Color(0xFF4D7C0F)
      ..style = PaintingStyle.fill;
    final peakPath = Path()
      ..moveTo(pos.dx, pos.dy - 8)
      ..lineTo(pos.dx - 6, pos.dy + 3)
      ..lineTo(pos.dx + 6, pos.dy + 3)
      ..close();
    canvas.drawPath(peakPath, peakPaint);

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(color: Color(0xFF365314), fontSize: 8, fontWeight: FontWeight.w700),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 5));
  }

  void _drawAlertPill(Canvas canvas, Offset pos, String label, Color color) {
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx - tp.width / 2 - 4, pos.dy - 2, tp.width + 8, 14),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  void _drawIncidentPin(Canvas canvas, Offset pos, Color color, String label) {
    canvas.drawCircle(pos, 8, Paint()..color = color);
    canvas.drawCircle(pos, 3, Paint()..color = Colors.white);

    final textSpan = TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx - tp.width / 2 - 4, pos.dy + 10, tp.width + 8, 14),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(rrect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 11));
  }

  @override
  bool shouldRepaint(covariant _FieldWorkerHeatmapPainter old) {
    return old.mapType != mapType ||
        old.showAlerts != showAlerts ||
        old.showIncidents != showIncidents;
  }
}
