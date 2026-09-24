import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_logo.dart';
import '../widgets/status_pill_badge.dart';

class AlertsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const AlertsScreen({super.key, this.onOpenDrawer});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _activeFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    alertService.addListener(_onAlertsChanged);
    alertService.syncLiveAlerts();
  }

  @override
  void dispose() {
    alertService.removeListener(_onAlertsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAlertsChanged() {
    if (mounted) setState(() {});
  }

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final corridorCtrl = TextEditingController(text: 'NH-06');
    final sectorCtrl = TextEditingController(text: 'Ri-Bhoi Corridor');
    String selectedSev = 'EMERGENCY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cell_tower_rounded, color: AppTheme.darkRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Broadcast Corridor Alert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Corridor & Sector', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                const SizedBox(height: 4),
                TextField(
                  controller: corridorCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. NH-06',
                    filled: true,
                    fillColor: AppTheme.container,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sectorCtrl,
                  decoration: InputDecoration(
                    hintText: 'Sector (e.g. KM 52-54)',
                    filled: true,
                    fillColor: AppTheme.container,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Severity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedSev,
                  items: ['EMERGENCY', 'HIGH RISK', 'CAUTION', 'INFO'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setDlgState(() => selectedSev = v ?? 'EMERGENCY'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.container,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Alert Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Short summary headline',
                    filled: true,
                    fillColor: AppTheme.container,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                const SizedBox(height: 4),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Operational advisory details for field units & drivers...',
                    filled: true,
                    fillColor: AppTheme.container,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textLow)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cell_tower_rounded, size: 16),
              label: const Text('Broadcast Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkRed, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Operational alert broadcast across all monitored sectors.';
                final corridor = corridorCtrl.text.trim();
                final kmRange = sectorCtrl.text.trim();
                final sev = selectedSev;

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Broadcasting advisory to central command...'), backgroundColor: AppTheme.darkRed),
                );

                try {
                  await ApiService().broadcastAlert(
                    severity: sev,
                    corridor: corridor,
                    title: title,
                    description: desc,
                  );
                } catch (_) {}

                alertService.addAlert(
                  severity: sev,
                  corridor: corridor,
                  kmRange: kmRange,
                  category: sev == 'EMERGENCY' ? 'EMERGENCY' : 'CORRIDOR',
                  location: '$corridor $kmRange',
                  title: title,
                  desc: desc,
                  status: sev == 'EMERGENCY' ? BadgeStatusType.blocked : BadgeStatusType.caution,
                  isEmergency: sev == 'EMERGENCY',
                  source: 'Field Command Unit',
                  pushNotification: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts = alertService.alerts;
    final unreadCount = alertService.unreadCount;

    List<AlertItem> filteredAlerts;
    if (_activeFilter == 'ALL') {
      filteredAlerts = allAlerts;
    } else if (_activeFilter == 'UNREAD') {
      filteredAlerts = allAlerts.where((a) => !a.isRead).toList();
    } else if (_activeFilter == 'EMERGENCY') {
      filteredAlerts = allAlerts.where((a) => a.severity == 'EMERGENCY' || a.category == 'EMERGENCY').toList();
    } else if (_activeFilter == 'HIGH RISK') {
      filteredAlerts = allAlerts.where((a) => a.severity == 'HIGH RISK').toList();
    } else if (_activeFilter == 'CAUTION') {
      filteredAlerts = allAlerts.where((a) => a.severity == 'CAUTION').toList();
    } else if (_activeFilter == 'INFO') {
      filteredAlerts = allAlerts.where((a) => a.severity == 'INFO').toList();
    } else {
      filteredAlerts = allAlerts.where((a) => a.category == _activeFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredAlerts = filteredAlerts.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.desc.toLowerCase().contains(q) ||
            a.corridor.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q) ||
            a.id.toLowerCase().contains(q);
      }).toList();
    }

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
        title: Text(
          localizationService.tr('alerts'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textHigh,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cell_tower_rounded, color: AppTheme.darkRed, size: 22),
            tooltip: 'Broadcast Emergency Alert',
            onPressed: _showBroadcastDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryBlue, size: 20),
            tooltip: 'Sync Live Corridor Alerts',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing live alerts with command center...'),
                  backgroundColor: AppTheme.primaryBlue,
                  duration: Duration(seconds: 1),
                ),
              );
              await alertService.syncLiveAlerts();
            },
          ),
          TextButton(
            onPressed: () {
              final unread = alertService.unreadCount;
              alertService.acknowledgeAllAlerts();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(unread > 0 ? '$unread alerts marked as read & acknowledged' : 'All alerts are already marked read'),
                  backgroundColor: AppTheme.primaryBlue,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              localizationService.tr('mark_all_read'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveWrapper(
        maxWidth: 840,
        child: Column(
          children: [
            // Search Control Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: AppTheme.textLow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textHigh),
                      decoration: const InputDecoration(
                        hintText: 'Search alert title, corridor, or sector...',
                        hintStyle: TextStyle(fontSize: 12, color: AppTheme.textLow),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textLow),
                    ),
                ],
              ),
            ),
          ),

          // KPI Stats Strip (Emergency, High Risk, Caution, Informational)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildKpiCard('Emergency', '${alertService.emergencyCount}', AppTheme.darkRed),
                const SizedBox(width: 8),
                _buildKpiCard('High Risk', '${alertService.highRiskCount}', const Color(0xFFC2410C)),
                const SizedBox(width: 8),
                _buildKpiCard('Caution', '${alertService.cautionCount}', AppTheme.amber),
                const SizedBox(width: 8),
                _buildKpiCard('Info', '${alertService.infoCount}', AppTheme.primaryBlue),
              ],
            ),
          ),

          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', '${localizationService.tr('filter_all')} (${allAlerts.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('UNREAD', '${localizationService.tr('filter_unread')} ($unreadCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('EMERGENCY', localizationService.tr('filter_emergency')),
                  const SizedBox(width: 8),
                  _buildFilterChip('HIGH RISK', 'HIGH RISK'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CAUTION', 'CAUTION'),
                  const SizedBox(width: 8),
                  _buildFilterChip('INFO', 'INFO'),
                  const SizedBox(width: 8),
                  _buildFilterChip('WEATHER', localizationService.tr('filter_weather')),
                  const SizedBox(width: 8),
                  _buildFilterChip('CORRIDOR', 'CORRIDOR'),
                ],
              ),
            ),
          ),

          // Alerts List with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                alertService.markSeenAsRead();
                await alertService.syncLiveAlerts();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert telemetry synchronized with ASDMA corridor feeds'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: filteredAlerts.isEmpty
                  ? _buildEmptyState()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          alertService.markSeenAsRead();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: filteredAlerts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredAlerts[index];
                          return _buildAlertCard(item);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildKpiCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textLow, letterSpacing: 0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isActive = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : AppTheme.container,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textHigh,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertItem item) {
    final isEmergency = item.isEmergency || item.severity == 'EMERGENCY';
    final color = isEmergency
        ? AppTheme.darkRed
        : (item.severity == 'HIGH RISK'
            ? const Color(0xFFC2410C)
            : (item.severity == 'CAUTION' ? AppTheme.amber : AppTheme.primaryBlue));
    final bgColor = isEmergency
        ? AppTheme.redBg
        : (item.isRead ? AppTheme.surface.withValues(alpha: 0.75) : AppTheme.surface);

    return GestureDetector(
      onTap: () {
        alertService.markAsRead(item.id);
        _showAlertDetailsSheet(context, item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmergency
                ? AppTheme.red.withValues(alpha: 0.3)
                : (!item.isRead ? AppTheme.primaryBlue.withValues(alpha: 0.4) : AppTheme.borderLight),
            width: !item.isRead ? 1.5 : 1.0,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Accent Strip
            Container(
              width: 4,
              height: 140,
              decoration: BoxDecoration(
                color: item.isRead ? color.withValues(alpha: 0.4) : color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPillBadge(status: item.status, customLabel: item.severity),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.container,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            item.corridor,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            item.relativeTime,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: item.isRead ? AppTheme.textMid : AppTheme.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMid,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Affects tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.container,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Affects: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow)),
                          Text(item.affects, style: const TextStyle(fontSize: 10, color: AppTheme.textMid)),
                        ],
                      ),
                    ),
                    if (item.resolvedBy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Resolved by ${item.resolvedBy} · ${item.resolvedAt}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!item.isRead) ...[
                          GestureDetector(
                            onTap: () {
                              alertService.acknowledgeAlert(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Acknowledged ${item.id}'), duration: const Duration(seconds: 1)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Text(
                                'Acknowledge',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textHigh,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
                          onTap: () {
                            alertService.markAsRead(item.id);
                            _showAlertDetailsSheet(context, item);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.blueLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              localizationService.tr('view_details'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            alertService.dismissAlert(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Alert dismissed'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.container,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              localizationService.tr('dismiss'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLow,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            item.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_rounded,
                            size: 18,
                            color: item.isRead ? AppTheme.textLow : AppTheme.primaryBlue,
                          ),
                          tooltip: item.isRead ? 'Mark as unread' : 'Mark as read',
                          onPressed: () => alertService.toggleRead(item.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                      ],
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

  void _showAlertDetailsSheet(BuildContext context, AlertItem item) {
    final isEmergency = item.isEmergency;
    final color = isEmergency ? AppTheme.darkRed : (item.type == 'CAUTION' ? AppTheme.amber : AppTheme.primaryBlue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              children: [
                StatusPillBadge(status: item.status, customLabel: item.type),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMid),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMid),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textLow),
                const SizedBox(width: 4),
                Text(
                  item.relativeTime,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operational Situation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh)),
                      Text(item.source, style: const TextStyle(fontSize: 10, color: AppTheme.textLow)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.desc, style: const TextStyle(fontSize: 13, color: AppTheme.textMid, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.container,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Recommended Action', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow)),
                        SizedBox(height: 2),
                        Text('Divert via NH-37 Corridor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.container,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Freight Impact', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textLow)),
                        SizedBox(height: 2),
                        Text('> 16T Trucks Restricted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      alertService.dismissAlert(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert dismissed')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMid,
                      side: const BorderSide(color: AppTheme.borderMed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Dismiss Alert', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      alertService.markAsRead(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Acknowledged: ${item.title}'),
                          backgroundColor: AppTheme.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Acknowledge', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 56, color: AppTheme.borderMed),
          const SizedBox(height: 12),
          Text(
            'All Clear',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.borderMed,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No active alerts matching this filter',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLow,
            ),
          ),
        ],
      ),
    );
  }
}

