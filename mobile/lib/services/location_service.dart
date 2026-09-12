import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final double accuracyMeters;
  final bool isMock;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0.0,
    this.heading = 0.0,
    this.accuracyMeters = 0.0,
    this.isMock = false,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Mock location for unit/widget tests and deterministic verification.
  static LocationResult? mockLocation;

  /// Check permissions and return user-friendly message if unavailable.
  Future<String?> checkPermissions() async {
    if (mockLocation != null) return null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Device GPS / Location service is disabled. Please turn on Location in your device settings.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permissions are denied. TiyraSense needs GPS to navigate and track safely.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied. Please grant location access in App Settings.';
      }

      return null;
    } catch (e) {
      return 'Location check failed: $e';
    }
  }

  /// Get one-shot current device location.
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (mockLocation != null) {
      return mockLocation!;
    }
    final permError = await checkPermissions();
    if (permError != null) {
      // Try last known position as fallback before failing
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          return LocationResult(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            speedKmh: (lastPos.speed * 3.6).clamp(0.0, 150.0),
            heading: lastPos.heading,
            accuracyMeters: lastPos.accuracy,
          );
        }
      } catch (_) {}

      return LocationResult(
        latitude: 26.1445,
        longitude: 91.7362,
        isMock: true,
        errorMessage: permError,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final speedKmh = position.speed > 0 ? (position.speed * 3.6) : 0.0;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: speedKmh,
        heading: position.heading,
        accuracyMeters: position.accuracy,
      );
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      // Fall back to last known position
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          return LocationResult(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            speedKmh: (lastPos.speed * 3.6).clamp(0.0, 150.0),
            heading: lastPos.heading,
            accuracyMeters: lastPos.accuracy,
          );
        }
      } catch (_) {}

      return LocationResult(
        latitude: 26.1445,
        longitude: 91.7362,
        isMock: true,
        errorMessage: 'Unable to acquire satellite GPS lock: $e',
      );
    }
  }

  /// Stream live GPS position updates.
  Stream<LocationResult> getPositionStream({
    int distanceFilterMeters = 5,
    int intervalSeconds = 3,
  }) {
    if (mockLocation != null) {
      return Stream.value(mockLocation!);
    }
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
      intervalDuration: Duration(seconds: intervalSeconds),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "TiyraSense Navigation Active",
        notificationText: "Streaming corridor safety telemetry to command",
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings).map((pos) {
      final speedKmh = pos.speed > 0 ? (pos.speed * 3.6) : 0.0;
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: speedKmh,
        heading: pos.heading,
        accuracyMeters: pos.accuracy,
      );
    }).handleError((err) {
      debugPrint('[LocationService] Stream error: $err');
      return LocationResult(
        latitude: 26.1445,
        longitude: 91.7362,
        isMock: true,
        errorMessage: err.toString(),
      );
    });
  }

  /// Open device app settings if permission is permanently denied.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Open device location settings if GPS switch is turned off.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
