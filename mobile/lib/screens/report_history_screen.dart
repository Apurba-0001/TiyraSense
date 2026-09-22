import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/offline_storage_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hazard_report_sheet.dart';

class ReportHistoryScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ReportHistoryScreen({super.key, this.onOpenDrawer});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  String _activeFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    reportService.addListener(_onReportsUpdated);
    offlineStorageService.addListener(_onReportsUpdated);
  }

  @override
  void dispose() {
    reportService.removeListener(_onReportsUpdated);
    offlineStorageService.removeListener(_onReportsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onReportsUpdated() {
    if (mounted) setState(() {});
  }

  void _showDispatchDialog(ReportItem item) {
    final unitCtrl = TextEditingController(text: 'BRO Rapid Clearance #1');
    final notesCtrl = TextEditingController(text: 'Assigned immediate corridor clearance and escort.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 8),
            Text('Dispatch Clearance Unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textHigh)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report: ${item.id} (${item.hazardType})', style: const TextStyle(fontSize: 12, color: AppTheme.textLow)),
            const SizedBox(height: 12),
            const Text('Dispatch Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
            const SizedBox(height: 4),
            TextField(
              controller: unitCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.container,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Dispatch Instructions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
            const SizedBox(height: 4),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.container,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textLow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              reportService.dispatchUnitToReport(item.id, unitCtrl.text.trim(), notes: notesCtrl.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispatched ${unitCtrl.text.trim()} to ${item.id}')),
              );
            },
            child: const Text('Dispatch Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allReports = reportService.reports;
    final myCount = reportService.myReports.length;

    List<ReportItem> filtered = allReports;
    if (_activeFilter == 'MY REPORTS') {
      filtered = allReports.where((r) => r.isMine).toList();
    } else if (_activeFilter == 'PENDING') {
      filtered = allReports.where((r) => r.status == 'PENDING').toList();
    } else if (_activeFilter == 'VERIFIED') {
      filtered = allReports.where((r) => r.status == 'VERIFIED').toList();
    } else if (_activeFilter == 'DISPATCHED') {
      filtered = allReports.where((r) => r.status == 'DISPATCHED').toList();
    } else if (_activeFilter == 'REJECTED') {
      filtered = allReports.where((r) => r.status == 'REJECTED').toList();
    } else if (_activeFilter != 'ALL') {
      filtered = allReports.where((r) => r.hazardType.toUpperCase() == _activeFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.id.toLowerCase().contains(q) ||
            r.corridor.toLowerCase().contains(q) ||
            r.hazardType.toLowerCase().contains(q) ||
            r.workerName.toLowerCase().contains(q) ||
            r.notes.toLowerCase().contains(q) ||
            r.coordinates.toLowerCase().contains(q);
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
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textHigh),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text(
          localizationService.tr('incident_report_history'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textHigh,
          ),
        ),
        actions: [
          if (offlineStorageService.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                ),
              ),
            )
          else if (offlineStorageService.pendingCount > 0 || reportService.offlinePendingCount > 0)
            IconButton(
              icon: Badge(
                label: Text('${offlineStorageService.pendingCount > 0 ? offlineStorageService.pendingCount : reportService.offlinePendingCount}'),
                backgroundColor: AppTheme.amber,
                child: const Icon(Icons.sync_rounded, color: AppTheme.amber, size: 22),
              ),
              tooltip: 'Sync Offline Reports',
              onPressed: () async {
                final count = await reportService.syncAllPending();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Synchronized $count reports to ASDMA Command Database.'),
                      backgroundColor: AppTheme.green,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 22),
            tooltip: 'New Hazard Report',
            onPressed: () => HazardReportSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HazardReportSheet.show(context),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
        label: Text(localizationService.tr('report_hazard_btn'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          if (offlineStorageService.isSyncing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Auto-syncing queued photos & reports to database in real time...',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
              ),
            )
          else if (offlineStorageService.pendingCount > 0 || reportService.offlinePendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.amber.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_queue_rounded, size: 16, color: AppTheme.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${offlineStorageService.pendingCount > 0 ? offlineStorageService.pendingCount : reportService.offlinePendingCount} report(s) queued offline. Will auto-sync when connected.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.amber),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => offlineStorageService.autoSync(),
                    child: const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.amber)),
                  ),
                ],
              ),
            ),
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
                        hintText: 'Search reports by corridor, hazard, or officer...',
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

          // KPI Metric Cards (Total, Pending, Verified, Dispatched)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _buildKpiCard(localizationService.tr('total_submissions'), '${allReports.length}', AppTheme.primaryBlue),
                const SizedBox(width: 8),
                _buildKpiCard(localizationService.tr('pending_review'), '${reportService.pendingCount}', AppTheme.amber),
                const SizedBox(width: 8),
                _buildKpiCard('VERIFIED', '${reportService.verifiedCount}', AppTheme.green),
                const SizedBox(width: 8),
                _buildKpiCard('DISPATCHED', '${reportService.dispatchedCount}', const Color(0xFFC2410C)),
              ],
            ),
          ),

          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', '${localizationService.tr('filter_all')} (${allReports.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PENDING', '${localizationService.tr('filter_pending')} (${reportService.pendingCount})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('VERIFIED', '${localizationService.tr('filter_verified')} (${reportService.verifiedCount})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('DISPATCHED', 'DISPATCHED (${reportService.dispatchedCount})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REJECTED', 'REJECTED (${reportService.rejectedCount})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('MY REPORTS', '${localizationService.tr('my_reports')} ($myCount)'),
                ],
              ),
            ),
          ),

          // Reports List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildReportCard(filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
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
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLow,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : AppTheme.surface,
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
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportItem item) {
    Color statusColor = AppTheme.amber;
    if (item.status == 'VERIFIED') statusColor = AppTheme.green;
    if (item.status == 'DISPATCHED') statusColor = const Color(0xFFC2410C);
    if (item.status == 'REJECTED') statusColor = AppTheme.darkRed;
    if (item.status == 'RESOLVED') statusColor = AppTheme.primaryBlue;

    final isSevere = item.severity.toUpperCase().contains('FULL');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.isMine ? AppTheme.primaryBlue.withValues(alpha: 0.4) : AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Officer Name/Unit, Status, Relative Time
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  child: Text(
                    item.workerInitials,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.workerName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                          ),
                          if (item.isMine) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.blueLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${item.workerUnit} · ${item.id}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textLow),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
                if (item.isOfflineQueued && item.syncStatus == 'PENDING_SYNC') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.amberBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 10, color: AppTheme.amber),
                        SizedBox(width: 3),
                        Text('OFFLINE QUEUE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.amber)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  item.relativeTime,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Corridor & KM tag with Hazard Type & Severity Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    '${item.corridor} ${item.km}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.hazardType,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSevere ? AppTheme.redBg : AppTheme.container,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSevere ? AppTheme.red.withValues(alpha: 0.4) : AppTheme.borderMed),
                  ),
                  child: Text(
                    item.severity,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSevere ? AppTheme.darkRed : AppTheme.textMid,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Location with pin icon
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMid),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // GPS Coordinates
            Row(
              children: [
                const Icon(Icons.my_location_rounded, size: 13, color: AppTheme.textLow),
                const SizedBox(width: 4),
                Text(
                  item.coordinates,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Photo Thumbnail (if photo attached locally or on remote CDN/database)
            if ((item.photoPath != null && item.photoPath!.isNotEmpty) ||
                (item.photoUrl != null && item.photoUrl!.isNotEmpty)) ...[
              GestureDetector(
                onTap: () => _showFullImageDialog(item.photoPath, item.photoUrl),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.canvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildThumbnail(item.photoPath, item.photoUrl),
                        Positioned(
                          bottom: 6,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('View Evidence Photo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Notes / Observations
            Text(
              item.notes,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMid, height: 1.3),
            ),
            if (item.dispatchUnit != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2410C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC2410C).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFFC2410C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Assigned: ${item.dispatchUnit}${item.dispatchNotes != null ? " · ${item.dispatchNotes}" : ""}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFC2410C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Action Buttons: Verify, Dispatch Unit
            Row(
              children: [
                if (item.status == 'PENDING') ...[
                  GestureDetector(
                    onTap: () {
                      reportService.verifyReport(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Verified ${item.id} — synced to command room')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.green),
                          SizedBox(width: 4),
                          Text('Verify', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.status != 'DISPATCHED' && item.status != 'REJECTED') ...[
                  GestureDetector(
                    onTap: () => _showDispatchDialog(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.send_rounded, size: 13, color: AppTheme.primaryBlue),
                          SizedBox(width: 4),
                          Text('Dispatch Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${item.corridor} Sector',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? localPath, String? remoteUrl) {
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildRemoteOrFallback(remoteUrl),
      );
    }
    return _buildRemoteOrFallback(remoteUrl);
  }

  Widget _buildRemoteOrFallback(String? remoteUrl) {
    final resolved = ApiService().resolveAssetUrl(remoteUrl);
    if (resolved != null && resolved.isNotEmpty) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.container,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.container,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: AppTheme.textLow),
          ),
        ),
      );
    }
    return Container(
      color: AppTheme.container,
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 6),
            Text('Field Photo Evidence Attached', style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showFullImageDialog(String? localPath, String? remoteUrl) {
    final resolved = ApiService().resolveAssetUrl(remoteUrl);
    Widget imageWidget;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      imageWidget = Image.file(File(localPath), fit: BoxFit.contain);
    } else if (resolved != null && resolved.isNotEmpty) {
      imageWidget = Image.network(
        resolved,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 250,
            color: AppTheme.surface,
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          color: AppTheme.surface,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, color: AppTheme.textLow, size: 36),
                SizedBox(height: 8),
                Text('Unable to load photo evidence.', style: TextStyle(color: AppTheme.textMid, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        height: 250,
        color: AppTheme.surface,
        child: const Center(
          child: Text('Image file saved on local device storage.', style: TextStyle(color: AppTheme.textMid)),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 60, color: AppTheme.borderMed),
            const SizedBox(height: 14),
            const Text(
              'No Reports Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
            ),
            const SizedBox(height: 6),
            const Text(
              'No incident reports match this filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textLow),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => HazardReportSheet.show(context),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Capture New Hazard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
