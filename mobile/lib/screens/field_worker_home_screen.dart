import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_status_badge.dart';
import 'login_screen.dart';

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

class _FieldReport {
  final String title;
  final String location;
  final String time;
  final String status;
  final Color statusColor;

  _FieldReport({
    required this.title,
    required this.location,
    required this.time,
    required this.status,
    required this.statusColor,
  });
}

class _FieldWorkerHomeScreenState extends State<FieldWorkerHomeScreen> {
  final SyncStatus _syncStatus = SyncStatus.online;
  int _pendingSyncCount = 0;

  final List<_FieldReport> _reports = [
    _FieldReport(
      title: 'Boulder Roll-Down on NH-06 Shoulder',
      location: 'KM 52.3 near Nongpoh',
      time: 'Today, 06:20 AM',
      status: 'VERIFIED',
      statusColor: AppTheme.success,
    ),
    _FieldReport(
      title: 'Culvert Water Inundation (20cm)',
      location: 'KM 38.1 Jorabat Section',
      time: 'Yesterday, 04:45 PM',
      status: 'CLEARED',
      statusColor: AppTheme.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field Worker Console',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.user.fullName} • Disaster Response Unit',
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
            // Connectivity & GPS Precision Status Card
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wifi_tethering_rounded, size: 20, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Connectivity & Sync',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SyncStatusBadge(status: _syncStatus, pendingCount: _pendingSyncCount),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location_rounded, size: 16, color: AppTheme.success),
                            SizedBox(width: 6),
                            Text(
                              'Sector: NH-06 KM 42.8',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '±2.1m Precision • WGS-84',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Primary Emergency Action: Report Road Hazard / Blockage
            ElevatedButton.icon(
              onPressed: () => _openHazardReportSheet(context),
              icon: const Icon(Icons.add_alert_rounded, size: 22),
              label: const Text(
                'Report Road Hazard / Blockage',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.critical,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 14),

            // Quick Category Selector
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
                  const Text(
                    'QUICK HAZARD DISPATCH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
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
                    childAspectRatio: 2.1,
                    children: [
                      _buildHazardCategoryTile(
                        icon: Icons.landscape_rounded,
                        label: 'Landslide',
                        color: const Color(0xFFD97706),
                      ),
                      _buildHazardCategoryTile(
                        icon: Icons.flood_rounded,
                        label: 'Flash Flood',
                        color: const Color(0xFF0284C7),
                      ),
                      _buildHazardCategoryTile(
                        icon: Icons.broken_image_rounded,
                        label: 'Subsidence',
                        color: const Color(0xFFDC2626),
                      ),
                      _buildHazardCategoryTile(
                        icon: Icons.park_rounded,
                        label: 'Fallen Tree',
                        color: const Color(0xFF059669),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Recent Field Submissions Queue
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
                        'Recent Field Reports',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Synced with ASDMA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reports.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (ctx, index) {
                      final r = _reports[index];
                      return _buildReportItem(
                        title: r.title,
                        location: r.location,
                        time: r.time,
                        status: r.status,
                        statusColor: r.statusColor,
                      );
                    },
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

  Widget _buildHazardCategoryTile({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openHazardReportSheet(context, preselectedType: label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '$location • $time',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
      ],
    );
  }

  void _openHazardReportSheet(BuildContext context, {String preselectedType = 'Landslide'}) {
    String selectedType = preselectedType;
    String selectedSeverity = 'Partial Lane Blockage';
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                    'Submit Field Hazard Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Report real-time obstruction tagged with current GPS coordinates',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // GPS Geolocation auto-tag
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.gps_fixed_rounded, size: 16, color: AppTheme.success),
                        SizedBox(width: 8),
                        Text(
                          'NH-06 KM 42.8 (26.0124° N, 91.8901° E)',
                          style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hazard Type Selector
                  const Text('Hazard Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Landslide', 'Flash Flood', 'Subsidence', 'Fallen Tree'].map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setSheetState(() => selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Blockage Severity
                  const Text('Passage Impact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Partial Lane Blockage', 'Full Road Closure', 'Shoulder Erosion'].map((sev) {
                      final isSelected = selectedSeverity == sev;
                      return ChoiceChip(
                        label: Text(sev),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setSheetState(() => selectedSeverity = sev);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Notes TextField
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Observations (optional)',
                      hintText: 'e.g., Heavy gravel, clearance team on site',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.critical,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _reports.insert(
                            0,
                            _FieldReport(
                              title: '$selectedType: $selectedSeverity',
                              location: 'KM 42.8 Jorabat-Nongpoh',
                              time: 'Just now',
                              status: 'DISPATCHED',
                              statusColor: AppTheme.warning,
                            ),
                          );
                          _pendingSyncCount++;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$selectedType report dispatched to ASDMA queue!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                      child: const Text('Broadcast Incident Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
