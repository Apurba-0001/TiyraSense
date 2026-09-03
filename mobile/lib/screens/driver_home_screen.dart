import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final UserModel user;
  final AuthProvider authProvider;

  const DriverHomeScreen({
    super.key,
    required this.user,
    required this.authProvider,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _showGeologicalFeed = false;
  String _activeRoute = 'NH-06 (Recommended)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TiyraSense Driver',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.user.fullName} • On Active Duty',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary),
            tooltip: 'Alerts',
            onPressed: () => _showCorridorAlertsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              await widget.authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(authProvider: widget.authProvider),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Freshness Telemetry Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.satellite_alt_rounded, color: AppTheme.success, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'GPS / NavIC Locked • Node Mesh #NER-14',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Updated 2m ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Operator Greeting & Heavy Vehicle Manifest Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FLEET REG: NL-01-A-8942',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Active Shift',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CARGO: CRITICAL FMCG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Good day, ${widget.user.fullName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tata Prima 2830.K (31T Gross) • Dimapur ↔ Guwahati Transit',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Operational Corridor Status Card (Preserves "Corridor Status: PASSABLE" for test)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Corridor Status: PASSABLE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'NH-06 Guwahati ↔ Shillong Expressway',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'LIVE SENSING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'One-way convoy escort lifted at Nongpoh. Both lanes operational.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Core Telemetry Triplet Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPERATIONAL TELEMETRY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryMetric(
                          icon: Icons.speed_rounded,
                          label: 'Traffic Flow',
                          value: 'Regulated',
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryMetric(
                          icon: Icons.landslide_rounded,
                          label: 'Slip Probability',
                          value: '18% Low',
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryMetric(
                          icon: Icons.verified_user_rounded,
                          label: 'Verification',
                          value: '98% Conf.',
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Accordion Toggle for Geological Sensors
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showGeologicalFeed = !_showGeologicalFeed;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showGeologicalFeed ? 'Hide Geological Sensors' : 'View Geological Sensor Feed',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          Icon(
                            _showGeologicalFeed ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showGeologicalFeed) ...[
                    const Divider(height: 14),
                    _buildGeoSensorRow('Slope Pore Pressure', '22.4 kPa (Nominal)', AppTheme.success),
                    _buildGeoSensorRow('Acoustic Rockfall Sensor', 'Zero Shifting', AppTheme.success),
                    _buildGeoSensorRow('Seepage Gauge Km 42', '4.2 mm/hr (Clear)', AppTheme.success),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Primary Operational CTA: Plan a Safer Journey
            ElevatedButton(
              onPressed: () => _showJourneyPlanningBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.alt_route_rounded, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan a Safer Journey',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'AI checks slope slip, convoy wait times & detours',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Tactical Operational Grid (4 Tools)
            const Text(
              'FIELD LOGISTICS QUICK-ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _buildQuickActionTile(
                  icon: Icons.add_alert_rounded,
                  title: 'Report Hazard',
                  subtitle: 'Mud, Rock, Slip',
                  tag: '1-Tap',
                  color: AppTheme.warning,
                  onTap: () => _showReportHazardBottomSheet(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.notification_important_rounded,
                  title: 'Corridor Alerts',
                  subtitle: 'NH-29 & NH-06',
                  tag: '2 Active',
                  color: AppTheme.statusRestricted,
                  onTap: () => _showCorridorAlertsDialog(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.thunderstorm_rounded,
                  title: 'Radar & Rain',
                  subtitle: 'Doppler Telemetry',
                  tag: '8mm/h',
                  color: AppTheme.primary,
                  onTap: () => _showWeatherRadarDialog(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.emergency_rounded,
                  title: 'SOS Emergency',
                  subtitle: 'BRO / Police Post',
                  tag: 'Priority',
                  color: AppTheme.critical,
                  onTap: () => _showEmergencyDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Journey Waypoint Stepper
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Route Timeline',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _activeRoute,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTimelineItem(
                    title: 'Guwahati Port Hub (Origin)',
                    subtitle: 'Dep: 05:30 AM • KM 0.0',
                    isFirst: true,
                    isPassed: true,
                  ),
                  _buildTimelineItem(
                    title: 'Jorabat Junction Checkpost',
                    subtitle: 'Clear passage • KM 18.2',
                    isPassed: true,
                  ),
                  _buildTimelineItem(
                    title: 'Nongpoh Transit Sector',
                    subtitle: 'Light rain • KM 52.4 (Current)',
                    isPassed: false,
                    isCurrent: true,
                  ),
                  _buildTimelineItem(
                    title: 'Shillong Terminal Hub (Destination)',
                    subtitle: 'ETA: 08:15 AM • KM 98.4',
                    isLast: true,
                    isPassed: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildTelemetryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _buildGeoSensorRow(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
    bool isPassed = false,
    bool isCurrent = false,
  }) {
    Color dotColor = isPassed ? AppTheme.success : (isCurrent ? AppTheme.primary : AppTheme.textMuted);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isPassed ? AppTheme.success : AppTheme.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isCurrent ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  void _showJourneyPlanningBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Plan a Safer Journey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Text(
                'Select routing preference for Guwahati ↔ Shillong corridor',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Route Option A (Recommended)
              InkWell(
                onTap: () {
                  setState(() => _activeRoute = 'NH-06 (Recommended)');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selected Recommended Safe Route via NH-06'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OPTION A: RECOMMENDED SAFEST',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                          Text(
                            'Risk Score: 0.18 (Low)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'via NH-06 Express Corridor',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '98.4 km • ETA 2h 15m • Bypasses active landslide alerts near Pagla Pahar',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Route Option B (Fastest)
              InkWell(
                onTap: () {
                  setState(() => _activeRoute = 'NH-29 (Fastest)');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selected Fastest Route via NH-29 Ridge'),
                      backgroundColor: AppTheme.warning,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OPTION B: FASTEST AVAILABLE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                          Text(
                            'Risk Score: 0.64 (High)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'via NH-29 Mountain Ridge',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '89.0 km • ETA 1h 58m (-17m) • Active mudflow advisory at KM 14.8',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showReportHazardBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Road Hazard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Text('Tag hazard at your current location on NH-06', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.landscape_rounded, color: AppTheme.warning),
                title: const Text('Landslide / Mudflow'),
                subtitle: const Text('Debris or boulders obstructing passage'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Landslide report submitted for verification'), backgroundColor: AppTheme.success),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.water_damage_rounded, color: AppTheme.primary),
                title: const Text('Flash Flood / Culvert Overflow'),
                subtitle: const Text('Water crossing roadway'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Water inundation report submitted'), backgroundColor: AppTheme.success),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCorridorAlertsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notification_important_rounded, color: AppTheme.statusRestricted),
            SizedBox(width: 8),
            Text('Corridor Advisories'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. NH-29 Km 14.8: Single-lane convoy active due to rockfall clearance.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 8),
            Text('2. NH-06 Umiam Sector: Dense fog reducing visibility to <50m.', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
        ],
      ),
    );
  }

  void _showWeatherRadarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doppler Radar Telemetry'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Rainfall Intensity: 8.4 mm/hr (Light to Moderate)', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('• 3-Hour Forecast: Monsoon band moving North towards Nongpoh', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('• Road Grip Index: 88% (Adequate for multi-axle freight)', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppTheme.critical),
            SizedBox(width: 8),
            Text('SOS Emergency Mode'),
          ],
        ),
        content: const Text(
          'Broadcast distress beacon to Nearest Border Roads Organisation (BRO) Camp (4.2 km) and Assam Highway Patrol?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.critical),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency beacon transmitted. Help is notified.'),
                  backgroundColor: AppTheme.critical,
                ),
              );
            },
            child: const Text('Transmit SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
