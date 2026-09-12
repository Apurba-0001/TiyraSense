import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/localization_service.dart';
import '../services/vehicle_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';
import 'hazard_report_sheet.dart';
import 'vehicle_profile_sheet.dart';
import '../screens/report_history_screen.dart';

/// Tactical Utilities & Field Support Side Drawer.
/// Contains only non-duplicate operational tools (Offline Cache, Emergency SOS,
/// Quick Hazard Reporting, Vehicle Profile, Weather Radar, and Sign Out).
class SideDrawer extends StatelessWidget {
  final UserRole role;
  final VoidCallback? onSubmitReportTap;
  final VoidCallback? onSyncStatusTap;
  final VoidCallback? onAlertsTap;

  const SideDrawer({
    super.key,
    required this.role,
    String? activeItem,
    VoidCallback? onRoutePlannerTap,
    this.onAlertsTap,
    this.onSubmitReportTap,
    this.onSyncStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;
    final userName = user?.fullName ??
        (switch (role) {
          UserRole.driver => 'Ramen Borah',
          UserRole.fieldWorker => 'Dipankar Saikia',
          UserRole.official => 'Pranjal Sarmah',
          UserRole.admin => 'Priya Sharma',
        });
    final roleName = switch (role) {
      UserRole.driver => 'COMMERCIAL DRIVER',
      UserRole.fieldWorker => 'FIELD DISASTER WORKER',
      UserRole.official => 'OPERATIONS COMMAND (OFFICIAL)',
      UserRole.admin => 'SYSTEM ADMINISTRATOR',
    };
    final initials = userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();

    return Drawer(
      width: 290,
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // Header (Gradient Brand Block)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: role == UserRole.admin
                    ? const [Color(0xFF1E1B4B), Color(0xFF4338CA)]
                    : (role == UserRole.official
                        ? const [Color(0xFF0F172A), AppTheme.blueDark]
                        : const [AppTheme.primaryBlue, AppTheme.blueDark]),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo.icon(size: 42, radius: 10),
                      const Spacer(),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials.isNotEmpty ? initials : 'TS',
                          style: TextStyle(
                            color: role == UserRole.admin ? const Color(0xFF4338CA) : AppTheme.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          roleName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 3),
                      const Text(
                        'ONLINE',
                        style: TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tactical Utilities Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    role == UserRole.admin
                        ? 'ADMINISTRATIVE GOVERNANCE'
                        : (role == UserRole.official ? 'OPERATIONAL COMMAND' : 'TACTICAL UTILITIES'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textLow,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // 1. Offline Maps & Storage Sync
                _buildDrawerItem(
                  icon: Icons.cloud_done_rounded,
                  iconColor: AppTheme.primaryBlue,
                  label: 'Offline Maps & Sync',
                  subtitle: 'NH-06 Corridor Cached • 19.2 MB',
                  onTap: () {
                    final nav = Navigator.of(context, rootNavigator: true);
                    Navigator.of(context).pop();
                    showOfflineSyncSheet(nav.context);
                  },
                ),

                // 2. Emergency Highway SOS
                _buildDrawerItem(
                  icon: Icons.emergency_rounded,
                  iconColor: AppTheme.red,
                  label: localizationService.tr('emergency_sos'),
                  subtitle: 'Highway Patrol 112 • ASDMA 1070',
                  onTap: () {
                    final nav = Navigator.of(context, rootNavigator: true);
                    Navigator.of(context).pop();
                    showEmergencySosSheet(nav.context);
                  },
                ),

                if (role == UserRole.official) ...[
                  _buildDrawerItem(
                    icon: Icons.campaign_rounded,
                    iconColor: AppTheme.red,
                    label: 'Trigger Corridor Alert',
                    subtitle: 'Broadcast road disruption advisory',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onAlertsTap != null) onAlertsTap!();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.fact_check_rounded,
                    iconColor: const Color(0xFF0D9488),
                    label: 'Ground Verification Queue',
                    subtitle: 'Validate citizen & patrol reports',
                    onTap: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      nav.push(
                        MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                      );
                    },
                  ),
                ] else if (role == UserRole.admin) ...[
                  _buildDrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    label: 'User Directory & Access',
                    subtitle: 'Manage roles and account states',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.dns_rounded,
                    iconColor: const Color(0xFF0D9488),
                    label: 'Data Source Diagnostics',
                    subtitle: 'PostGIS, OSRM & IMD health probes',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ] else ...[
                  // 3. Quick Hazard Reporting (Driver & Field Worker)
                  _buildDrawerItem(
                    icon: Icons.add_alert_rounded,
                    iconColor: AppTheme.amber,
                    label: localizationService.tr('report_hazard'),
                    subtitle: 'Landslide, Flood, or Obstacle',
                    onTap: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      if (onSubmitReportTap != null) {
                        onSubmitReportTap!();
                      } else {
                        HazardReportSheet.show(nav.context);
                      }
                    },
                  ),

                  // 4. Incident Report History
                  _buildDrawerItem(
                    icon: Icons.history_edu_rounded,
                    iconColor: const Color(0xFF0D9488),
                    label: localizationService.tr('report_history'),
                    subtitle: 'Your submissions & verification status',
                    onTap: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      nav.push(
                        MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                      );
                    },
                  ),

                  // 5. Vehicle / Kit Configuration
                  ListenableBuilder(
                    listenable: vehicleService,
                    builder: (context, _) {
                      final veh = vehicleService.selectedVehicle;
                      return _buildDrawerItem(
                        icon: role == UserRole.driver ? Icons.local_shipping_rounded : Icons.handyman_rounded,
                        iconColor: const Color(0xFF0D9488),
                        label: role == UserRole.driver ? localizationService.tr('truck_axle_specs') : 'Field Inspection Kit',
                        subtitle: role == UserRole.driver
                            ? '${veh.title} • ${veh.grossWeight.split('(').first.trim()}'
                            : 'GPS Calibrated • Geotag Active',
                        onTap: () {
                          final nav = Navigator.of(context, rootNavigator: true);
                          Navigator.of(context).pop();
                          if (role == UserRole.driver) {
                            VehicleProfileSheet.show(nav.context);
                          } else {
                            showEquipmentProfileSheet(nav.context, role: role);
                          }
                        },
                      );
                    },
                  ),
                ],

                // Monsoon & Landslide Watch
                _buildDrawerItem(
                  icon: Icons.thunderstorm_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  label: localizationService.tr('monsoon_watch'),
                  subtitle: 'IMD Rain Advisory • Moderate Risk',
                  onTap: () {
                    final nav = Navigator.of(context, rootNavigator: true);
                    Navigator.of(context).pop();
                    showWeatherWatchSheet(nav.context);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(color: AppTheme.borderLight, height: 1),
                ),

                // Sign Out
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.red,
                  label: localizationService.tr('log_out'),
                  subtitle: 'End local session on this device',
                  isDestructive: true,
                  onTap: () async {
                    final nav = Navigator.of(context, rootNavigator: true);
                    Navigator.of(context).pop();
                    await authProvider.logout();
                    nav.pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ],
            ),
          ),

          // Footer with official logo
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  const AppLogo.horizontal(height: 18),
                  const SizedBox(height: 4),
                  const Text(
                    'TiyraSense Mobile v1.0 • SIH 2026',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDestructive ? const Color(0xFFFEE2E2) : iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDestructive ? AppTheme.red : AppTheme.textHigh,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textLow,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.borderMed, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tactical Modal 1: Offline Sync & Storage
  static void showOfflineSyncSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline Maps & Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('High-resolution NER road segments cached', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('NH-06 Guwahati-Shillong', '14.2 MB (Ready)'),
            _buildStatusRow('NH-102 Imphal-Moreh', '8.4 MB (Ready)'),
            _buildStatusRow('Pending Offline Hazard Queue', '0 Reports Pending'),
            _buildStatusRow('Last Sync with Server', 'Just now'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Offline cache synchronized with TiyraSense server.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Refresh Cache Now'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tactical Modal 2: Emergency SOS Directory
  static void showEmergencySosSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: AppTheme.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Highway Helplines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('Direct dispatch for road blockades & recovery', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEmergencyContactRow(context, 'National Emergency & Highway Police', '112', Icons.local_police_rounded),
            _buildEmergencyContactRow(context, 'ASDMA Disaster Response Room', '1070', Icons.shield_rounded),
            _buildEmergencyContactRow(context, 'NER Commercial Crane & Towing', '+91-361-2237000', Icons.car_crash_rounded),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Tactical Modal 3: Equipment & Vehicle Profile
  static void showEquipmentProfileSheet(BuildContext context, {UserRole role = UserRole.driver}) {
    final isDriver = role == UserRole.driver;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (sheetContext) => ListenableBuilder(
        listenable: vehicleService,
        builder: (context, _) {
          final veh = vehicleService.selectedVehicle;
          final cargo = vehicleService.selectedCargo;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDriver ? 'Truck & Axle Specifications' : 'Field Inspection Equipment',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isDriver ? 'Configured for risk evaluation along hilly terrain' : 'Diagnostic telemetry sensor statuses',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                ),
                const SizedBox(height: 16),
                if (isDriver) ...[
                  _buildStatusRow('Vehicle Class', '${veh.category} (${veh.title})'),
                  _buildStatusRow('Gross Registered Weight', veh.grossWeight),
                  _buildStatusRow('Maximum Hill Gradient', veh.maxGradient),
                  _buildStatusRow('Cargo Classification', cargo.title),
                  _buildStatusRow('Telematics GPS Ping', veh.telematicsStatus),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        VehicleProfileSheet.show(context);
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Switch Vehicle & Cargo Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  _buildStatusRow('Survey Hardware Kit', 'Laser Ranger + Handheld GNSS'),
                  _buildStatusRow('Position Accuracy', '±0.4m CEP (Barapani Base)'),
                  _buildStatusRow('Geotag Image Storage', 'Active (Local encrypted)'),
                  _buildStatusRow('Offline Report Cache', 'Synchronized'),
                ],
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tactical Modal 4: Weather & Landslide Watch
  static void showWeatherWatchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NER Monsoon & Landslide Watch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('IMD radar and regional soil saturation advisory', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
            const SizedBox(height: 16),
            _buildStatusRow('NH-06 Nongpoh Sector', 'Continuous Moderate Rain (28mm/24h)'),
            _buildStatusRow('Landslide Hazard Index', 'MEDIUM (Caution on cut slopes)'),
            _buildStatusRow('Barapani Bridge Level', 'Normal Operational Clearance'),
            _buildStatusRow('Next IMD Advisory Update', 'In 45 minutes'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatusRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textHigh, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Widget _buildEmergencyContactRow(BuildContext context, String label, String number, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing $label ($number)...'),
            backgroundColor: AppTheme.green,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.container,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.red, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(number, style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('DIAL', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
