import 'package:flutter/foundation.dart';
import 'alert_service.dart';
import 'offline_storage_service.dart';
import '../widgets/status_pill_badge.dart';

class ReportItem {
  final String id;
  final String corridor;
  final String km;
  final String hazardType; // Landslide, Flash Flood, Subsidence, Fallen Tree, Debris, Bridge Strain, Other
  final String severity; // FULL BLOCKAGE, PARTIAL, SHOULDER
  final String location;
  final DateTime timestamp;
  String status; // PENDING, VERIFIED, DISPATCHED, REJECTED, RESOLVED
  final String notes;
  final String? photoPath;
  final String workerName;
  final String workerInitials;
  final String workerUnit;
  final String coordinates;
  String? dispatchUnit;
  String? dispatchNotes;
  final bool isMine;
  bool isOfflineQueued;
  String syncStatus; // 'SYNCED', 'PENDING_SYNC', 'SYNCING'

  ReportItem({
    required this.id,
    this.corridor = 'NH-06',
    this.km = 'KM 52.3',
    required this.hazardType,
    required this.severity,
    String? location,
    required this.timestamp,
    required this.status,
    String? notes,
    String? description,
    this.photoPath,
    required this.workerName,
    String? workerInitials,
    this.workerUnit = 'Field Unit 4',
    this.coordinates = '26.0124° N, 91.8901° E',
    this.dispatchUnit,
    this.dispatchNotes,
    this.isMine = false,
    this.isOfflineQueued = false,
    this.syncStatus = 'SYNCED',
  })  : location = location ?? '$corridor $km · $coordinates',
        notes = notes ?? description ?? 'Field observation recorded with camera evidence snapshot.',
        workerInitials = workerInitials ?? (workerName.trim().isNotEmpty ? workerName.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase() : 'FW');

  // Bidirectional aliases
  String get description => notes;
  String get submitted => relativeTime;

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class ReportService extends ChangeNotifier {
  final List<ReportItem> _reports = [];

  ReportService() {
    _seedInitialReports();
  }

  List<ReportItem> get reports => List.unmodifiable(_reports);

  List<ReportItem> get myReports => List.unmodifiable(_reports.where((r) => r.isMine));

  int get pendingCount => _reports.where((r) => r.status == 'PENDING').length;
  int get verifiedCount => _reports.where((r) => r.status == 'VERIFIED').length;
  int get dispatchedCount => _reports.where((r) => r.status == 'DISPATCHED').length;
  int get rejectedCount => _reports.where((r) => r.status == 'REJECTED').length;

  void _seedInitialReports() {
    final now = DateTime.now();
    _reports.addAll([
      ReportItem(
        id: 'RP-2847',
        corridor: 'NH-06',
        km: 'KM 52.3',
        hazardType: 'Landslide',
        severity: 'FULL BLOCKAGE',
        location: 'NH-06 KM 52.3 · 26.0124° N, 91.8901° E',
        coordinates: '26.0124° N, 91.8901° E',
        timestamp: now.subtract(const Duration(minutes: 6)),
        status: 'PENDING',
        notes: 'Large boulder roll-down on left shoulder. One lane blocked, second lane at risk of secondary debris flow. Immediate earth-mover intervention requested.',
        workerName: 'Sanjay Kumar',
        workerInitials: 'SK',
        workerUnit: 'Field Unit 4',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2846',
        corridor: 'NH-29',
        km: 'KM 81.1',
        hazardType: 'Flash Flood',
        severity: 'PARTIAL',
        location: 'NH-29 KM 81.1 · 25.6812° N, 93.7145° E',
        coordinates: '25.6812° N, 93.7145° E',
        timestamp: now.subtract(const Duration(minutes: 18)),
        status: 'VERIFIED',
        notes: 'Mountain stream overflow depositing gravel across 40 meters of roadway. Water depth approximately 20cm. Light vehicles diverted.',
        workerName: 'Priya Mao',
        workerInitials: 'PM',
        workerUnit: 'Field Unit 2',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2845',
        corridor: 'NH-37',
        km: 'KM 124.0',
        hazardType: 'Debris',
        severity: 'SHOULDER',
        location: 'NH-37 KM 124.0 · 26.5410° N, 93.1892° E',
        coordinates: '26.5410° N, 93.1892° E',
        timestamp: now.subtract(const Duration(minutes: 42)),
        status: 'DISPATCHED',
        notes: 'Uprooted tree branches partially encroaching eastbound emergency shoulder. Clearance squad en route.',
        workerName: 'Ratan Das',
        workerInitials: 'RD',
        workerUnit: 'Logistics Patrol 1',
        dispatchUnit: 'BRO Rapid Clearance #1',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2844',
        corridor: 'NH-40',
        km: 'KM 14.8',
        hazardType: 'Subsidence',
        severity: 'PARTIAL',
        location: 'NH-40 KM 14.8 · 25.5780° N, 91.8821° E',
        coordinates: '25.5780° N, 91.8821° E',
        timestamp: now.subtract(const Duration(hours: 1)),
        status: 'VERIFIED',
        notes: 'Bitumen cracking along outer mountain edge due to continuous saturation. Heavy vehicle weight restriction implemented.',
        workerName: 'Arunav Sharma',
        workerInitials: 'AS',
        workerUnit: 'Field Unit 3',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2843',
        corridor: 'NH-102',
        km: 'KM 68.2',
        hazardType: 'Landslide',
        severity: 'FULL BLOCKAGE',
        location: 'NH-102 KM 68.2 · 24.4120° N, 94.0210° E',
        coordinates: '24.4120° N, 94.0210° E',
        timestamp: now.subtract(const Duration(hours: 2)),
        status: 'DISPATCHED',
        notes: 'Mudslide covering entire two-lane stretch near Lokchao bridge. Road clearing heavy excavator requested.',
        workerName: 'Thangjam Singh',
        workerInitials: 'TS',
        workerUnit: 'Quick Response Unit 5',
        dispatchUnit: 'NDRF Rescue Unit 9',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2842',
        corridor: 'NH-06',
        km: 'KM 110.5',
        hazardType: 'Bridge Strain',
        severity: 'SHOULDER',
        location: 'NH-06 KM 110.5 · 25.2104° N, 92.3411° E',
        coordinates: '25.2104° N, 92.3411° E',
        timestamp: now.subtract(const Duration(hours: 4)),
        status: 'REJECTED',
        notes: 'Reported acoustic vibration on pier 3 during heavy truck crossing. PWD engineer reinspected: normal structural flex.',
        workerName: 'L. Dkhar',
        workerInitials: 'LD',
        workerUnit: 'Patrol Unit 7',
        isMine: false,
      ),
    ]);
  }

  void verifyReport(String id) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'VERIFIED';
      notifyListeners();
    }
  }

  void dispatchUnitToReport(String id, String unit, {String? notes}) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'DISPATCHED';
      _reports[index].dispatchUnit = unit;
      _reports[index].dispatchNotes = notes;
      notifyListeners();
    }
  }

  void rejectReport(String id, {String? reason}) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'REJECTED';
      _reports[index].dispatchNotes = reason;
      notifyListeners();
    }
  }

  /// Remove/delete a wrong, duplicate, or outdated field incident report
  void deleteReport(String id) {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  int get offlinePendingCount => _reports.where((r) => r.isOfflineQueued && r.syncStatus == 'PENDING_SYNC').length;

  /// Synchronize all locally queued offline reports to the remote database
  Future<int> syncAllPending() async {
    final synced = await offlineStorageService.syncPendingData();
    for (final r in _reports) {
      if (r.isOfflineQueued && r.syncStatus == 'PENDING_SYNC') {
        r.syncStatus = 'SYNCED';
      }
    }
    notifyListeners();
    return synced;
  }

  /// Add a newly submitted hazard report from camera/field sheet
  ReportItem addReport({
    required String hazardType,
    required String severity,
    required String location,
    String corridor = 'NH-06',
    String km = 'KM 52.3',
    required String notes,
    String? photoPath,
    String workerName = 'Current User',
    String workerUnit = 'Field Unit 4',
    bool isOffline = false,
  }) {
    final offlineActive = isOffline || !offlineStorageService.isOnline;
    final newReport = ReportItem(
      id: 'RP-${DateTime.now().millisecondsSinceEpoch % 10000}',
      corridor: corridor,
      km: km,
      hazardType: hazardType,
      severity: severity,
      location: location,
      timestamp: DateTime.now(),
      status: 'PENDING',
      notes: notes.isNotEmpty ? notes : 'Field observation recorded with camera evidence snapshot.',
      photoPath: photoPath,
      workerName: workerName,
      workerUnit: workerUnit,
      isMine: true,
      isOfflineQueued: offlineActive,
      syncStatus: offlineActive ? 'PENDING_SYNC' : 'SYNCED',
    );

    _reports.insert(0, newReport);

    if (offlineActive) {
      offlineStorageService.queueReportOffline(QueuedReportData(
        id: newReport.id,
        corridor: corridor,
        km: km,
        hazardType: hazardType,
        severity: severity,
        location: location,
        latitude: 26.0124,
        longitude: 91.8901,
        notes: newReport.notes,
        photoPath: photoPath,
        workerName: workerName,
        workerUnit: workerUnit,
        capturedAt: newReport.timestamp,
        isSynced: false,
      ));
    }

    // Automatically synchronize a corresponding alert into AlertService
    final isCritical = severity.toUpperCase().contains('FULL');
    alertService.addAlert(
      severity: isCritical ? 'EMERGENCY' : 'CAUTION',
      corridor: corridor,
      kmRange: km,
      category: 'HAZARD',
      location: location,
      title: '$hazardType — $severity',
      desc: newReport.notes,
      status: isCritical ? BadgeStatusType.blocked : BadgeStatusType.caution,
      isEmergency: isCritical,
      source: 'Field Incident Report ($workerName)${offlineActive ? ' [OFFLINE QUEUED]' : ''}',
    );

    notifyListeners();
    return newReport;
  }

  /// Reset to initial state (for testing)
  void reset() {
    _reports.clear();
    _seedInitialReports();
    notifyListeners();
  }
}

/// Global ReportService singleton
final reportService = ReportService();
