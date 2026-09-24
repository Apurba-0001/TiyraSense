import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/alert_service.dart';
import '../services/api_service.dart';
import '../services/report_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/status_pill_badge.dart';
import '../widgets/app_logo.dart';
import '../widgets/side_drawer.dart';
import '../widgets/journey_planning_sheet.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

/// Official Operations Command Home Screen.
/// Provides tactical oversight, alert broadcasting, incident report verification,
/// and live fleet vehicle tracking for Disaster Management and Logistics Officials.
class OfficialHomeScreen extends StatefulWidget {
  final UserModel user;
  final AuthProvider authProvider;

  const OfficialHomeScreen({
    super.key,
    required this.user,
    required this.authProvider,
  });

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Fleet vehicles data model
  int _selectedVehicleIndex = 0;
  final List<Map<String, dynamic>> _fleetVehicles = [
    {
      'id': 'TRK-01',
      'name': 'Tata Prima 3530.K (18-Wheeler)',
      'driver': 'Ramen Borah',
      'phone': '+91 98540 11204',
      'corridor': 'NH-06 (Guwahati - Shillong)',
      'location': 'Km 64 · Nongpoh Pass',
      'lat': 25.9012,
      'lng': 91.8791,
      'speed': 42.0,
      'heading': 168.0,
      'cargo': 'Essential Medicine & Vaccines',
      'axleLoad': '28.4 MT / 35.0 MT',
      'status': 'Normal',
      'eta': '2h 15m',
      'forwardHazard': 'Minor rockfall cleared at Km 72',
      'riskScore': 0.18,
    },
    {
      'id': 'TRK-02',
      'name': 'BharatBenz 2823C (Multi-Axle)',
      'driver': 'Biren Gogoi',
      'phone': '+91 94350 44211',
      'corridor': 'NH-27 (Guwahati Bypass)',
      'location': 'Km 12 · Khanapara Interchange',
      'lat': 26.1154,
      'lng': 91.7082,
      'speed': 58.0,
      'heading': 94.0,
      'cargo': 'FCI Food Grain & Staples',
      'axleLoad': '24.1 MT / 28.0 MT',
      'status': 'In Transit',
      'eta': '4h 40m',
      'forwardHazard': 'None',
      'riskScore': 0.12,
    },
    {
      'id': 'MED-04',
      'name': 'Force Trax Mobile Clinic',
      'driver': 'Dr. N. Deka',
      'phone': '+91 91012 33455',
      'corridor': 'NH-06 (Barapani Link)',
      'location': 'Km 88 · Umiam Lake Sector',
      'lat': 25.6601,
      'lng': 91.9056,
      'speed': 35.0,
      'heading': 182.0,
      'cargo': 'Emergency Relief & Trauma Kits',
      'axleLoad': '3.2 MT / 4.5 MT',
      'status': 'Priority In Transit',
      'eta': '45m',
      'forwardHazard': 'Monsoon waterlogging alert at Km 92',
      'riskScore': 0.32,
    },
    {
      'id': 'RECON-05',
      'name': 'Mahindra Bolero Neo 4x4',
      'driver': 'Dipankar Saikia',
      'phone': '+91 86381 22904',
      'corridor': 'NH-06 (Sonapur Sector)',
      'location': 'Km 48 · Byrnihat Outpost',
      'lat': 26.0124,
      'lng': 91.8901,
      'speed': 48.0,
      'heading': 175.0,
      'cargo': 'Ground Sensor Kit & Satellite Uplink',
      'axleLoad': '2.1 MT / 2.8 MT',
      'status': 'Active Reconnaissance',
      'eta': 'Patrolling',
      'forwardHazard': 'Active mudslide reconnaissance at Km 52',
      'riskScore': 0.44,
    },
  ];

  // Report filter for tab 2
  String _reportFilter = 'ALL';

  final ApiService _apiService = ApiService();
  Timer? _pollTimer;
  List<Map<String, dynamic>> _liveCorridors = [];

  @override
  void initState() {
    super.initState();
    _loadLiveTelemetry();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadLiveTelemetry());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveTelemetry() async {
    reportService.syncLiveReports();
    try {
      final corridors = await _apiService.fetchCorridors();
      if (mounted && corridors.isNotEmpty) {
        setState(() {
          _liveCorridors = corridors;
        });
      }
    } catch (_) {}

    try {
      final journeys = await _apiService.fetchActiveJourneys();
      if (mounted && journeys.isNotEmpty) {
        setState(() {
          _fleetVehicles.clear();
          for (final j in journeys) {
            final curLoc = j['current_location'] as Map<String, dynamic>?;
            _fleetVehicles.add({
              'id': j['journey_id'] ?? 'TRK-01',
              'name': j['vehicle_name'] ?? 'Logistics Carrier',
              'driver': j['driver_name'] ?? 'Assigned Driver',
              'phone': j['driver_phone'] ?? '+91 94350 11204',
              'corridor': j['route_name'] ?? 'Monitored Corridor',
              'location': j['destination_name'] ?? 'In Transit',
              'lat': (curLoc?['latitude'] as num?)?.toDouble() ?? 26.1445,
              'lng': (curLoc?['longitude'] as num?)?.toDouble() ?? 91.7362,
              'speed': (j['speed_kmh'] as num?)?.toDouble() ?? 42.0,
              'heading': 168.0,
              'cargo': j['route_name'] ?? 'Essential Freight',
              'axleLoad': '28.4 MT / 35.0 MT',
              'status': j['status'] ?? 'In Transit',
              'eta': '2h 15m',
              'forwardHazard': j['status'] == 'HAZARD_SLOWED' ? 'Caution alert active in sector' : 'None',
              'riskScore': 0.18,
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.canvas,
      drawer: SideDrawer(
        role: UserRole.official,
        activeItem: _getDrawerActiveItem(),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildOperationalCommandDashboard(context),
          _buildFleetTrackingConsole(context),
          _buildVerificationQueueScreen(context),
          AlertsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          ProfileScreen(
            role: UserRole.official,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getDrawerActiveItem() {
    switch (_currentTabIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Fleet Live Tracking';
      case 2:
        return 'Verification Queue';
      case 3:
        return 'Alerts';
      default:
        return 'Profile';
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 0: OPERATIONAL COMMAND DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildOperationalCommandDashboard(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: AppLogo.icon(size: 36, radius: 9),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textHigh,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OFFICIAL COMMAND',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'NER Transit Command Hub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textLow,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trigger Emergency Alert',
            icon: const Icon(Icons.campaign_rounded, color: AppTheme.red),
            onPressed: () => _showBroadcastAlertDialog(context),
          ),
          IconButton(
            tooltip: 'Plan Safe Route',
            icon: const Icon(Icons.alt_route_rounded, color: AppTheme.primaryBlue),
            onPressed: () => JourneyPlanningSheet.show(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 840,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Command KPI Banner
              _buildCommandKpiBanner(),
              const SizedBox(height: 16),

              // 2. Quick Actions Grid (2x2)
              const Text(
                'OFFICIAL ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLow,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _buildOfficialQuickActionGrid(context),
              const SizedBox(height: 20),

              // 3. Urgent Verification Queue Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INCIDENT VERIFICATION QUEUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
                ListenableBuilder(
                  listenable: reportService,
                  builder: (context, _) => Text(
                    '${reportService.pendingCount} Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPendingVerificationQueueWidget(context),
            const SizedBox(height: 20),

            // 4. Critical Corridor Risk Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CRITICAL CORRIDORS OVERVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentTabIndex = 1),
                  child: const Text(
                    'View Fleet Live →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCriticalCorridorsList(),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCommandKpiBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: Color(0xFF60A5FA)),
                    SizedBox(width: 4),
                    Text(
                      'LOGISTICS INTELLIGENCE COMMAND',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF93C5FD),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.circle, size: 8, color: Color(0xFF4ADE80)),
              const SizedBox(width: 4),
              const Text(
                'LIVE FEED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4ADE80),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'North Eastern Region Corridor Operations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitoring 14 critical NH corridors, 4 active logistics units, and 12 IMD AWS weather telemetry stations across Assam, Meghalaya, and Nagaland.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildKpiMiniItem(_liveCorridors.isNotEmpty ? '${_liveCorridors.length}' : '8', 'Monitored Corridors', const Color(0xFF60A5FA)),
              _buildKpiDivider(),
              _buildKpiMiniItem('${_fleetVehicles.length}', 'Fleet Units Active', const Color(0xFF34D399)),
              _buildKpiDivider(),
              ListenableBuilder(
                listenable: reportService,
                builder: (context, _) => _buildKpiMiniItem(
                  '${reportService.pendingCount}',
                  'Pending Review',
                  const Color(0xFFFBBF24),
                ),
              ),
              _buildKpiDivider(),
              _buildKpiMiniItem('99.9%', 'System Telemetry', const Color(0xFFA78BFA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMiniItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.15),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildOfficialQuickActionGrid(BuildContext context) {
    final cols = Responsive.gridColumns(context, defaultCols: 2, tabletCols: 4);
    final isCompact = Responsive.isCompact(context);
    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: cols == 4 ? 1.6 : (isCompact ? 1.35 : 1.5),
      children: [
        _buildActionCard(
          icon: Icons.campaign_rounded,
          color: AppTheme.red,
          title: 'Trigger Corridor Alert',
          subtitle: 'Broadcast road disruption advisory',
          onTap: () => _showBroadcastAlertDialog(context),
        ),
        _buildActionCard(
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF0D9488),
          title: 'Review & Verify Reports',
          subtitle: 'Evaluate field hazards & dispatch',
          onTap: () => setState(() => _currentTabIndex = 2),
        ),
        _buildActionCard(
          icon: Icons.local_shipping_rounded,
          color: AppTheme.primaryBlue,
          title: 'Fleet Live Tracking',
          subtitle: 'Inspect trucks, cargo & telematics',
          onTap: () => setState(() => _currentTabIndex = 1),
        ),
        _buildActionCard(
          icon: Icons.alt_route_rounded,
          color: const Color(0xFF7C3AED),
          title: 'Plan Safe Route',
          subtitle: 'Evaluate multi-criteria risk routes',
          onTap: () => JourneyPlanningSheet.show(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textLow.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textHigh,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textLow,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVerificationQueueWidget(BuildContext context) {
    return ListenableBuilder(
      listenable: reportService,
      builder: (context, _) {
        final pendingReports = reportService.reports.where((r) => r.status == 'PENDING').toList();
        if (pendingReports.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.green, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Hazard Reports Cleared',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                      ),
                      Text(
                        'No pending field reports awaiting official verification.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textLow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final topReport = pendingReports.first;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.5)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PENDING VERIFICATION · ${topReport.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.amber,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    topReport.relativeTime,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${topReport.corridor} (${topReport.km}) — ${topReport.hazardType}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textHigh,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                topReport.notes,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLow, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_rounded, size: 13, color: AppTheme.textLow),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by ${topReport.workerName} (${topReport.workerUnit})',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Verify & Broadcast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () {
                        reportService.verifyReport(topReport.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Incident ${topReport.id} verified and broadcasted to NER corridor feed.'),
                            backgroundColor: AppTheme.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 16),
                      label: const Text('Dispatch Team', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () => _showDispatchDialog(context, topReport.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriticalCorridorsList() {
    final corridors = _liveCorridors.isNotEmpty
        ? _liveCorridors.take(5).map((c) {
            final status = (c['status'] ?? 'PASSABLE').toString().toUpperCase();
            final riskScore = (c['risk_score'] as num?)?.toDouble() ?? 20.0;
            Color statusColor = AppTheme.green;
            if (status.contains('BLOCK') || status.contains('HIGH') || riskScore > 60) {
              statusColor = AppTheme.red;
            } else if (status.contains('CAUTION') || riskScore > 30) {
              statusColor = AppTheme.amber;
            }
            return {
              'code': c['route_id'] ?? c['id'] ?? 'NH-06',
              'name': c['name'] ?? 'Monitored Corridor',
              'status': status,
              'statusColor': statusColor,
              'riskScore': (riskScore / 100.0).toStringAsFixed(2),
              'weather': c['last_report'] ?? 'Live Telemetry Radar',
              'trucks': '${_fleetVehicles.length} Units',
              'throughput': '${(100 - riskScore).clamp(10, 100).toInt()}%',
            };
          }).toList()
        : [
            {
              'code': 'NH-06',
              'name': 'Guwahati — Shillong — Silchar',
              'status': 'MODERATE RISK',
              'statusColor': AppTheme.amber,
              'riskScore': '0.28',
              'weather': 'Light Mist · Rain 12mm/h',
              'trucks': '14 Units',
              'throughput': '84%',
            },
            {
              'code': 'NH-29',
              'name': 'Dimapur — Kohima Express Corridor',
              'status': 'HIGH WATCH',
              'statusColor': AppTheme.red,
              'riskScore': '0.64',
              'weather': 'Heavy Rain 48mm/h · Fog',
              'trucks': '6 Units',
              'throughput': '52%',
            },
            {
              'code': 'NH-10',
              'name': 'Sevoke — Gangtok Teesta Valley',
              'status': 'NORMAL FLOW',
              'statusColor': AppTheme.green,
              'riskScore': '0.14',
              'weather': 'Partly Cloudy · 24°C',
              'trucks': '18 Units',
              'throughput': '96%',
            },
          ];

    return Column(
      children: corridors.map((corridor) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (corridor['statusColor'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    corridor['code'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: corridor['statusColor'] as Color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      corridor['name'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${corridor['weather']} • ${corridor['trucks']} Active',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textLow),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (corridor['statusColor'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      corridor['status'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: corridor['statusColor'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Risk: ${corridor['riskScore']}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textHigh),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FLEET LIVE TRACKING CONSOLE
  // ---------------------------------------------------------------------------
  Widget _buildFleetTrackingConsole(BuildContext context) {
    final vehicle = _fleetVehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textHigh),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Live Tracking',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
            ),
            Text(
              'Real-Time Vehicle Coordinates & Telematics',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textLow),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh GPS Telemetry',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fleet GPS telemetry synchronized (4 beacons updated).'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 840,
        child: Column(
          children: [
            // 1. Vehicle Selector Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: AppTheme.surface,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fleetVehicles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final v = _fleetVehicles[idx];
                  final isSelected = idx == _selectedVehicleIndex;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 14,
                          color: isSelected ? Colors.white : AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(v['id'] as String),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textHigh,
                    ),
                    onSelected: (_) => setState(() => _selectedVehicleIndex = idx),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),

          // 2. Main Vehicle Detail & Telemetry View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vehicle['id'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vehicle['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textHigh,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicle['status'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        const SizedBox(height: 12),
                        // Driver Info & Call Button
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.blueLight,
                              child: Icon(Icons.person_rounded, size: 20, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle['driver'] as String,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                                  ),
                                  Text(
                                    vehicle['phone'] as String,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.phone_rounded, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Dialing ${vehicle['driver']} (${vehicle['phone']})...')),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.message_rounded, size: 18),
                              onPressed: () {
                                _showSendTacticalMessageDialog(context, vehicle['driver'] as String);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Telematics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryMetricCard(
                          icon: Icons.speed_rounded,
                          title: 'Speed',
                          value: '${(vehicle['speed'] as double).toStringAsFixed(0)} km/h',
                          subtitle: 'Heading ${vehicle['heading']}° S',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTelemetryMetricCard(
                          icon: Icons.scale_rounded,
                          title: 'Axle Payload',
                          value: vehicle['axleLoad'] as String,
                          subtitle: vehicle['cargo'] as String,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryMetricCard(
                          icon: Icons.location_on_rounded,
                          title: 'Current Location',
                          value: vehicle['location'] as String,
                          subtitle: '${vehicle['lat']}, ${vehicle['lng']}',
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTelemetryMetricCard(
                          icon: Icons.security_rounded,
                          title: 'Route Risk',
                          value: 'Score ${(vehicle['riskScore'] as double).toStringAsFixed(2)}',
                          subtitle: 'ETA: ${vehicle['eta']}',
                          color: (vehicle['riskScore'] as double) > 0.3 ? AppTheme.amber : AppTheme.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Forward Hazard Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.amber),
                            SizedBox(width: 6),
                            Text(
                              'FORWARD CORRIDOR HAZARDS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textLow,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vehicle['forwardHazard'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textHigh),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                              side: const BorderSide(color: AppTheme.primaryBlue),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.share_location_rounded, size: 16),
                            label: const Text('Reroute Vehicle to Safer Path', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () {
                              JourneyPlanningSheet.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTelemetryMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textLow),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: GROUND INCIDENT VERIFICATION QUEUE
  // ---------------------------------------------------------------------------
  Widget _buildVerificationQueueScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textHigh),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Verification Queue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
            ),
            Text(
              'Official Recon Validation & Dispatch',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textLow),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 840,
        child: Column(
          children: [
            // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'PENDING', 'VERIFIED', 'DISPATCHED', 'REJECTED'].map((filter) {
                  final isSelected = _reportFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textHigh,
                      ),
                      onSelected: (_) => setState(() => _reportFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),

          // Reports List
          Expanded(
            child: ListenableBuilder(
              listenable: reportService,
              builder: (context, _) {
                final filtered = reportService.reports.where((r) {
                  if (_reportFilter == 'ALL') return true;
                  return r.status.toUpperCase() == _reportFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textLow),
                        const SizedBox(height: 8),
                        Text(
                          'No ${_reportFilter.toLowerCase()} incident reports found',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final report = filtered[idx];
                    return _buildVerificationReportCard(context, report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildVerificationReportCard(BuildContext context, ReportItem report) {
    final statusColor = report.status == 'VERIFIED'
        ? AppTheme.green
        : (report.status == 'DISPATCHED'
            ? const Color(0xFF0D9488)
            : (report.status == 'REJECTED' ? AppTheme.red : AppTheme.amber));

    return Container(
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.id,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLow),
              ),
              const Spacer(),
              Text(
                report.relativeTime,
                style: const TextStyle(fontSize: 10, color: AppTheme.textLow),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${report.corridor} (${report.km}) — ${report.hazardType}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
          ),
          const SizedBox(height: 4),
          Text(
            report.notes,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLow, height: 1.4),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.textLow),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textLow),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (report.dispatchUnit != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.airport_shuttle_rounded, size: 14, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Text(
                    'Dispatched: ${report.dispatchUnit}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              if (report.status != 'VERIFIED')
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      reportService.verifyReport(report.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report ${report.id} marked as VERIFIED.')),
                      );
                    },
                    child: const Text('Verify', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              if (report.status != 'VERIFIED') const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _showDispatchDialog(context, report.id),
                  child: const Text('Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.amber,
                  side: const BorderSide(color: AppTheme.amber),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  reportService.rejectReport(report.id, reason: 'Rejected by operations official command.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report ${report.id} rejected.')),
                  );
                },
                child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  backgroundColor: AppTheme.red.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                tooltip: 'Delete / Purge Report',
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () => _confirmDeleteReport(context, report.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textLow,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Command Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'Fleet Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Reports Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS: BROADCAST ALERT & DISPATCH
  // ---------------------------------------------------------------------------
  void _showBroadcastAlertDialog(BuildContext context) {
    String selectedCorridor = 'NH-06';
    String selectedSeverity = 'EMERGENCY';
    final titleController = TextEditingController(text: 'Urgent Monsoon Disruption Warning');
    final descController = TextEditingController(
      text: 'Heavy rainfall causing high debris flow risk between Km 48 - 62. All heavy multi-axle freight advised to halt or reroute.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign_rounded, color: AppTheme.red, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Broadcast Corridor Alert',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Target Corridor',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['NH-06', 'NH-29', 'NH-10', 'NH-37', 'ALL CORRIDORS'].map((corridor) {
                    final isSelected = selectedCorridor == corridor;
                    return ChoiceChip(
                      label: Text(corridor),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textHigh,
                      ),
                      onSelected: (_) => setSheetState(() => selectedCorridor = corridor),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Severity Classification',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['EMERGENCY', 'HIGH RISK', 'CAUTION'].map((sev) {
                    final isSelected = selectedSeverity == sev;
                    final chipColor = sev == 'EMERGENCY' ? AppTheme.red : (sev == 'HIGH RISK' ? AppTheme.amber : AppTheme.primaryBlue);
                    return ChoiceChip(
                      label: Text(sev),
                      selected: isSelected,
                      selectedColor: chipColor,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textHigh,
                      ),
                      onSelected: (_) => setSheetState(() => selectedSeverity = sev),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Headline / Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tactical Advisory Details',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedSeverity == 'EMERGENCY' ? AppTheme.red : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Broadcast to All Drivers & Field Units',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();
                      if (title.isEmpty) return;

                      alertService.addAlert(
                        severity: selectedSeverity,
                        corridor: selectedCorridor,
                        category: 'EMERGENCY',
                        location: '$selectedCorridor Active Sector',
                        title: title,
                        desc: desc,
                        status: BadgeStatusType.blocked,
                        isEmergency: selectedSeverity == 'EMERGENCY',
                        source: 'Official Operations Command (${widget.user.fullName})',
                        pushNotification: true,
                      );

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tactical Alert broadcasted to all units on $selectedCorridor!'),
                          backgroundColor: AppTheme.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, String reportId) {
    String selectedUnit = 'NDRF Rescue Unit 9';
    final notesController = TextEditingController(text: 'Heavy excavator and road clearance crew dispatched.');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.airport_shuttle_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('Dispatch Response Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dispatching unit to Incident $reportId', style: const TextStyle(fontSize: 12, color: AppTheme.textLow)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                decoration: const InputDecoration(labelText: 'Response Unit'),
                items: [
                  'NDRF Rescue Unit 9',
                  'SDRF Quick Clearance Team 3',
                  'PWD Heavy Earth-Mover Crew',
                  'Highway Patrol Sector 4',
                ].map((unit) => DropdownMenuItem(value: unit, child: Text(unit, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setDialogState(() => selectedUnit = val ?? selectedUnit),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Dispatch Instructions'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                reportService.dispatchUnitToReport(reportId, selectedUnit, notes: notesController.text.trim());
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$selectedUnit dispatched to Incident $reportId!'),
                    backgroundColor: AppTheme.green,
                  ),
                );
              },
              child: const Text('Confirm Dispatch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendTacticalMessageDialog(BuildContext context, String driverName) {
    final msgController = TextEditingController(text: 'Please slow down at Km 52 due to active mudslide reconnaissance.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tactical Message to $driverName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: msgController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Message Body'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Message transmitted to $driverName.')),
              );
            },
            child: const Text('Transmit'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReport(BuildContext context, String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppTheme.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Incident Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete report $reportId? This will remove the record from operations and live feeds.',
          style: const TextStyle(fontSize: 12, color: AppTheme.textLow, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              reportService.deleteReport(reportId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report $reportId permanently deleted.'),
                  backgroundColor: AppTheme.red,
                ),
              );
            },
            child: const Text('Delete Report'),
          ),
        ],
      ),
    );
  }
}
