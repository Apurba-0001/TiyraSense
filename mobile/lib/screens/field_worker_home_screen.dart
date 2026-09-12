import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/alert_service.dart';
import '../services/localization_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_pill_badge.dart';
import '../widgets/app_logo.dart';
import '../widgets/side_drawer.dart';
import '../widgets/hazard_report_sheet.dart';
import 'field_worker_map_screen.dart';
import 'profile_screen.dart';
import 'report_history_screen.dart';
import 'alerts_screen.dart';

class FieldWorkerHomeScreen extends StatefulWidget {
  final UserModel user;
  final AuthProvider authProvider;

  const FieldWorkerHomeScreen({
    super.key,
    required this.user,
    required this.authProvider,
  });

  @override
  State<FieldWorkerHomeScreen> createState() => _FieldWorkerHomeScreenState();
}

class _FieldWorkerHomeScreenState extends State<FieldWorkerHomeScreen> {
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.canvas,
      drawer: SideDrawer(
        role: UserRole.fieldWorker,
        activeItem: _currentTabIndex == 0
            ? 'Dashboard'
            : (_currentTabIndex == 1 ? 'Map' : (_currentTabIndex == 2 ? 'My Reports' : 'Profile')),
        onSubmitReportTap: () => HazardReportSheet.show(context),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeDashboard(context),
          FieldWorkerMapScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          ReportHistoryScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          ProfileScreen(
            role: UserRole.fieldWorker,
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
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  localizationService.tr('field_recon_active'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLow,
                    fontWeight: FontWeight.w500,
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
                    tooltip: 'Alerts',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: AlertsScreen(
                              onOpenDrawer: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      );
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1 — Connectivity Card
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wifi_tethering_rounded, size: 20, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            localizationService.tr('connectivity_sync'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textHigh,
                            ),
                          ),
                        ],
                      ),
                      const StatusPillBadge(status: BadgeStatusType.online),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.container,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location_rounded, size: 16, color: AppTheme.green),
                            SizedBox(width: 6),
                            Text(
                              'Sector: NH-06 KM 42.8',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textHigh,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+/- 2.1m · WGS-84',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Button 2 — Primary Hazard Report (Visually Dominant)
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: () => HazardReportSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 2,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_alert_rounded, size: 24, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizationService.tr('report_road_hazard'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'GPS tagged · synced to ASDMA command',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 3 — Quick Dispatch 2x2 Grid
            Container(
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
                  Text(
                    localizationService.tr('quick_dispatch'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLow,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      _buildQuickDispatchTile(
                        icon: Icons.landscape_rounded,
                        label: localizationService.tr('hazard_landslide'),
                        color: AppTheme.amber,
                        bgColor: AppTheme.amberBg,
                        onTap: () => HazardReportSheet.show(context, initialHazardType: 'Landslide'),
                      ),
                      _buildQuickDispatchTile(
                        icon: Icons.flood_rounded,
                        label: localizationService.tr('hazard_flood'),
                        color: AppTheme.primaryBlue,
                        bgColor: AppTheme.blueBg,
                        onTap: () => HazardReportSheet.show(context, initialHazardType: 'Flash Flood'),
                      ),
                      _buildQuickDispatchTile(
                        icon: Icons.broken_image_rounded,
                        label: localizationService.tr('hazard_subsidence'),
                        color: AppTheme.red,
                        bgColor: AppTheme.redBg,
                        onTap: () => HazardReportSheet.show(context, initialHazardType: 'Subsidence'),
                      ),
                      _buildQuickDispatchTile(
                        icon: Icons.park_rounded,
                        label: localizationService.tr('hazard_fallen_tree'),
                        color: AppTheme.green,
                        bgColor: AppTheme.greenBg,
                        onTap: () => HazardReportSheet.show(context, initialHazardType: 'Fallen Tree'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 4 — Recent Reports
            Container(
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
                      const Text(
                        'Recent Reports',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHigh,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.container,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Synced',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentReportRow(
                    title: 'Boulder Roll-Down on NH-06 Shoulder',
                    subtitle: 'KM 52.3 · Today 06:20 AM',
                    statusDotColor: AppTheme.green,
                    badge: const StatusPillBadge(status: BadgeStatusType.passable, customLabel: 'VERIFIED'),
                  ),
                  const Divider(color: AppTheme.borderLight, height: 20),
                  _buildRecentReportRow(
                    title: 'Culvert Water Inundation',
                    subtitle: 'KM 38.1 · Yesterday 17:45',
                    statusDotColor: AppTheme.amber,
                    badge: const StatusPillBadge(status: BadgeStatusType.caution, customLabel: 'DISPATCHED'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentTabIndex = 2),
                      icon: const Icon(Icons.history_edu_rounded, size: 16),
                      label: const Text('View All Incident Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.blueLight),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDispatchTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportRow({
    required String title,
    required String subtitle,
    required Color statusDotColor,
    required Widget badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusDotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
              ),
            ],
          ),
        ),
        badge,
      ],
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
              _buildNavTab(2, Icons.list_alt_rounded, localizationService.tr('report_history')),
              _buildNavTab(3, Icons.person_rounded, localizationService.tr('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textLow,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
