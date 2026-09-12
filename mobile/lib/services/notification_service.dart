import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// TiyraSense Push Notification Policy:
/// ONLY push notifications for critical, high-signal operational events:
/// 1. An alert is broadcasted (hazard report broadcasted, emergency alerts, road blockages).
/// 2. Specific news / weather bulletins are published by authorities (ASDMA/IMD advisories).
/// 3. Real-time safety events happen during transit (forward road hazard detected on corridor ahead).
///
/// DO NOT push notifications for:
/// - Routine user UI interactions (tapping route choice chips, switching tabs).
/// - Starting navigation (driver is actively interacting with the screen and sees the route guidance banner).
/// - Routine continuous telemetry pings or duplicate location updates.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Test / mock support
  static bool mockMode = false;
  static final List<Map<String, dynamic>> dispatchedNotifications = [];

  // Channel IDs
  static const String channelHazardAlerts = 'tiyrasense_hazard_alerts';
  static const String channelRouteUpdates = 'tiyrasense_route_updates';
  static const String channelGeneral = 'tiyrasense_general';
  static const String channelLiveNavigation = 'tiyrasense_live_navigation';

  /// Active ongoing live notification data (for lockscreen and status bar)
  static Map<String, dynamic>? activeLiveNotification;

  /// Initialize local notification system and channels
  Future<void> initialize() async {
    if (_isInitialized || mockMode) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Tapped notification: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        // Request runtime permission for Android 13+
        await androidPlatform.requestNotificationsPermission();

        // 1. Critical Hazard Alerts Channel
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelHazardAlerts,
            'Critical Hazard Alerts',
            description: 'Urgent alerts for landslides, roadblocks, and severe flash floods',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );

        // 2. Route & Corridor Updates Channel
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelRouteUpdates,
            'Route & Corridor Updates',
            description: 'Corridor risk level changes and automatic safer route recalculations',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // 3. General Notifications Channel
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelGeneral,
            'General Notifications',
            description: 'Incident report confirmations and telemetry status updates',
            importance: Importance.defaultImportance,
          ),
        );

        // 4. Live Navigation Channel (Ongoing status bar & lockscreen card)
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelLiveNavigation,
            'Live Navigation Guidance',
            description: 'Persistent turn-by-turn guidance on Android lock screen and shade',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
            showBadge: false,
          ),
        );
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (safe fallback): $e');
    }
  }

  /// Show a high-priority Heads-Up Hazard Alert
  Future<void> showHazardAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (mockMode) {
      dispatchedNotifications.add({
        'type': 'hazard',
        'title': title,
        'body': body,
        'payload': payload,
      });
      return;
    }

    await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelHazardAlerts,
      'Critical Hazard Alerts',
      channelDescription: 'Urgent alerts for landslides, roadblocks, and severe flash floods',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Hazard Alert',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showHazardAlert error: $e');
    }
  }

  /// Show a Route Recalculation / Corridor Change Update
  Future<void> showRouteUpdate({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (mockMode) {
      dispatchedNotifications.add({
        'type': 'route',
        'title': title,
        'body': body,
        'payload': payload,
      });
      return;
    }

    await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelRouteUpdates,
      'Route & Corridor Updates',
      channelDescription: 'Corridor risk level changes and automatic safer route recalculations',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Route Update',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showRouteUpdate error: $e');
    }
  }

  /// Show a General Notification (e.g. Incident Report Broadcast Confirmation)
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (mockMode) {
      dispatchedNotifications.add({
        'type': 'general',
        'title': title,
        'body': body,
        'payload': payload,
      });
      return;
    }

    await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelGeneral,
      'General Notifications',
      channelDescription: 'Incident report confirmations and telemetry status updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 2,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showGeneralNotification error: $e');
    }
  }

  /// Show an ongoing Live Navigation Notification (matching Android lock screen card)
  Future<void> showLiveNavigationNotification({
    required String distanceText,
    required String roadName,
    String? instruction,
  }) async {
    activeLiveNotification = {
      'distance': distanceText,
      'road': roadName,
      'instruction': instruction ?? 'towards $roadName',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (mockMode) return; // Keep dispatchedNotifications clean for test assertions

    await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelLiveNavigation,
      'Live Navigation Guidance',
      channelDescription: 'Persistent turn-by-turn guidance on Android lock screen and shade',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      subText: 'Live notifications',
      actions: const [
        AndroidNotificationAction(
          'exit_navigation',
          'Exit navigation',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: 99999,
        title: distanceText,
        body: 'towards $roadName',
        notificationDetails: details,
        payload: 'navigation_active',
      );
    } catch (e) {
      debugPrint('[NotificationService] showLiveNavigationNotification error: $e');
    }
  }

  /// Cancel active Live Navigation ongoing notification
  Future<void> cancelLiveNavigationNotification() async {
    activeLiveNotification = null;
    if (mockMode) return;
    try {
      await _notificationsPlugin.cancel(id: 99999);
    } catch (e) {
      debugPrint('[NotificationService] cancelLiveNavigationNotification error: $e');
    }
  }
}
