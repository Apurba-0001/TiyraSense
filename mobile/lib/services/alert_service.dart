import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/status_pill_badge.dart';
import './api_service.dart';
import './notification_service.dart';

class AlertItem {
  final String id;
  final String severity; // EMERGENCY, HIGH RISK, CAUTION, INFO
  final String corridor; // NH-06, NH-29, NH-37, etc.
  final String kmRange; // KM 52-54, etc.
  final String category; // CORRIDOR, WEATHER, EMERGENCY, HAZARD, NEWS
  final String location;
  final DateTime timestamp;
  final String title;
  final String desc;
  final BadgeStatusType status;
  final bool isEmergency;
  bool isRead;
  final String? resolvedBy;
  final String? resolvedAt;
  final String source;

  AlertItem({
    required this.id,
    String? type,
    String? severity,
    this.corridor = 'NH-06',
    this.kmRange = 'Active Corridor',
    required this.category,
    required this.location,
    required this.timestamp,
    required this.title,
    required this.desc,
    required this.status,
    required this.isEmergency,
    this.isRead = false,
    this.resolvedBy,
    this.resolvedAt,
    this.source = 'ASDMA Operational Feed',
  }) : severity = severity ?? type ?? 'INFO';

  // Bi-directional compatibility getters & setters
  String get type => severity;
  String get description => desc;
  String get affects => location;
  bool get acknowledged => isRead;
  set acknowledged(bool val) => isRead = val;

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity,
        'corridor': corridor,
        'kmRange': kmRange,
        'category': category,
        'location': location,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'desc': desc,
        'status': status.name,
        'isEmergency': isEmergency,
        'isRead': isRead,
        'resolvedBy': resolvedBy,
        'resolvedAt': resolvedAt,
        'source': source,
      };

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'passable';
    BadgeStatusType parsedStatus = BadgeStatusType.passable;
    if (statusStr.contains('blocked') || statusStr.contains('impassable')) {
      parsedStatus = BadgeStatusType.blocked;
    } else if (statusStr.contains('highrisk') || statusStr.contains('danger')) {
      parsedStatus = BadgeStatusType.highRisk;
    } else if (statusStr.contains('caution')) {
      parsedStatus = BadgeStatusType.caution;
    } else if (statusStr.contains('restricted')) {
      parsedStatus = BadgeStatusType.restricted;
    }

    return AlertItem(
      id: json['id']?.toString() ?? 'ALT-${DateTime.now().millisecondsSinceEpoch}',
      severity: json['severity']?.toString() ?? 'INFO',
      corridor: json['corridor']?.toString() ?? 'NH-06',
      kmRange: json['kmRange']?.toString() ?? 'Active Corridor',
      category: json['category']?.toString() ?? 'CORRIDOR',
      location: json['location']?.toString() ?? 'NER Corridor',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      title: json['title']?.toString() ?? 'Advisory',
      desc: json['desc']?.toString() ?? '',
      status: parsedStatus,
      isEmergency: json['isEmergency'] == true,
      isRead: json['isRead'] == true,
      resolvedBy: json['resolvedBy']?.toString(),
      resolvedAt: json['resolvedAt']?.toString(),
      source: json['source']?.toString() ?? 'ASDMA Operational Feed',
    );
  }
}

class AlertService extends ChangeNotifier {
  final List<AlertItem> _alerts = [];
  final Set<String> _deletedAlertIds = {};
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyStoredAlerts = 'tiyrasense_stored_alerts_v2';
  static const String _keyDeletedIds = 'tiyrasense_deleted_alert_ids_v2';

  AlertService() {
    _seedInitialAlerts();
    _initLocalStorage();
  }

  List<AlertItem> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  int get emergencyCount => _alerts.where((a) => a.severity == 'EMERGENCY' || a.isEmergency).length;

  int get highRiskCount => _alerts.where((a) => a.severity == 'HIGH RISK').length;

  int get cautionCount => _alerts.where((a) => a.severity == 'CAUTION').length;

  int get infoCount => _alerts.where((a) => a.severity == 'INFO').length;

  Future<void> _initLocalStorage() async {
    try {
      final deletedRaw = await _storage.read(key: _keyDeletedIds);
      if (deletedRaw != null && deletedRaw.isNotEmpty) {
        final list = jsonDecode(deletedRaw) as List<dynamic>;
        _deletedAlertIds.addAll(list.map((e) => e.toString()));
      }

      final storedRaw = await _storage.read(key: _keyStoredAlerts);
      if (storedRaw != null && storedRaw.isNotEmpty) {
        final list = jsonDecode(storedRaw) as List<dynamic>;
        if (list.isNotEmpty) {
          _alerts.clear();
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final alert = AlertItem.fromJson(item);
              if (!_deletedAlertIds.contains(alert.id)) {
                _alerts.add(alert);
              }
            }
          }
        }
      } else {
        await _persistAlerts();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistAlerts() async {
    try {
      final jsonStr = jsonEncode(_alerts.map((a) => a.toJson()).toList());
      await _storage.write(key: _keyStoredAlerts, value: jsonStr);
    } catch (_) {}
  }

  Future<void> _persistDeletedIds() async {
    try {
      final jsonStr = jsonEncode(_deletedAlertIds.toList());
      await _storage.write(key: _keyDeletedIds, value: jsonStr);
    } catch (_) {}
  }

  void _seedInitialAlerts() {
    final now = DateTime.now();
    _alerts.addAll([
      AlertItem(
        id: 'ALT-301',
        severity: 'EMERGENCY',
        corridor: 'NH-06',
        kmRange: 'KM 52-54',
        category: 'EMERGENCY',
        location: 'NH-06 KM 52-54 (Ri-Bhoi)',
        timestamp: now.subtract(const Duration(minutes: 5)),
        title: 'Active Landslide & Road Blockage',
        desc: 'Major slope failure triggered by overnight precipitation at KM 52.3 near Nongpoh cutting. Both carriageways obstructed by rockfall.',
        status: BadgeStatusType.blocked,
        isEmergency: true,
        isRead: false,
        source: 'BRO Field Reconnaissance',
      ),
      AlertItem(
        id: 'ALT-302',
        severity: 'CAUTION',
        corridor: 'NH-29',
        kmRange: 'KM 81-86',
        category: 'WEATHER',
        location: 'NH-29 KM 81-86 (Barail foothills)',
        timestamp: now.subtract(const Duration(minutes: 19)),
        title: 'Flash Flood Runoff on Pavement',
        desc: 'Mountain stream overflow between KM 81-86 depositing silt and standing water (approx. 20cm). Single lane alternating escort enforced.',
        status: BadgeStatusType.caution,
        isEmergency: false,
        isRead: false,
        source: 'IMD Weather Radar',
      ),
      AlertItem(
        id: 'ALT-303',
        severity: 'CAUTION',
        corridor: 'NH-37',
        kmRange: 'KM 115-130',
        category: 'WEATHER',
        location: 'NH-37 KM 115-130 (Bokakhat)',
        timestamp: now.subtract(const Duration(minutes: 42)),
        title: 'Heavy Rainfall Speed Restriction',
        desc: 'IMD sensor forecast indicates 45mm/h storm over southern floodplains. Safe speed advisory capped at 30 km/h.',
        status: BadgeStatusType.caution,
        isEmergency: false,
        isRead: false,
        source: 'IMD Sensor Network',
      ),
      AlertItem(
        id: 'ALT-304',
        severity: 'INFO',
        corridor: 'NH-51',
        kmRange: 'KM 10-60',
        category: 'CORRIDOR',
        location: 'NH-51 All Sectors',
        timestamp: now.subtract(const Duration(hours: 1)),
        title: 'Scheduled Convoy Transit Clearance',
        desc: 'State emergency fuel tankers received passage clearance through Garo Hills corridor without delay.',
        status: BadgeStatusType.passable,
        isEmergency: false,
        isRead: false,
        source: 'Highway Patrol Command',
      ),
      AlertItem(
        id: 'ALT-305',
        severity: 'CAUTION',
        corridor: 'NH-40',
        kmRange: 'KM 22-26',
        category: 'CORRIDOR',
        location: 'NH-40 KM 22-26 (Jowai)',
        timestamp: now.subtract(const Duration(hours: 3)),
        title: 'Culvert Repair Single-Lane Passage',
        desc: 'Drainage repair work completed on northern culvert wing. Speed restored to normal operational limits.',
        status: BadgeStatusType.caution,
        isEmergency: false,
        isRead: true,
        resolvedBy: 'Official R. Agarwal',
        resolvedAt: '14:22',
        source: 'PWD Roads Division',
      ),
      AlertItem(
        id: 'ALT-306',
        severity: 'INFO',
        corridor: 'NH-208',
        kmRange: 'KM 05-18',
        category: 'WEATHER',
        location: 'NH-208 Valley Sector',
        timestamp: now.subtract(const Duration(hours: 5)),
        title: 'Dense Fog Morning Advisory Cleared',
        desc: 'Valley mist lifted across Kumarghat link. Normal daytime visibility restored.',
        status: BadgeStatusType.passable,
        isEmergency: false,
        isRead: true,
        resolvedBy: 'Admin Team',
        resolvedAt: '11:05',
        source: 'Traffic Command Center',
      ),
    ]);
  }

  /// Mark all alerts as read / acknowledged and persist to local storage
  void markAllRead() {
    for (final alert in _alerts) {
      alert.isRead = true;
    }
    _persistAlerts();
    notifyListeners();
  }

  void acknowledgeAllAlerts() => markAllRead();

  /// Mark seen messages as read and save to local storage
  void markSeenAsRead() {
    bool hasChanges = false;
    for (final alert in _alerts) {
      if (!alert.isRead) {
        alert.isRead = true;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _persistAlerts();
      notifyListeners();
    }
  }

  /// Mark a single alert as read and persist to local storage
  void markAsRead(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1 && !_alerts[index].isRead) {
      _alerts[index].isRead = true;
      _persistAlerts();
      notifyListeners();
    }
  }

  void acknowledgeAlert(String id) => markAsRead(id);

  /// Toggle read/unread state of an alert and persist to local storage
  void toggleRead(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alerts[index].isRead = !_alerts[index].isRead;
      _persistAlerts();
      notifyListeners();
    }
  }

  /// Dismiss / remove an alert and persist removal so it remains deleted
  void dismissAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _deletedAlertIds.add(id);
    _persistAlerts();
    _persistDeletedIds();
    notifyListeners();
  }

  /// Add a dynamic alert and persist to local storage
  void addAlert({
    String? type,
    String? severity,
    String corridor = 'NH-06',
    String kmRange = 'Active Sector',
    required String category,
    required String location,
    required String title,
    required String desc,
    required BadgeStatusType status,
    required bool isEmergency,
    String source = 'Field Incident Report',
    bool pushNotification = false,
  }) {
    final newAlert = AlertItem(
      id: 'ALT-${DateTime.now().millisecondsSinceEpoch % 10000}',
      severity: severity ?? type ?? 'INFO',
      corridor: corridor,
      kmRange: kmRange,
      category: category,
      location: location,
      timestamp: DateTime.now(),
      title: title,
      desc: desc,
      status: status,
      isEmergency: isEmergency,
      isRead: false,
      source: source,
    );
    _alerts.insert(0, newAlert);
    _persistAlerts();

    // Push notifications only for genuine broadcasts or critical road events
    if (pushNotification) {
      if (isEmergency || category.toUpperCase() == 'HAZARD' || category.toUpperCase() == 'EMERGENCY') {
        NotificationService().showHazardAlert(
          title: '🚨 $title',
          body: '$desc ($location)',
          payload: newAlert.id,
        );
      } else {
        NotificationService().showGeneralNotification(
          title: category.toUpperCase() == 'NEWS' ? '📰 $title' : '📢 $title',
          body: '$desc ($location)',
          payload: newAlert.id,
        );
      }
    }

    notifyListeners();
  }

  /// Broadcast an official advisory or news bulletin
  void broadcastNewsAlert({
    required String headline,
    required String summary,
    required String location,
    String source = 'ASDMA Official Bulletin',
    bool isEmergency = false,
  }) {
    addAlert(
      type: isEmergency ? 'EMERGENCY' : 'INFO',
      category: 'NEWS',
      location: location,
      title: headline,
      desc: summary,
      status: isEmergency ? BadgeStatusType.blocked : BadgeStatusType.caution,
      isEmergency: isEmergency,
      source: source,
      pushNotification: true,
    );
  }

  /// Sync live alerts from Supabase Cloud DB and FastAPI Backend API.
  /// Merges alerts into local storage without overwriting the user's read state,
  /// respects deleted alert IDs, and only dispatches notifications for genuine new reports from the backend/dashboard.
  Future<void> syncLiveAlerts() async {
    try {
      final api = ApiService();
      final directAlerts = await api.fetchAlertsDirect(limit: 50);
      final backendAlerts = await api.fetchAlertsFromBackend(limit: 50);

      final List<Map<String, dynamic>> combined = [];
      combined.addAll(directAlerts);
      for (final b in backendAlerts) {
        final bId = b['id']?.toString();
        if (bId != null && !combined.any((d) => d['id']?.toString() == bId)) {
          combined.add(b);
        }
      }

      if (combined.isEmpty) return;

      bool hasChanges = false;
      for (final item in combined) {
        final alertId = item['id']?.toString() ?? '';
        if (alertId.isEmpty || _deletedAlertIds.contains(alertId)) {
          continue; // User dismissed this alert or it has invalid ID
        }

        final existingIdx = _alerts.indexWhere((a) => a.id == alertId);
        if (existingIdx != -1) {
          // Already in local storage: preserve local isRead status!
          continue;
        }

        // Genuinely brand-new alert arriving from the backend or official dashboard!
        final sev = (item['severity'] ?? 'CAUTION').toString().toUpperCase();
        final isEmerg = sev == 'EMERGENCY' || sev == 'CRITICAL';
        final title = item['title']?.toString() ?? 'Corridor Advisory';
        final desc = item['message_en']?.toString() ??
            item['description']?.toString() ??
            item['title']?.toString() ??
            '';
        final corridor = item['corridor']?.toString() ?? 'NH-06';
        final location = item['location']?.toString() ?? '$corridor Sector';

        final newAlert = AlertItem(
          id: alertId,
          severity: isEmerg
              ? 'EMERGENCY'
              : (sev == 'HIGH'
                  ? 'HIGH RISK'
                  : (sev == 'MEDIUM' ? 'CAUTION' : 'INFO')),
          corridor: corridor,
          kmRange: item['km_range']?.toString() ?? 'Active Sector',
          category: isEmerg ? 'EMERGENCY' : 'HAZARD',
          location: location,
          timestamp: item['dispatched_at'] != null
              ? DateTime.tryParse(item['dispatched_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
          title: title,
          desc: desc,
          status: isEmerg ? BadgeStatusType.blocked : BadgeStatusType.caution,
          isEmergency: isEmerg,
          isRead: false,
          source: item['source']?.toString() ?? 'Official Command Feed',
        );

        _alerts.insert(0, newAlert);
        hasChanges = true;

        // Dispatch notification ONLY for actual new incoming reports from the backend or dashboard
        if (isEmerg) {
          NotificationService().showHazardAlert(
            title: '🚨 $title',
            body: '$desc ($location)',
            payload: newAlert.id,
          );
        } else {
          NotificationService().showGeneralNotification(
            title: '📢 $title',
            body: '$desc ($location)',
            payload: newAlert.id,
          );
        }
      }

      if (hasChanges) {
        await _persistAlerts();
        notifyListeners();
      }
    } catch (_) {
      // Offline: stored local alerts remain fully intact
    }
  }

  /// Reset alerts to clean seeded state and wipe local storage (useful for tests)
  void reset() {
    _alerts.clear();
    _deletedAlertIds.clear();
    _seedInitialAlerts();
    _persistAlerts();
    _persistDeletedIds();
    notifyListeners();
  }
}

/// Global AlertService singleton
final alertService = AlertService();
