import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/alert_service.dart';
import '../services/localization_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/status_pill_badge.dart';
import '../widgets/app_logo.dart';
import '../widgets/side_drawer.dart';
import '../widgets/journey_planning_sheet.dart';
import '../widgets/hazard_report_sheet.dart';
import 'driver_map_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'report_history_screen.dart';

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
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _selectedRouteData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.canvas,
      drawer: SideDrawer(
        role: UserRole.driver,
        activeItem: _currentTabIndex == 0
            ? 'Dashboard'
            : (_currentTabIndex == 1 ? 'Route Planner' : (_currentTabIndex == 3 ? 'Alerts' : '')),
        onRoutePlannerTap: () => JourneyPlanningSheet.show(
          context,
          onRouteSelected: (routeData) {
            setState(() {
              _selectedRouteData = routeData;
              _currentTabIndex = 1;
            });
          },
        ),
        onAlertsTap: () => setState(() => _currentTabIndex = 3),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeDashboard(context),
          DriverMapScreen(
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            initialRouteData: _selectedRouteData,
            apiServiceOverride: widget.authProvider.apiService,
          ),
          _buildJourneyTabPlaceholder(context),
          AlertsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          ProfileScreen(
            role: UserRole.driver,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.user.role == UserRole.fieldWorker
                        ? localizationService.tr('field_recon_active')
                        : localizationService.tr('on_duty_escort'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLow,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: alertService,
            builder: (context, _) {
              final hasUnread = alertService.unreadCount > 0;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.textMid),
                    onPressed: () {
                      setState(() => _currentTabIndex = 3);
                      alertService.markSeenAsRead();
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: Center(
        child: ResponsiveWrapper(
          maxWidth: 840,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Block 1 — GPS Strip
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.satellite_alt_rounded, size: 16, color: AppTheme.green),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                localizationService.tr('gps_locked'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textHigh,
                                  letterSpacing: 0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localizationService.tr('updated_ago'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.textLow,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Block 2 — Corridor Status Card
                GestureDetector(
                  onTap: () => setState(() => _currentTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                      Row(
                        children: [
                          // 44px green-tinted square
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.greenBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.green.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NH-06 Guwahati to Shillong',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textHigh,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Segment ID: NER-AS-ML-006',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textLow),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const StatusPillBadge(status: BadgeStatusType.passable),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.container,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localizationService.tr('normal_flow'),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Block 3 — Telemetry Row
              Text(
                localizationService.tr('operational_telemetry'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLow,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTelemetryTile(
                    icon: Icons.speed_rounded,
                    iconColor: AppTheme.primaryBlue,
                    label: localizationService.tr('traffic'),
                    value: localizationService.tr('traffic_regulated'),
                    valueColor: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _buildTelemetryTile(
                    icon: Icons.landslide_rounded,
                    iconColor: AppTheme.green,
                    label: localizationService.tr('slip_risk'),
                    value: localizationService.tr('slip_risk_low'),
                    valueColor: AppTheme.green,
                  ),
                  const SizedBox(width: 8),
                  _buildTelemetryTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppTheme.green,
                    label: localizationService.tr('confidence'),
                    value: localizationService.tr('confidence_val'),
                    valueColor: AppTheme.green,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Block 4 — Journey CTA Button
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: () => JourneyPlanningSheet.show(
                    context,
                    onRouteSelected: (routeData) {
                      setState(() {
                        _selectedRouteData = routeData;
                        _currentTabIndex = 1;
                      });
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alt_route_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizationService.tr('plan_safer_journey'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizationService.tr('ai_checks_risk'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xB3FFFFFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Block 5 — Quick Actions Grid (Adaptive 2 to 4 cols)
              Text(
                localizationService.tr('quick_actions'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLow,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: Responsive.gridColumns(context, compact: 2, phone: 2, tablet: 4, desktop: 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: Responsive.isTablet(context) ? 1.45 : (Responsive.isCompact(context) ? 1.3 : 1.4),
                children: [
                  _buildQuickActionCard(
                    icon: Icons.add_alert_rounded,
                    iconColor: AppTheme.amber,
                    bgColor: AppTheme.amberBg,
                    tag: '1-Tap',
                    title: localizationService.tr('report_hazard'),
                    subtitle: localizationService.tr('mud_rock_slip'),
                    onTap: () => HazardReportSheet.show(context),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.orange,
                    bgColor: const Color(0xFFFFF7ED),
                    tag: '2 Active',
                    title: localizationService.tr('corridor_alerts'),
                    subtitle: 'NH-29 & NH-06',
                    onTap: () => setState(() => _currentTabIndex = 3),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.thunderstorm_outlined,
                    iconColor: AppTheme.primaryBlue,
                    bgColor: AppTheme.blueBg,
                    tag: '8mm/h',
                    title: localizationService.tr('weather_radar'),
                    subtitle: localizationService.tr('doppler_feed'),
                    onTap: () => SideDrawer.showWeatherWatchSheet(context),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.emergency_rounded,
                    iconColor: AppTheme.red,
                    bgColor: AppTheme.redBg,
                    tag: localizationService.tr('priority'),
                    title: localizationService.tr('sos_police'),
                    subtitle: localizationService.tr('bro_police_post'),
                    onTap: () => SideDrawer.showEmergencySosSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu_rounded, color: Color(0xFF0D9488), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizationService.tr('incident_reports_history'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizationService.tr('view_field_submissions'),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textLow),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Block 6 — Active Route Timeline Card
              GestureDetector(
                onTap: () => setState(() => _currentTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Active Route Timeline',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textHigh,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.blueLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NH-06 CORRIDOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineWaypoint(
                      title: 'Guwahati Port Hub',
                      subtitle: 'Dep: 06:15 AM · Cleared',
                      isPassed: true,
                      isLast: false,
                    ),
                    _buildTimelineWaypoint(
                      title: 'Jorabat Junction (KM 18)',
                      subtitle: 'Passed: 07:10 AM · Smooth Flow',
                      isPassed: true,
                      isLast: false,
                    ),
                    _buildTimelineWaypoint(
                      title: 'Nongpoh Checkpoint (KM 52)',
                      subtitle: 'Current Location · ETA Rest Stop 09:30 AM',
                      isCurrent: true,
                      isLast: false,
                    ),
                    _buildTimelineWaypoint(
                      title: 'Shillong Terminal Hub (KM 98)',
                      subtitle: 'Est. Arrival: 12:20 PM · Clear Bay',
                      isPassed: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.container,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLow,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String tag,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.cardShadow,
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
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineWaypoint({
    required String title,
    required String subtitle,
    bool isPassed = false,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    Color dotColor = AppTheme.borderMed;
    if (isPassed) dotColor = AppTheme.green;
    if (isCurrent) dotColor = AppTheme.primaryBlue;

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
                border: isCurrent ? Border.all(color: AppTheme.blueLight, width: 3) : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isPassed ? AppTheme.green : AppTheme.borderLight,
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
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: AppTheme.textHigh,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
              ),
              if (!isLast) const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyTabPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alt_route_rounded, size: 64, color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            const Text(
              'Dynamic Route Planner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select corridors and calculate multi-factor terrain risk penalties.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textLow),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => JourneyPlanningSheet.show(
                context,
                onRouteSelected: (routeData) {
                  setState(() {
                    _selectedRouteData = routeData;
                    _currentTabIndex = 1;
                  });
                },
              ),
              child: const Text('Open Journey Sheet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.navShadow,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavTab(0, Icons.home_rounded, localizationService.tr('home')),
              _buildNavTab(1, Icons.map_rounded, localizationService.tr('map')),
              _buildNavTab(2, Icons.alt_route_rounded, localizationService.tr('plan')),
              _buildNavTab(3, Icons.notifications_rounded, localizationService.tr('alerts')),
              _buildNavTab(4, Icons.person_rounded, localizationService.tr('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 2) {
            JourneyPlanningSheet.show(context);
          } else {
            setState(() {
              _currentTabIndex = index;
              if (index == 3) {
                alertService.markSeenAsRead();
              }
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Blue indicator pip above active tab
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 2),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textLow,
                ),
                if (index == 3)
                  ListenableBuilder(
                    listenable: alertService,
                    builder: (context, _) {
                      if (alertService.unreadCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -2,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}
