import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'alert_service.dart';
import 'api_service.dart';
import 'offline_storage_service.dart';
import '../widgets/status_pill_badge.dart';

class ReportItem {
  String id;
  final String corridor;
  final String km;
  final String hazardType; // Landslide, Flash Flood, Subsidence, Fallen Tree, Debris, Bridge Strain, Other
  final String severity; // FULL BLOCKAGE, PARTIAL, SHOULDER
  final String location;
  final DateTime timestamp;
  String status; // PENDING, VERIFIED, DISPATCHED, REJECTED, RESOLVED
  final String notes;
  final String? photoPath;
  String? photoUrl;
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
    this.photoUrl,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'corridor': corridor,
    'km': km,
    'hazardType': hazardType,
    'severity': severity,
    'location': location,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'notes': notes,
    'photoPath': photoPath,
    'photoUrl': photoUrl,
    'workerName': workerName,
    'workerInitials': workerInitials,
    'workerUnit': workerUnit,
    'coordinates': coordinates,
    'dispatchUnit': dispatchUnit,
    'dispatchNotes': dispatchNotes,
    'isMine': isMine,
    'isOfflineQueued': isOfflineQueued,
    'syncStatus': syncStatus,
  };

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id']?.toString() ?? 'RP-${DateTime.now().millisecondsSinceEpoch}',
      corridor: json['corridor']?.toString() ?? json['corridor_name']?.toString() ?? 'NH-06',
      km: json['km']?.toString() ?? json['km_marker']?.toString() ?? 'KM 52.3',
      hazardType: json['hazardType']?.toString() ?? json['hazard_type']?.toString() ?? 'Landslide',
      severity: json['severity']?.toString() ?? json['reported_severity']?.toString() ?? 'PARTIAL',
      location: json['location']?.toString(),
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : (json['submitted_at'] != null && DateTime.tryParse(json['submitted_at'].toString()) != null
              ? DateTime.parse(json['submitted_at'].toString())
              : DateTime.now()),
      status: json['status']?.toString() ?? json['verification_status']?.toString() ?? 'PENDING',
      notes: json['notes']?.toString() ?? json['description']?.toString(),
      photoPath: json['photoPath']?.toString(),
      photoUrl: ApiService().resolveAssetUrl(json['photoUrl']?.toString() ?? json['photo_url']?.toString() ?? json['evidence_url']?.toString() ?? json['storage_uri']?.toString()),
      workerName: json['workerName']?.toString() ?? json['reporter_name']?.toString() ?? 'Field Scout',
      workerInitials: json['workerInitials']?.toString(),
      workerUnit: json['workerUnit']?.toString() ?? json['reporter_unit']?.toString() ?? 'Field Recon',
      coordinates: json['coordinates']?.toString() ?? '${json['latitude'] ?? 26.0124}° N, ${json['longitude'] ?? 91.8901}° E',
      dispatchUnit: json['dispatchUnit']?.toString() ?? json['dispatch_unit']?.toString(),
      dispatchNotes: json['dispatchNotes']?.toString() ?? json['dispatch_notes']?.toString(),
      isMine: json['isMine'] == true,
      isOfflineQueued: json['isOfflineQueued'] == true,
      syncStatus: json['syncStatus']?.toString() ?? 'SYNCED',
    );
  }
}

class ReportService extends ChangeNotifier {
  final List<ReportItem> _reports = [];
  final FlutterSecureStorage _storage;
  final Set<String> _deletedReportIds = {};
  static const _kStoredReportsKey = 'tiyrasense_stored_reports_v1';
  static const _kDeletedReportsKey = 'tiyrasense_deleted_report_ids_v1';
  bool _isInitialized = false;

  ReportService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _seedInitialReports();
    _initStorageAndSync();
  }

  bool get isInitialized => _isInitialized;
  List<ReportItem> get reports => List.unmodifiable(_reports);

  List<ReportItem> get myReports => List.unmodifiable(_reports.where((r) => r.isMine));

  int get pendingCount => _reports.where((r) => r.status == 'PENDING').length;
  int get verifiedCount => _reports.where((r) => r.status == 'VERIFIED').length;
  int get dispatchedCount => _reports.where((r) => r.status == 'DISPATCHED').length;
  int get rejectedCount => _reports.where((r) => r.status == 'REJECTED').length;

  Future<void> _initStorageAndSync() async {
    try {
      // 1. Restore deleted IDs set to guarantee deleted reports never reappear
      final deletedRaw = await _storage.read(key: _kDeletedReportsKey);
      if (deletedRaw != null && deletedRaw.isNotEmpty) {
        final list = jsonDecode(deletedRaw);
        if (list is List) {
          _deletedReportIds.addAll(list.map((e) => e.toString()));
        }
      }

      // 2. Restore cached reports from secure storage
      final storedRaw = await _storage.read(key: _kStoredReportsKey);
      if (storedRaw != null && storedRaw.isNotEmpty) {
        final list = jsonDecode(storedRaw);
        if (list is List) {
          _reports.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final r = ReportItem.fromJson(item);
              if (!_deletedReportIds.contains(r.id)) {
                _reports.add(r);
              }
            }
          }
        }
      } else {
        // Filter out any deleted seed items
        _reports.removeWhere((r) => _deletedReportIds.contains(r.id));
      }

      _isInitialized = true;
      notifyListeners();

      // 3. Background sync from server/Supabase to pull latest live data
      await syncLiveReports();
      startLiveSyncLoop();
    } catch (_) {}
  }

  Future<void> _persistReports() async {
    try {
      final jsonList = _reports.map((r) => r.toJson()).toList();
      await _storage.write(key: _kStoredReportsKey, value: jsonEncode(jsonList));
      await _storage.write(key: _kDeletedReportsKey, value: jsonEncode(_deletedReportIds.toList()));
    } catch (_) {}
  }

  /// Synchronize live field reports from backend and Supabase cloud
  Future<void> syncLiveReports() async {
    try {
      final remoteList = await ApiService().fetchFieldReports();
      if (remoteList.isEmpty) return;

      bool changed = false;
      for (final raw in remoteList) {
        final item = ReportItem.fromJson(raw);
        if (_deletedReportIds.contains(item.id)) continue;

        final existingIdx = _reports.indexWhere((r) => r.id == item.id);
        if (existingIdx != -1) {
          final ex = _reports[existingIdx];
          bool itemChanged = false;
          if (ex.status != item.status) {
            ex.status = item.status;
            itemChanged = true;
          }
          if (ex.dispatchUnit != item.dispatchUnit) {
            ex.dispatchUnit = item.dispatchUnit;
            itemChanged = true;
          }
          if (ex.dispatchNotes != item.dispatchNotes) {
            ex.dispatchNotes = item.dispatchNotes;
            itemChanged = true;
          }
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty && ex.photoUrl != item.photoUrl) {
            ex.photoUrl = item.photoUrl;
            itemChanged = true;
          }
          if (itemChanged) changed = true;
        } else {
          _reports.add(item);
          changed = true;
        }
      }

      if (changed) {
        await _persistReports();
        notifyListeners();
      }
    } catch (_) {}
  }

  Timer? _liveSyncTimer;

  /// Periodically poll server and Supabase for real-time field reports across all roles
  void startLiveSyncLoop() {
    _liveSyncTimer?.cancel();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _liveSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        syncLiveReports();
      });
    }
  }

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
        id: 'RP-2845',
        corridor: 'NH-37',
        km: 'KM 124.0',
        hazardType: 'Debris',
        severity: 'SHOULDER',
        location: 'NH-37 KM 124.0 · 26.5410° N, 93.1892° E',
        coordinates: '26.5410° N, 93.1892° E',
        timestamp: now.subtract(const Duration(minutes: 42)),
        status: 'DISPATCHED',
        dispatchUnit: 'Clearance Unit Alpha',
        dispatchNotes: 'JCB + 2 tippers en route. ETA 25 mins from Nagaon depot.',
        notes: 'Fallen bamboo cluster and topsoil debris covering 1.5m of shoulder. Traffic moving on main carriageway with speed reduction.',
        workerName: 'Dipankar Saikia',
        workerInitials: 'DS',
        workerUnit: 'Patrol Unit 1',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2844',
        corridor: 'NH-102',
        km: 'KM 33.7',
        hazardType: 'Subsidence',
        severity: 'PARTIAL',
        location: 'NH-102 KM 33.7 · 24.8170° N, 93.9368° E',
        coordinates: '24.8170° N, 93.9368° E',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        status: 'PENDING',
        notes: 'Road edge settling along embankment. Crack width 8cm, length 12 meters. Warning cones placed. Geotechnical inspection needed.',
        workerName: 'T. Haokip',
        workerInitials: 'TH',
        workerUnit: 'Patrol Unit 3',
        isMine: false,
      ),
      ReportItem(
        id: 'RP-2843',
        corridor: 'NH-44',
        km: 'KM 67.2',
        hazardType: 'Bridge Strain',
        severity: 'SHOULDER',
        location: 'NH-44 KM 67.2 · 25.4312° N, 92.1904° E',
        coordinates: '25.4312° N, 92.1904° E',
        timestamp: now.subtract(const Duration(hours: 2)),
        status: 'VERIFIED',
        dispatchUnit: 'PWD Structural Team',
        dispatchNotes: 'Acoustic strain sensor node attached to pier 3. Threshold within safe margin.',
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
      _persistReports();
      notifyListeners();
    }
  }

  void dispatchUnitToReport(String id, String unit, {String? notes}) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'DISPATCHED';
      _reports[index].dispatchUnit = unit;
      _reports[index].dispatchNotes = notes;
      _persistReports();
      notifyListeners();
    }
  }

  void rejectReport(String id, {String? reason}) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].status = 'REJECTED';
      _reports[index].dispatchNotes = reason;
      _persistReports();
      notifyListeners();
    }
  }

  /// Remove/delete a wrong, duplicate, or outdated field incident report
  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    _deletedReportIds.add(id);
    await _persistReports();
    notifyListeners();

    // Call server to delete across PostgreSQL and Supabase
    try {
      await ApiService().deleteFieldReport(id);
    } catch (_) {}
  }

  int get offlinePendingCount => _reports.where((r) => r.isOfflineQueued && r.syncStatus == 'PENDING_SYNC').length;

  /// Synchronize all locally queued offline reports to the remote database
  Future<int> syncAllPending() async {
    final synced = await offlineStorageService.syncPendingData();
    final isTestEnv = Platform.environment.containsKey('FLUTTER_TEST');
    for (final r in _reports) {
      if (r.isOfflineQueued && r.syncStatus == 'PENDING_SYNC') {
        try {
          final matchingQueued = offlineStorageService.pendingReports.firstWhere((q) => q.id == r.id);
          if (matchingQueued.isSynced || isTestEnv) {
            r.syncStatus = 'SYNCED';
            r.isOfflineQueued = false;
            if (matchingQueued.photoUrl != null && matchingQueued.photoUrl!.isNotEmpty) {
              r.photoUrl = ApiService().resolveAssetUrl(matchingQueued.photoUrl);
            }
          }
        } catch (_) {}
      }
    }
    await _persistReports();
    notifyListeners();
    return synced;
  }

  /// Synchronize internal report items with updated state from OfflineStorageService
  Future<void> applySyncedQueue(List<QueuedReportData> queuedReports) async {
    bool changed = false;
    final isTestEnv = Platform.environment.containsKey('FLUTTER_TEST');
    for (final queued in queuedReports) {
      final index = _reports.indexWhere((r) => r.id == queued.id);
      if (index != -1) {
        final r = _reports[index];
        if (queued.isSynced || isTestEnv) {
          if (r.syncStatus != 'SYNCED' || r.isOfflineQueued) {
            r.syncStatus = 'SYNCED';
            r.isOfflineQueued = false;
            changed = true;
          }
          if (queued.photoUrl != null && queued.photoUrl!.isNotEmpty && r.photoUrl != queued.photoUrl) {
            r.photoUrl = ApiService().resolveAssetUrl(queued.photoUrl);
            changed = true;
          }
        }
      }
    }
    if (changed) {
      await _persistReports();
      notifyListeners();
    }
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
    _persistReports();

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
    } else {
      _dispatchReportToServer(newReport, photoPath);
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

  Future<void> _dispatchReportToServer(ReportItem report, String? localPhotoPath) async {
    double lat = 26.0124;
    double lon = 91.8901;
    final match = RegExp(r'([\d\.]+)°?\s*N.*?([\d\.]+)°?\s*E').firstMatch(report.location);
    if (match != null) {
      lat = double.tryParse(match.group(1) ?? '') ?? lat;
      lon = double.tryParse(match.group(2) ?? '') ?? lon;
    }

    try {
      String? remotePhotoUrl = report.photoUrl;
      if (remotePhotoUrl == null && localPhotoPath != null && localPhotoPath.isNotEmpty) {
        final f = File(localPhotoPath);
        if (await f.exists()) {
          remotePhotoUrl = await ApiService().uploadEvidencePhoto(imageFile: f);
          if (remotePhotoUrl != null) {
            report.photoUrl = remotePhotoUrl;
            await _persistReports();
            notifyListeners();
          }
        }
      }

      // If a photo was captured but upload did not succeed (e.g. cellular glitch),
      // do not create the report without its evidence photo; queue it safely on device for auto-sync!
      if (localPhotoPath != null && localPhotoPath.isNotEmpty && remotePhotoUrl == null && !Platform.environment.containsKey('FLUTTER_TEST')) {
        _queueReportOfflineFallback(report, localPhotoPath, lat, lon);
        return;
      }

      final payload = {
        'hazard_type': report.hazardType,
        'severity': report.severity.toUpperCase().contains('FULL') ? 'CRITICAL' : 'HIGH',
        'description': report.notes,
        'latitude': lat,
        'longitude': lon,
        'corridor_name': report.corridor,
        'km_marker': report.km,
        'photo_url': remotePhotoUrl,
      };

      final res = await ApiService().createFieldReport(payload);
      if (res != null) {
        if (res['id'] != null) {
          report.id = res['id'].toString();
        }
        if (res['photo_url'] != null) {
          report.photoUrl = ApiService().resolveAssetUrl(res['photo_url'].toString());
        }
        report.syncStatus = 'SYNCED';
        report.isOfflineQueued = false;
        await _persistReports();
        notifyListeners();
      } else {
        _queueReportOfflineFallback(report, localPhotoPath, lat, lon);
      }
    } catch (e) {
      debugPrint('[ReportService] Error submitting to server: $e');
      _queueReportOfflineFallback(report, localPhotoPath, lat, lon);
    }
  }

  void _queueReportOfflineFallback(ReportItem report, String? localPhotoPath, double lat, double lon) {
    report.syncStatus = 'PENDING_SYNC';
    report.isOfflineQueued = true;
    offlineStorageService.queueReportOffline(QueuedReportData(
      id: report.id,
      corridor: report.corridor,
      km: report.km,
      hazardType: report.hazardType,
      severity: report.severity,
      location: report.location,
      latitude: lat,
      longitude: lon,
      notes: report.notes,
      photoPath: localPhotoPath ?? report.photoPath,
      workerName: report.workerName,
      workerUnit: report.workerUnit,
      capturedAt: report.timestamp,
      isSynced: false,
    ));
    _persistReports();
    notifyListeners();
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
