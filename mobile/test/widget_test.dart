import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyrasense_mobile/main.dart';
import 'package:tiyrasense_mobile/models/user_model.dart';
import 'package:tiyrasense_mobile/screens/driver_home_screen.dart';
import 'package:tiyrasense_mobile/screens/driver_map_screen.dart';
import 'package:tiyrasense_mobile/screens/field_worker_home_screen.dart';
import 'package:tiyrasense_mobile/screens/field_worker_map_screen.dart';
import 'package:tiyrasense_mobile/screens/official_home_screen.dart';
import 'package:tiyrasense_mobile/screens/admin_home_screen.dart';
import 'package:tiyrasense_mobile/screens/login_screen.dart';
import 'package:tiyrasense_mobile/screens/signup_screen.dart';
import 'package:tiyrasense_mobile/screens/alerts_screen.dart';
import 'package:tiyrasense_mobile/screens/report_history_screen.dart';
import 'package:tiyrasense_mobile/screens/splash_screen.dart';
import 'package:tiyrasense_mobile/screens/profile_screen.dart';
import 'package:tiyrasense_mobile/services/alert_service.dart';
import 'package:tiyrasense_mobile/services/api_service.dart';
import 'package:tiyrasense_mobile/services/localization_service.dart';
import 'package:tiyrasense_mobile/services/location_service.dart';
import 'package:tiyrasense_mobile/services/image_compressor_service.dart';
import 'package:tiyrasense_mobile/services/notification_service.dart';
import 'package:image/image.dart' as img;
import 'package:tiyrasense_mobile/services/offline_storage_service.dart';
import 'package:tiyrasense_mobile/services/report_service.dart';
import 'package:tiyrasense_mobile/services/vehicle_service.dart';
import 'package:tiyrasense_mobile/state/auth_provider.dart';
import 'package:tiyrasense_mobile/theme/app_theme.dart';
import 'package:tiyrasense_mobile/utils/distance_utils.dart';
import 'package:tiyrasense_mobile/widgets/map_layer_sheet.dart';
import 'package:tiyrasense_mobile/widgets/slippy_tile_layer.dart';
import 'package:tiyrasense_mobile/widgets/app_logo.dart';
import 'package:tiyrasense_mobile/widgets/journey_planning_sheet.dart';
import 'package:tiyrasense_mobile/widgets/hazard_report_sheet.dart';
import 'package:tiyrasense_mobile/widgets/live_notification_card.dart';
import 'package:tiyrasense_mobile/widgets/status_pill_badge.dart';
import 'package:tiyrasense_mobile/widgets/vehicle_profile_sheet.dart';

class FakeApiService extends ApiService {
  bool shouldFail = false;
  int? failStatusCode = 401;
  String failMessage = 'Invalid email or password';
  UserRole returnRole = UserRole.driver;

  @override
  Future<Map<String, dynamic>> evaluateRoutes({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    String vehicleClass = 'FOUR_WHEELER',
    bool preferSafety = true,
  }) async {
    return {
      'origin': origin,
      'destination': destination,
      'safest_viable_route_id': 'route-safest-1',
      'fastest_available_route_id': 'route-fastest-1',
      'candidate_routes': [
        {
          'id': 'route-safest-1',
          'name': 'Route A · NH-06 via Nongpoh',
          'classification': 'SAFEST_VIABLE',
          'distance_km': 98.4,
          'estimated_duration_seconds': 21900.0,
          'composite_risk_score': 0.14,
          'bottleneck_disruption_prob': 0.14,
        },
        {
          'id': 'route-fastest-1',
          'name': 'Route B · Direct Hill Bypass',
          'classification': 'FASTEST_AVAILABLE',
          'distance_km': 84.1,
          'estimated_duration_seconds': 19200.0,
          'composite_risk_score': 0.78,
          'bottleneck_disruption_prob': 0.78,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> startJourney({
    required String routeId,
    String? vehicleId,
    String? token,
    Map<String, dynamic>? originCoords,
    Map<String, dynamic>? destinationCoords,
    String? originName,
    String? destinationName,
    String? routeName,
    List<dynamic>? routeGeometry,
  }) async {
    return {
      'id': 'journey-mock-001',
      'route_id': routeId,
      'status': 'IN_TRANSIT',
      'current_latitude': 26.1445,
      'current_longitude': 91.7362,
    };
  }

  @override
  Future<void> sendTelemetry({
    required String journeyId,
    required double latitude,
    required double longitude,
    double speedKmh = 45.0,
    double headingDegrees = 0.0,
  }) async {}

  @override
  Future<Map<String, dynamic>> getJourneyTracking(String journeyId) async {
    return {
      'journey_id': journeyId,
      'status': 'IN_TRANSIT',
      'current_latitude': 26.1445,
      'current_longitude': 91.7362,
      'remaining_distance_km': 95.0,
      'remaining_duration_seconds': 21000.0,
      'forward_hazards': [],
    };
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (shouldFail) {
      throw ApiException(failMessage, failStatusCode ?? 401);
    }
    return {
      'access_token': 'test_token_12345',
      'token_type': 'bearer',
      'expires_in_seconds': 3600,
      'user': {
        'id': '00000000-0000-0000-0000-000000000001',
        'email': email,
        'full_name': 'Test User',
        'role': returnRole.toApiRole(),
        'phone_number': '+91-98765-43210',
        'organization': 'Assam Logistics Division',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
    UserRole role,
  ) async {
    if (shouldFail) {
      throw ApiException(failMessage, failStatusCode ?? 400);
    }
    return {
      'id': '00000000-0000-0000-0000-000000000002',
      'email': email,
      'full_name': fullName,
      'role': role.toApiRole(),
    };
  }

  @override
  Future<UserModel> fetchProfile(String token) async {
    if (shouldFail) {
      throw ApiException(failMessage, failStatusCode);
    }
    return UserModel(
      id: '00000000-0000-0000-0000-000000000001',
      email: 'driver@tiyrasense.in',
      fullName: 'Test Driver',
      role: returnRole,
    );
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    NotificationService.mockMode = true;
    NotificationService.dispatchedNotifications.clear();
    LocationService.mockLocation = const LocationResult(
      latitude: 26.1445,
      longitude: 91.7362,
      speedKmh: 45.0,
      heading: 90.0,
      accuracyMeters: 3.0,
    );
    reportService.reset();
    alertService.reset();
  });

  testWidgets('renders login screen with TiyraSense branding and fields', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('TiyraSense'), findsOneWidget);
    expect(find.text('NER Logistics Intelligence'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('displays validation error when submitting empty fields', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('manual credential entry populates driver email and password without autofill', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'driver@tiyrasense.in');
    await tester.enterText(find.byType(TextFormField).last, 'DriverPass2026!');
    await tester.pumpAndSettle();

    expect(find.text('driver@tiyrasense.in'), findsOneWidget);
    expect(find.text('DriverPass2026!'), findsOneWidget);
  });

  testWidgets('successful driver login navigates to DriverHomeScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'driver@tiyrasense.in');
    await tester.enterText(find.byType(TextFormField).last, 'DriverPass2026!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.text('NH-06 Guwahati to Shillong'), findsOneWidget);
    expect(find.text('PASSABLE'), findsOneWidget);
    expect(find.text('Plan Safer Journey'), findsOneWidget);
  });

  testWidgets('successful field worker login navigates to FieldWorkerHomeScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.fieldWorker;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'worker@tiyrasense.in');
    await tester.enterText(find.byType(TextFormField).last, 'WorkerPass2026!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(FieldWorkerHomeScreen), findsOneWidget);
    expect(find.text('Report Road Hazard'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
  });

  testWidgets('authentication error displays error banner', (tester) async {
    final fakeApi = FakeApiService()
      ..shouldFail = true
      ..failMessage = 'Invalid email or password. Please verify credentials.';
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'driver@tiyrasense.in');
    await tester.enterText(find.byType(TextFormField).last, 'DriverPass2026!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password. Please verify credentials.'), findsOneWidget);
  });

  testWidgets('driver home screen logout via profile returns to LoginScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'driver@tiyrasense.in');
    await tester.enterText(find.byType(TextFormField).last, 'DriverPass2026!');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverHomeScreen), findsOneWidget);

    // Navigate to Profile tab (Icon: person_rounded)
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    // Scroll to and tap Sign Out button
    await tester.scrollUntilVisible(
      find.text('Sign Out'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('persisted session auto-authenticates into DriverHomeScreen upon app restart', (tester) async {
    final cachedUser = UserModel(
      id: '00000000-0000-0000-0000-000000000001',
      email: 'driver@tiyrasense.in',
      fullName: 'Rajesh Das',
      role: UserRole.driver,
    );

    FlutterSecureStorage.setMockInitialValues({
      'tiyrasense_auth_token': 'saved_jwt_token_abc123',
      'tiyrasense_user_data': jsonEncode(cachedUser.toJson()),
    });

    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    await authProvider.initialize();

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('NH-06 Guwahati to Shillong'), findsOneWidget);
  });

  testWidgets('persisted session stays logged in even when starting offline', (tester) async {
    final cachedUser = UserModel(
      id: '00000000-0000-0000-0000-000000000002',
      email: 'worker@tiyrasense.in',
      fullName: 'Field Agent',
      role: UserRole.fieldWorker,
    );

    FlutterSecureStorage.setMockInitialValues({
      'tiyrasense_auth_token': 'saved_jwt_token_worker',
      'tiyrasense_user_data': jsonEncode(cachedUser.toJson()),
    });

    final offlineApi = FakeApiService()
      ..shouldFail = true
      ..failStatusCode = null
      ..failMessage = 'SocketException: Network unreachable';
    final authProvider = AuthProvider(apiService: offlineApi);

    await authProvider.initialize();

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(FieldWorkerHomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('user stays logged in across app restarts even if token expires until they click Sign Out', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'tiyrasense_auth_token': 'expired_jwt_token',
      'tiyrasense_user_data': jsonEncode({
        'id': '00000000-0000-0000-0000-000000000001',
        'email': 'driver@tiyrasense.in',
        'full_name': 'Driver',
        'role': 'DRIVER',
      }),
    });

    final expiredApi = FakeApiService()
      ..shouldFail = true
      ..failStatusCode = 401
      ..failMessage = 'Token expired';
    final authProvider = AuthProvider(apiService: expiredApi);

    await authProvider.initialize();

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    // User stays logged in and enters DriverHomeScreen, not LoginScreen
    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // Only when user navigates to Profile and explicitly taps Sign Out do they log out
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sign Out'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('renders SignUpScreen with role restriction banner and fields', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(
      MaterialApp(
        home: SignUpScreen(authProviderOverride: authProvider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsNWidgets(2));
    expect(find.text('Official and Admin accounts are provisioned by administrators only.'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Field Worker'), findsOneWidget);
  });

  testWidgets('renders JourneyPlanningSheet with Safest and Faster routes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyPlanningSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan Journey'), findsOneWidget);
    expect(find.text('Guwahati Port Hub'), findsOneWidget);
    expect(find.text('Shillong Terminal Hub'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Faster'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Confirm Route'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Confirm Route'), findsOneWidget);
  });

  testWidgets('JourneyPlanningSheet allows selecting origin, swapping locations, and picking vehicle/cargo', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyPlanningSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Swap origin and destination
    expect(find.text('Swap'), findsOneWidget);
    await tester.tap(find.text('Swap'));
    await tester.pumpAndSettle();

    // 2. Open Vehicle picker
    final vehicleFinder = find.text('Tata Prima 31T');
    await tester.ensureVisible(vehicleFinder);
    await tester.pumpAndSettle();
    expect(vehicleFinder, findsOneWidget);
    await tester.tap(vehicleFinder);
    await tester.pumpAndSettle();

    expect(find.text('Select Vehicle Profile'), findsOneWidget);
    expect(find.text('Mahindra Bolero Maxi'), findsOneWidget);
    await tester.tap(find.text('Mahindra Bolero Maxi'));
    await tester.pumpAndSettle();

    expect(find.text('Mahindra Bolero Maxi'), findsOneWidget);

    // 3. Open Cargo picker
    final cargoFinder = find.text('FMCG Critical');
    await tester.ensureVisible(cargoFinder);
    await tester.pumpAndSettle();
    expect(cargoFinder, findsOneWidget);
    await tester.tap(cargoFinder);
    await tester.pumpAndSettle();

    expect(find.text('Select Cargo Profile'), findsOneWidget);
    expect(find.text('Medical & Disaster Relief'), findsOneWidget);
    await tester.tap(find.text('Medical & Disaster Relief'));
    await tester.pumpAndSettle();

    expect(find.text('Medical & Disaster Relief'), findsOneWidget);
  });

  testWidgets('renders HazardReportSheet with GPS lock and broadcast button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HazardReportSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report Hazard'), findsOneWidget);
    expect(find.text('GPS LOCKED'), findsOneWidget);
    expect(find.text('Landslide'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Broadcast Incident Report'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Broadcast Incident Report'), findsOneWidget);
  });

  testWidgets('renders AlertsScreen with categories and empty filter handling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlertsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('ALL (6)'), findsOneWidget);
    expect(find.text('Active Landslide & Road Blockage'), findsOneWidget);
  });

  testWidgets('renders AppLogo widgets using project official assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppLogo.splash(size: 96),
              AppLogo.icon(size: 36),
              AppLogo.horizontal(height: 24),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLogo), findsNWidgets(3));
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('renders SplashScreen with official splash logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Route')),
        },
      ),
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);

    // Advance past 2-second hold timer to avoid pending timer assertion
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();
  });

  testWidgets('unauthenticated access to protected routes redirects to LoginScreen without exposing open screens', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    final navState = tester.state<NavigatorState>(find.byType(Navigator));
    navState.pushNamed('/driver-home');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DriverHomeScreen), findsNothing);

    navState.pushNamed('/field-worker-home');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(FieldWorkerHomeScreen), findsNothing);
  });

  testWidgets('renders ProfileScreen and opens Edit Profile sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(role: UserRole.driver),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Offline Data'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
  });

  testWidgets('renders ProfileScreen and syncs telemetry via clean sync dialog', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(role: UserRole.driver),
      ),
    );
    await tester.pumpAndSettle();

    final syncFinder = find.text('Sync Now');
    expect(syncFinder, findsOneWidget);
    await tester.ensureVisible(syncFinder);
    await tester.pumpAndSettle();

    await tester.tap(syncFinder);
    await tester.pump();

    // Dialog opens with Syncing Telemetry
    expect(find.text('Syncing Telemetry'), findsOneWidget);
    expect(find.text('Verifying offline hazard queue'), findsOneWidget);

    // Fast-forward past sync time (1300ms)
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('Sync Complete'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Auto close timer finishes (800ms)
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Dialog dismissed and 'Just now' displayed
    expect(find.text('Just now'), findsOneWidget);
  });

  testWidgets('renders DriverMapScreen and engages active navigation with live telemetry', (tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(apiServiceOverride: fakeApi),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guwahati → Shillong'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Change Route'), findsOneWidget);

    await tester.tap(find.text('Navigate'));
    await tester.pump();

    expect(find.textContaining('Guidance Active'), findsOneWidget);
    expect(find.text('LIVE TELEMETRY STREAMING'), findsOneWidget);

    await tester.tap(find.textContaining('Guidance Active'));
    await tester.pump();

    expect(find.text('Navigate'), findsOneWidget);
  });

  testWidgets('DriverMapScreen engages Google Maps style live road directions with maneuvers, speed limit, and steps sheet', (tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(apiServiceOverride: fakeApi),
      ),
    );
    await tester.pumpAndSettle();

    // Start active navigation
    await tester.tap(find.text('Navigate'));
    await tester.pump();

    // Verify Google Maps direction banner elements
    expect(find.textContaining('In '), findsWidgets);
    expect(find.textContaining('Then:'), findsOneWidget);
    expect(find.text('LIMIT'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.textContaining('km/h'), findsWidgets);

    // Verify Google Maps bottom navigation bar elements
    expect(find.textContaining('min'), findsWidgets);
    expect(find.textContaining('km'), findsWidgets);
    expect(find.text('Steps (8)'), findsOneWidget);

    // Test Voice Guidance toggle
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.notification_important_rounded), findsOneWidget);

    // Open Turn-by-Turn Directions modal sheet via Steps button
    await tester.tap(find.text('Steps (8)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Turn-by-turn Directions'), findsOneWidget);
    expect(find.textContaining('Guwahati to Shillong'), findsOneWidget);

    // Close turn-by-turn sheet
    await tester.tap(find.byIcon(Icons.close_rounded).first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the red Exit [X] button to stop navigation
    final exitBtn = find.byWidgetPredicate(
      (w) => w is InkWell && w.child is Container && (w.child as Container).decoration is BoxDecoration,
    );
    expect(exitBtn, findsWidgets);

    // Stop navigation by tapping Guidance Active pill
    await tester.tap(find.textContaining('Guidance Active'));
    await tester.pump();

    // Verify navigation stopped and normal controls returned
    expect(find.text('Navigate'), findsOneWidget);
  });

  testWidgets('JourneyPlanningSheet supports selecting current GPS location', (tester) async {
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JourneyPlanningSheet(apiServiceOverride: fakeApi),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Origin Picker
    await tester.tap(find.text('Guwahati Port Hub'));
    await tester.pumpAndSettle();

    // Find and tap 'Use Current GPS Location'
    expect(find.text('Use Current GPS Location'), findsOneWidget);
    await tester.tap(find.text('Use Current GPS Location'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Current GPS'), findsOneWidget);
  });

  testWidgets('AlertsScreen syncs live corridor alerts and persists seen status to local storage', (tester) async {
    alertService.reset();
    await tester.pumpWidget(
      const MaterialApp(
        home: AlertsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sync button exists (instead of fake test push bell)
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.sync_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Syncing live alerts'), findsOneWidget);

    // Verify unread alerts are initially present
    expect(alertService.unreadCount, greaterThan(0));

    // Verify seen messages are marked as read when requested and persisted
    alertService.markSeenAsRead();
    await tester.pumpAndSettle();
    expect(alertService.unreadCount, 0);

    // Verify dismissed alert is deleted and recorded
    final initialCount = alertService.alerts.length;
    final firstId = alertService.alerts.first.id;
    alertService.dismissAlert(firstId);
    expect(alertService.alerts.length, initialCount - 1);
    expect(alertService.alerts.any((a) => a.id == firstId), isFalse);
  });

  testWidgets('HazardReportSheet broadcasts incident report and triggers notification', (tester) async {
    bool submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HazardReportSheet(onSubmit: () => submitted = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Broadcast Incident Report'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Broadcast Incident Report'));
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(NotificationService.dispatchedNotifications.any((n) => n['type'] == 'general'), isTrue);
  });

  testWidgets('AlertsScreen mark all read marks alerts as read and updates UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlertsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initially we have unread alerts and NEW tags
    expect(find.text('Mark all read'), findsOneWidget);
    expect(alertService.unreadCount, greaterThan(0));
    expect(find.text('NEW'), findsWidgets);

    // Tap 'Mark all read'
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    // Verify unread count is now 0 and NEW tags are gone
    expect(alertService.unreadCount, 0);
    expect(find.text('NEW'), findsNothing);
    expect(find.textContaining('marked as read'), findsOneWidget);
  });

  testWidgets('ReportHistoryScreen renders incident list and reflects new submissions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incident Report History'), findsOneWidget);
    expect(find.text('TOTAL SUBMISSIONS'), findsOneWidget);
    expect(find.text('Landslide'), findsWidgets);

    // Submit a new report
    reportService.addReport(
      hazardType: 'Flash Flood',
      severity: 'Full Blockage',
      location: 'NH-102 KM 24.5',
      notes: 'Water level rising rapidly over highway.',
    );
    await tester.pumpAndSettle();

    // Verify new report is rendered and tagged with YOU
    expect(find.text('NH-102 KM 24.5'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
  });

  testWidgets('DriverHomeScreen notification button only displays red dot when unread alerts exist', (tester) async {
    final auth = AuthProvider();
    const testDriver = UserModel(
      id: 'usr-1',
      fullName: 'Vikram Das',
      email: 'driver@tiyrasense.in',
      role: UserRole.driver,
      organization: 'NER Logistics Fleet',
    );

    alertService.reset();
    expect(alertService.unreadCount, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverHomeScreen(user: testDriver, authProvider: auth),
      ),
    );
    await tester.pumpAndSettle();

    // Verify notification button exists
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

    // Red dot finder: Container with circle shape and red color
    final redDotFinder = find.byWidgetPredicate(
      (w) => w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color == AppTheme.red,
    );
    expect(redDotFinder, findsWidgets);

    // Mark all read
    alertService.markAllRead();
    await tester.pumpAndSettle();

    // Red dot should no longer be present
    expect(redDotFinder, findsNothing);

    // Add new alert dynamically
    alertService.addAlert(
      type: 'EMERGENCY',
      category: 'HAZARD',
      location: 'NH-37 KM 88',
      title: 'Rockfall Alert',
      desc: 'Partial blockage',
      status: BadgeStatusType.caution,
      isEmergency: true,
    );
    await tester.pumpAndSettle();

    // Red dot reappears
    expect(redDotFinder, findsWidgets);
  });

  testWidgets('VehicleProfileSheet allows switching vehicle and cargo profile', (tester) async {
    // Reset vehicle to default
    vehicleService.selectVehicleByTitle('Tata Prima 31T');
    vehicleService.selectCargoByTitle('FMCG Critical');
    expect(vehicleService.selectedVehicle.title, 'Tata Prima 31T');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleProfileSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and vehicle list
    expect(find.text('Vehicle & Cargo Configuration'), findsOneWidget);
    expect(find.text('Ashok Leyland 1618'), findsOneWidget);

    // Tap Ashok Leyland 1618
    await tester.tap(find.text('Ashok Leyland 1618'));
    await tester.pumpAndSettle();

    // Tap Save Profile
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    // Verify vehicle service updated
    expect(vehicleService.selectedVehicle.title, 'Ashok Leyland 1618');
  });

  testWidgets('VehicleProfileSheet allows adding and selecting custom vehicle and cargo entries', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleProfileSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify custom vehicle entry button is visible in Vehicle tab
    expect(find.text('+ Add Custom Vehicle Entry'), findsOneWidget);

    // Tap + Add Custom Vehicle Entry
    await tester.tap(find.text('+ Add Custom Vehicle Entry'));
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('Add Custom Vehicle Entry'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Vehicle Name / Model *'), 'Eicher Pro 3019');
    await tester.enterText(find.widgetWithText(TextField, 'Gross Weight'), '18.5 Tonnes');
    await tester.tap(find.text('Add & Select Vehicle'));
    await tester.pumpAndSettle();

    // Verify custom vehicle is now created and selected
    expect(vehicleService.selectedVehicle.title, 'Eicher Pro 3019');
    expect(vehicleService.selectedVehicle.isCustom, true);
    expect(vehicleService.selectedVehicle.grossWeight, '18.5 Tonnes');

    // Switch to Cargo tab
    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    // Tap + Add Custom Cargo Entry
    expect(find.text('+ Add Custom Cargo Entry'), findsOneWidget);
    await tester.tap(find.text('+ Add Custom Cargo Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Add Custom Cargo Entry'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Cargo Description / Title *'), 'Solar PV Modules');
    await tester.tap(find.text('Add & Select Cargo'));
    await tester.pumpAndSettle();

    // Verify custom cargo is now created and selected
    expect(vehicleService.selectedCargo.title, 'Solar PV Modules');
    expect(vehicleService.selectedCargo.isCustom, true);
  });

  testWidgets('DriverHomeScreen card taps switch to Map view and SideDrawer SOS helpline dials correctly', (tester) async {
    final driverUser = UserModel(
      id: 'driver-test-01',
      email: 'driver@test.local',
      fullName: 'Ramen Borah',
      role: UserRole.driver,
      organization: 'All Assam Commercial Truckers Union',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DriverHomeScreen(
          user: driverUser,
          authProvider: AuthProvider(apiService: FakeApiService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initially on Home tab (showing corridor status card)
    expect(find.text('NH-06 Guwahati to Shillong'), findsOneWidget);

    // Tap Corridor Status Card
    await tester.tap(find.text('NH-06 Guwahati to Shillong'));
    await tester.pumpAndSettle();

    // Verify switched to Map view (showing Navigate button)
    expect(find.text('Navigate'), findsOneWidget);

    // Switch back to Home tab via bottom navigation bar
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('NH-06 Guwahati to Shillong'), findsOneWidget);

    // Open side drawer
    final ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify Emergency SOS & Towing option in drawer
    expect(find.text('Emergency SOS & Towing'), findsOneWidget);
    await tester.tap(find.text('Emergency SOS & Towing'));
    await tester.pumpAndSettle();

    // Verify emergency sheet opened
    expect(find.text('Emergency Highway Helplines'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);

    // Tap the 112 emergency contact row
    await tester.tap(find.text('112'));
    await tester.pumpAndSettle();

    // Verify dialing SnackBar appeared
    expect(find.text('Dialing National Emergency & Highway Police (112)...'), findsOneWidget);
  });

  test('DistanceUtils accurately calculates Haversine, road curvature distance, and ETA', () {
    // Guwahati (26.1445, 91.7362) to Shillong (25.5788, 91.8933)
    final straightLineKm = DistanceUtils.haversineKm(26.1445, 91.7362, 25.5788, 91.8933);
    // Straight line is approximately 65 km
    expect(straightLineKm, greaterThan(60.0));
    expect(straightLineKm, lessThan(70.0));

    // Road distance with 1.38x curvature multiplier
    final roadKm = DistanceUtils.calculateRoadDistanceKm(26.1445, 91.7362, 25.5788, 91.8933);
    expect(roadKm, greaterThan(85.0));
    expect(roadKm, lessThan(100.0));

    // Formatters
    expect(DistanceUtils.formatDistance(roadKm), contains('km'));
    final eta = DistanceUtils.formatEta(roadKm, averageSpeedKmh: 35.0);
    expect(eta, startsWith('ETA'));
    expect(eta, contains('h'));
  });

  testWidgets('DriverMapScreen renders with real distance, displays map canvas, and allows zooming', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(
          initialRouteData: const {
            'name': 'NH-06 via Nongpoh',
            'origin_name': 'Guwahati (ISBT)',
            'destination_name': 'Shillong (Police Bazar)',
            'origin_coords': [26.1445, 91.7362],
            'destination_coords': [25.5788, 91.8933],
            'distance_km': 98.4,
            'estimated_duration_seconds': 21900,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify origin and destination names are rendered in the header route pill
    expect(find.text('Guwahati → Shillong'), findsOneWidget);

    // Verify distance is rendered in the bottom sheet via RichText
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('98.4 km'),
      ),
      findsOneWidget,
    );

    // Verify zoom in and zoom out buttons exist
    final zoomInFinder = find.byIcon(Icons.add_rounded);
    final zoomOutFinder = find.byIcon(Icons.remove_rounded);
    final reCenterFinder = find.byIcon(Icons.center_focus_strong_rounded);

    expect(zoomInFinder, findsOneWidget);
    expect(zoomOutFinder, findsOneWidget);
    expect(reCenterFinder, findsOneWidget);

    // Tap zoom in
    await tester.tap(zoomInFinder);
    await tester.pumpAndSettle();

    // Tap recenter
    await tester.tap(reCenterFinder);
    await tester.pumpAndSettle();
    expect(find.text('Map centered on active corridor'), findsOneWidget);
  });

  test('LocalizationService supports Manipuri and replaces Bodo while keeping TiyraSense intact in English', () async {
    // Verify supported languages contains Manipuri and does not contain Bodo
    final supported = LocalizationService.supportedLanguages;
    final codes = supported.map((l) => l['code']).toList();
    final names = supported.map((l) => l['name']).toList();

    expect(codes, contains('mni'));
    expect(names, contains('Manipuri'));
    expect(codes, isNot(contains('brx')));
    expect(names, isNot(contains('Bodo')));

    // Verify app name remains 'TiyraSense' in English across all locales
    for (final code in ['en', 'as', 'bn', 'hi', 'mni']) {
      await localizationService.setLanguageCode(code);
      expect(localizationService.tr('app_name'), equals('TiyraSense'));
    }

    // Reset back to English
    await localizationService.setLanguageCode('en');
    expect(localizationService.localeCode, equals('en'));
  });

  testWidgets('ProfileScreen language selection changes UI texts to Manipuri and Bengali', (tester) async {
    // Reset to English first
    await localizationService.setLanguageCode('en');

    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: localizationService,
        builder: (context, _) => const MaterialApp(
          home: ProfileScreen(role: UserRole.driver),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial English texts
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('JOURNEYS'), findsOneWidget);

    // Open language selection sheet
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    // Verify Manipuri option exists and Bodo does NOT exist
    expect(find.text('মৈতৈলোন্ (Manipuri)'), findsOneWidget);
    expect(find.text('बड़ो (Bodo)'), findsNothing);

    // Select Manipuri (মৈতৈলোন্)
    await tester.tap(find.text('মৈতৈলোন্ (Manipuri)'));
    await tester.pumpAndSettle();

    // Verify UI texts actually changed to Manipuri
    expect(find.text('প্রোফাইল শেমদোকপা'), findsOneWidget); // Edit Profile in Manipuri
    expect(find.text('পাসৱার্দ হোংদোকপা'), findsOneWidget); // Change Password in Manipuri
    expect(find.text('লোন'), findsOneWidget); // Language in Manipuri
    expect(find.text('চৎথোক-চৎশিন'), findsOneWidget); // Journeys in Manipuri

    // Switch to Bengali
    await tester.tap(find.text('লোন'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা (Bengali)'));
    await tester.pumpAndSettle();

    // Verify UI texts actually changed to Bengali
    expect(find.text('প্রোফাইল সম্পাদনা'), findsOneWidget); // Edit Profile in Bengali
    expect(find.text('পাসওয়ার্ড পরিবর্তন'), findsOneWidget); // Change Password in Bengali
    expect(find.text('ভাষা'), findsOneWidget); // Language in Bengali

    // Reset back to English
    await tester.tap(find.text('ভাষা'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });

  test('DistanceUtils.computeDetailedBreakdown applies NER terrain, vehicle axle, and hazard clauses correctly', () {
    // Guwahati (26.1445, 91.7362) to Shillong (25.5788, 91.8933)
    final breakdownHeavySafest = DistanceUtils.computeDetailedBreakdown(
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Tata Prima 31T (31 Tonnes)',
      cargoTitle: 'POL & Hazardous Fuel',
      isSafestRoute: true,
      disruptionProbPct: 15,
    );

    expect(breakdownHeavySafest.baseAerialKm, greaterThan(60.0));
    expect(breakdownHeavySafest.baseAerialKm, lessThan(70.0));
    // Curvature is +38% of base aerial
    expect(breakdownHeavySafest.terrainCurvatureKm, closeTo(breakdownHeavySafest.baseAerialKm * 0.38, 0.1));
    // Heavy truck axle is +12%
    expect(breakdownHeavySafest.vehicleAxleKm, closeTo(breakdownHeavySafest.baseAerialKm * 0.12, 0.1));
    // Safest route precautionary hazard buffer for 15% disruption is 6.0 km
    expect(breakdownHeavySafest.hazardDetourKm, equals(6.0));
    // POL cargo buffer is +3%
    expect(breakdownHeavySafest.cargoBufferKm, closeTo(breakdownHeavySafest.baseAerialKm * 0.03, 0.1));

    // Total road km equals sum of all components
    final expectedTotal = breakdownHeavySafest.baseAerialKm +
        breakdownHeavySafest.terrainCurvatureKm +
        breakdownHeavySafest.vehicleAxleKm +
        breakdownHeavySafest.hazardDetourKm +
        breakdownHeavySafest.cargoBufferKm;
    expect(breakdownHeavySafest.totalRoadKm, closeTo(expectedTotal, 0.01));

    // Clauses list contains all 5 clauses
    expect(breakdownHeavySafest.clauses.length, equals(5));
    final clauseCodes = breakdownHeavySafest.clauses.map((c) => c.clauseCode).toList();
    expect(clauseCodes, containsAll(['BASE_AERIAL', 'IRC_TERRAIN', 'VEHICLE_AXLE', 'HAZARD_DETOUR', 'CARGO_BUFFER']));

    // Fastest route with light vehicle (Bolero) and standard FMCG cargo has 0 hazard detour and minimal axle clause
    final breakdownLightFastest = DistanceUtils.computeDetailedBreakdown(
      lat1: 26.1445,
      lon1: 91.7362,
      lat2: 25.5788,
      lon2: 91.8933,
      vehicleTitle: 'Mahindra Bolero Maxi (3.5T)',
      cargoTitle: 'FMCG Standard',
      isSafestRoute: false,
    );

    expect(breakdownLightFastest.hazardDetourKm, equals(0.0));
    expect(breakdownLightFastest.cargoBufferKm, equals(0.0));
    expect(breakdownLightFastest.vehicleAxleKm, closeTo(breakdownLightFastest.baseAerialKm * 0.01, 0.1));
    expect(breakdownLightFastest.totalRoadKm, lessThan(breakdownHeavySafest.totalRoadKm));
  });

  testWidgets('JourneyPlanningSheet displays Clauses Applied badge and opens Distance Clauses sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyPlanningSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 'Clauses Applied' badge is rendered on candidate route cards
    final clausesBadgeFinder = find.text('Clauses Applied');
    expect(clausesBadgeFinder, findsWidgets);

    // Tap the first 'Clauses Applied' badge
    await tester.tap(clausesBadgeFinder.first);
    await tester.pumpAndSettle();

    // Verify modal sheet opens with regulatory distance breakdown
    expect(find.text('Distance Clauses & Terrain Audit'), findsOneWidget);
    expect(find.text('AERIAL BASE'), findsOneWidget);
    expect(find.text('ROAD DISTANCE'), findsOneWidget);
    expect(find.text('IRC:SP:48 Mountain Curvature Clause'), findsOneWidget);
    expect(find.text('Vehicle Axle & Weight Clearance Clause'), findsOneWidget);
    expect(find.text('Close Audit View'), findsOneWidget);

    // Close the sheet
    await tester.tap(find.text('Close Audit View'));
    await tester.pumpAndSettle();
    expect(find.text('Distance Clauses & Terrain Audit'), findsNothing);
  });

  testWidgets('DriverMapScreen bottom card displays Clauses chip and opens modal', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(
          initialRouteData: const {
            'name': 'NH-06 via Nongpoh',
            'origin_name': 'Guwahati (ISBT)',
            'destination_name': 'Shillong (Police Bazar)',
            'origin_coords': [26.1445, 91.7362],
            'destination_coords': [25.5788, 91.8933],
            'distance_km': 98.4,
            'estimated_duration_seconds': 21900,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 'Clauses' chip is present on the bottom peek card
    final clausesChip = find.text('Clauses');
    expect(clausesChip, findsOneWidget);

    // Tap 'Clauses' chip
    await tester.tap(clausesChip);
    await tester.pumpAndSettle();

    // Verify in-transit clauses modal opens
    expect(find.text('Distance Clauses & Terrain Audit'), findsOneWidget);
    expect(find.text('IRC:SP:48 Mountain Curvature Clause'), findsOneWidget);
    expect(find.text('Close Audit View'), findsOneWidget);

    // Tap Close Audit View to dismiss
    await tester.tap(find.text('Close Audit View'));
    await tester.pumpAndSettle();
    expect(find.text('Distance Clauses & Terrain Audit'), findsNothing);
  });

  testWidgets('driver and field officer screens adapt to language change dynamically', (tester) async {
    final driver = UserModel(
      id: 'd1',
      email: 'driver@tiyrasense.in',
      fullName: 'Ramen Borah',
      role: UserRole.driver,
      phoneNumber: '+91 98765 43210',
    );
    final fieldWorker = UserModel(
      id: 'fw1',
      email: 'officer@tiyrasense.in',
      fullName: 'Priya Mao',
      role: UserRole.fieldWorker,
      phoneNumber: '+91 98765 43211',
    );
    final authProvider = AuthProvider(apiService: FakeApiService());

    // 1. Render in English first
    await localizationService.setLanguageCode('en');
    await tester.pumpWidget(
      MaterialApp(
        home: DriverHomeScreen(user: driver, authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plan Safer Journey'), findsOneWidget);
    expect(find.text('GPS / NavIC Locked'), findsOneWidget);
    expect(find.text('On Duty · Primary Escort Unit'), findsOneWidget);

    // 2. Switch to Bengali
    await localizationService.setLanguageCode('bn');
    await tester.pumpWidget(
      MaterialApp(
        home: DriverHomeScreen(user: driver, authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(localizationService.tr('plan_safer_journey')), findsOneWidget);
    expect(find.text(localizationService.tr('gps_locked')), findsOneWidget);
    expect(find.text(localizationService.tr('on_duty_escort')), findsOneWidget);

    // 3. Field Worker Home Screen in Bengali
    await tester.pumpWidget(
      MaterialApp(
        home: FieldWorkerHomeScreen(user: fieldWorker, authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(localizationService.tr('field_recon_active')), findsOneWidget);
    expect(find.text(localizationService.tr('report_road_hazard')), findsOneWidget);
    expect(find.text(localizationService.tr('quick_dispatch')), findsOneWidget);

    // Reset back to English
    await localizationService.setLanguageCode('en');
  });

  testWidgets('broadcast news or emergency alert triggers push notification, but routine alerts do not', (tester) async {
    NotificationService.mockMode = true;
    NotificationService.dispatchedNotifications.clear();

    // 1. Adding a routine alert without pushNotification flag should NOT trigger any notification
    alertService.addAlert(
      type: 'INFO',
      category: 'WEATHER',
      location: 'NH-102 KM 34',
      title: 'Light Drizzle',
      desc: 'Slight wet pavement reported.',
      status: BadgeStatusType.caution,
      isEmergency: false,
      pushNotification: false,
    );
    expect(NotificationService.dispatchedNotifications.isEmpty, isTrue);

    // 2. Broadcasting an emergency alert SHOULD trigger a hazard push notification
    alertService.addAlert(
      type: 'EMERGENCY',
      category: 'HAZARD',
      location: 'NH-06 KM 88',
      title: 'Sudden Mudslide Obstruction',
      desc: 'Both lanes blocked near Nongpoh.',
      status: BadgeStatusType.blocked,
      isEmergency: true,
      pushNotification: true,
    );
    expect(NotificationService.dispatchedNotifications.length, 1);
    expect(NotificationService.dispatchedNotifications.first['type'], 'hazard');
    expect(NotificationService.dispatchedNotifications.first['title'], contains('Sudden Mudslide'));

    // 3. Broadcasting specific official news bulletin SHOULD trigger a general push notification
    alertService.broadcastNewsAlert(
      headline: 'IMD Red Alert Issued for East Khasi Hills',
      summary: 'Heavy rainfall expected over next 24 hours. Transit advisories active.',
      location: 'Shillong Corridor',
      source: 'ASDMA Official Bulletin',
    );
    expect(NotificationService.dispatchedNotifications.length, 2);
    expect(NotificationService.dispatchedNotifications.last['type'], 'general');
    expect(NotificationService.dispatchedNotifications.last['title'], contains('IMD Red Alert'));
  });

  testWidgets('DriverMapScreen route selection chips and navigation start do not trigger push notifications', (tester) async {
    NotificationService.mockMode = true;
    NotificationService.dispatchedNotifications.clear();

    final fakeApi = FakeApiService();
    // 1. Test JourneyPlanningSheet route selection
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JourneyPlanningSheet(apiServiceOverride: fakeApi),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recommended'), findsOneWidget);
    await tester.tap(find.text('Recommended'));
    await tester.pumpAndSettle();

    expect(find.text('Faster'), findsOneWidget);
    await tester.tap(find.text('Faster'));
    await tester.pumpAndSettle();

    // 2. Test DriverMapScreen navigation start
    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(apiServiceOverride: fakeApi),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Navigate'), findsOneWidget);
    await tester.tap(find.text('Navigate'));
    await tester.pump();

    // Verify NO unneeded notifications were dispatched during route selection or navigation start
    expect(NotificationService.dispatchedNotifications.isEmpty, isTrue);
  });

  testWidgets('successful official login navigates to OfficialHomeScreen with command actions', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.official;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'official@tiyrasense.gov.in');
    await tester.enterText(find.byType(TextFormField).last, 'OfficialPass2026!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficialHomeScreen), findsOneWidget);
    expect(find.text('OFFICIAL COMMAND'), findsOneWidget);
    expect(find.text('NER Transit Command Hub'), findsOneWidget);
    expect(find.text('Trigger Corridor Alert'), findsOneWidget);
    expect(find.text('Review & Verify Reports'), findsOneWidget);
    expect(find.text('Fleet Live Tracking'), findsOneWidget);
  });

  testWidgets('OfficialHomeScreen allows official to inspect fleet tracking and verify reports', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.official;
    final authProvider = AuthProvider(apiService: fakeApi);
    const testUser = UserModel(
      id: '00000000-0000-0000-0000-000000000005',
      email: 'official@tiyrasense.gov.in',
      fullName: 'Pranjal Sarmah',
      role: UserRole.official,
    );

    reportService.reset();

    await tester.pumpWidget(
      MaterialApp(
        home: OfficialHomeScreen(user: testUser, authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();

    // Verify incident verification button on Command Hub tab
    final verifyBtn = find.text('Verify & Broadcast');
    expect(verifyBtn, findsOneWidget);
    await tester.scrollUntilVisible(verifyBtn, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();

    // Switch to Fleet Tracking tab
    await tester.tap(find.text('Fleet Tracking'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet Live Tracking'), findsOneWidget);
    expect(find.text('TRK-01'), findsWidgets);
    expect(find.text('Tata Prima 3530.K (18-Wheeler)'), findsOneWidget);
    expect(find.text('Ramen Borah'), findsOneWidget);

    // Switch to Reports Queue tab
    await tester.tap(find.text('Reports Queue'));
    await tester.pumpAndSettle();

    expect(find.text('Incident Verification Queue'), findsOneWidget);
    expect(find.text('VERIFIED'), findsWidgets);
  });

  testWidgets('successful admin login navigates to AdminHomeScreen with governance controls', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.admin;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'admin@tiyrasense.gov.in');
    await tester.enterText(find.byType(TextFormField).last, 'AdminPass2026!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomeScreen), findsOneWidget);
    expect(find.text('SYSTEM ADMINISTRATOR'), findsOneWidget);
    expect(find.text('Infrastructure Core'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Data Source Health'), findsOneWidget);
  });

  testWidgets('AdminHomeScreen allows admin to manage users and run data source health ping', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.admin;
    final authProvider = AuthProvider(apiService: fakeApi);
    const testUser = UserModel(
      id: '00000000-0000-0000-0000-000000000007',
      email: 'admin@tiyrasense.gov.in',
      fullName: 'Priya Sharma',
      role: UserRole.admin,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminHomeScreen(user: testUser, authProvider: authProvider),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Users tab
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Ramen Borah'), findsOneWidget);
    expect(find.text('Suspend User'), findsWidgets);

    // Toggle suspension on first user
    await tester.tap(find.text('Suspend User').first);
    await tester.pumpAndSettle();
    expect(find.text('Activate User'), findsWidgets);

    // 2. Switch to Data Health tab
    await tester.tap(find.text('Data Health'));
    await tester.pumpAndSettle();

    expect(find.text('Data Source Health'), findsOneWidget);
    expect(find.text('PostGIS Spatial Engine'), findsOneWidget);
    expect(find.text('Run Ping Test'), findsWidgets);

    // Tap first ping test
    await tester.tap(find.text('Run Ping Test').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 3. Switch to Diagnostics tab
    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('App Working & Performance'), findsOneWidget);
    expect(find.text('SECURITY & RBAC AUDIT TRAIL'), findsOneWidget);
  });

  testWidgets('queues reports offline when disconnected, displays offline badge, and syncs when reconnected', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    offlineStorageService.setOnlineStatus(false);

    // 1. Submit report while offline
    final offlineReport = reportService.addReport(
      hazardType: 'Flash Flood',
      severity: 'FULL BLOCKAGE',
      location: 'NH-06 KM 52.3',
      notes: 'Road submerged under 30cm water near Nongpoh',
      isOffline: true,
    );

    expect(offlineReport.isOfflineQueued, isTrue);
    expect(offlineReport.syncStatus, 'PENDING_SYNC');
    expect(reportService.offlinePendingCount, greaterThan(0));

    // 2. Render ReportHistoryScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify offline badge is visible on the report card
    expect(find.text('OFFLINE QUEUE'), findsWidgets);

    // Verify sync action button is available in the AppBar
    expect(find.byTooltip('Sync Offline Reports'), findsOneWidget);

    // 3. Reconnect to online and sync
    offlineStorageService.setOnlineStatus(true);
    await reportService.syncAllPending();
    expect(offlineReport.syncStatus, 'SYNCED');
    expect(offlineStorageService.pendingCount, 0);
  });

  testWidgets('DriverMapScreen displays autonomous direct GPS banner and functions offline', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    offlineStorageService.setOnlineStatus(false);

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverMapScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Start navigation while offline
    final startNavBtn = find.byIcon(Icons.near_me_rounded);
    expect(startNavBtn, findsOneWidget);
    await tester.tap(startNavBtn);
    await tester.pumpAndSettle();

    // Verify autonomous GPS satellite direct header is displayed
    expect(find.text('🛰️ DIRECT SATELLITE GPS · OFFLINE AUTONOMOUS'), findsOneWidget);
    expect(find.text('OFFLINE GPS'), findsWidgets);

    // Restore online status
    offlineStorageService.setOnlineStatus(true);
    await tester.pump();
    expect(find.text('ASDMA TELEMETRY ONLINE · CORRIDOR LIVE'), findsOneWidget);
  });

  test('ImageCompressorService resamples high-res photo, preserves detail, and respects size thresholds', () async {
    // 1. Create a simulated high-resolution incident photo (2400 x 1600)
    final highRes = img.Image(width: 2400, height: 1600);
    // Draw some high-contrast features (simulating road cracks and sign edges)
    for (int x = 0; x < 2400; x += 20) {
      for (int y = 0; y < 1600; y += 20) {
        highRes.setPixelRgb(x, y, 255, 200, 50);
      }
    }
    final rawLargeJpg = img.encodeJpg(highRes, quality: 95);
    expect(rawLargeJpg.lengthInBytes, greaterThan(20 * 1024));

    // 2. Compress with max dimensions 1600x1200 and quality 82
    final result = await ImageCompressorService.compressBytes(
      rawLargeJpg,
      maxWidth: 1600,
      maxHeight: 1200,
      quality: 82,
      minBytesThreshold: 5 * 1024, // low threshold to force compression
    );

    expect(result.wasCompressed, isTrue);
    expect(result.width, lessThanOrEqualTo(1600));
    expect(result.height, lessThanOrEqualTo(1200));
    // Aspect ratio preserved (2400/1600 = 1.5)
    expect((result.width / result.height).toStringAsFixed(1), '1.5');
    // Substantial size reduction
    expect(result.reductionPercentage, greaterThan(20.0));

    // Structural integrity intact: decoded image is valid and readable
    final decodedCompressed = img.decodeImage(result.bytes);
    expect(decodedCompressed, isNotNull);
    expect(decodedCompressed!.width, result.width);
    expect(decodedCompressed.height, result.height);

    // 3. Test smart threshold: small image should bypass re-compression to prevent generational loss
    final smallResult = await ImageCompressorService.compressBytes(
      result.bytes,
      minBytesThreshold: 5 * 1024 * 1024, // 5MB threshold
    );
    expect(smallResult.wasCompressed, isFalse);
    expect(smallResult.bytes.lengthInBytes, result.bytes.lengthInBytes);
  });

  testWidgets('LiveNotificationCard and Lockscreen Sheet render correctly and allow exiting navigation', (tester) async {
    bool exited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveNotificationCard(
            distanceText: '20 m',
            roadName: 'towards Ramkrishnapur Rd',
            onExitNavigation: () => exited = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify visual components of live notification capsule
    expect(find.text('20 m'), findsOneWidget);
    expect(find.text('towards Ramkrishnapur Rd'), findsOneWidget);
    expect(find.text('Exit navigation'), findsOneWidget);
    expect(find.byType(GoogleMapsPinWidget), findsOneWidget);
    expect(find.byIcon(Icons.turn_right_rounded), findsOneWidget);

    // Verify exit action
    await tester.tap(find.text('Exit navigation'));
    await tester.pump();
    expect(exited, isTrue);

    // Verify integration inside DriverMapScreen
    final fakeApi = FakeApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverMapScreen(apiServiceOverride: fakeApi),
      ),
    );
    await tester.pumpAndSettle();

    // Start navigation
    await tester.tap(find.text('Navigate'));
    await tester.pump();

    // Tap "Live Notice" button in secondary quick controls row
    expect(find.text('Live Notice'), findsOneWidget);
    await tester.tap(find.text('Live Notice'));
    await tester.pumpAndSettle();

    // Verify lockscreen shade view renders carrier, live notifications label, and capsule
    expect(find.text('Jio True5G | Jio'), findsOneWidget);
    expect(find.text('Live notifications'), findsOneWidget);
    expect(find.text('Exit navigation'), findsOneWidget);
    expect(find.byIcon(Icons.turn_right_rounded), findsWidgets);

    // Tap exit navigation inside the lockscreen sheet
    await tester.tap(find.text('Exit navigation'));
    await tester.pumpAndSettle();

    // Navigation stopped and returned to route preview
    expect(find.text('Navigate'), findsOneWidget);
  });

  testWidgets('MapLayerSheet switches map type between Default, Satellite, and Terrain and validates SlippyTileLayer URLs', (tester) async {
    AppMapType activeMapType = AppMapType.road;
    bool activeAlerts = true;
    bool activeIncidents = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                MapLayerSheet.show(
                  context: context,
                  currentMapType: activeMapType,
                  showAlerts: activeAlerts,
                  showIncidents: activeIncidents,
                  onMapTypeChanged: (type) => activeMapType = type,
                  onToggleAlerts: (val) => activeAlerts = val,
                  onToggleIncidents: (val) => activeIncidents = val,
                );
              },
              child: const Text('Open Layers'),
            ),
          ),
        ),
      ),
    );

    // Open layers sheet
    await tester.tap(find.text('Open Layers'));
    await tester.pumpAndSettle();

    expect(find.text('Map type'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Satellite'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Incidents'), findsOneWidget);

    // Tap Satellite
    await tester.tap(find.text('Satellite'));
    await tester.pumpAndSettle();
    expect(activeMapType, AppMapType.satellite);

    // Tap Terrain
    await tester.tap(find.text('Terrain'));
    await tester.pumpAndSettle();
    expect(activeMapType, AppMapType.terrain);

    // Toggle alerts
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(activeAlerts, false);

    // Verify SlippyTileLayer generates authentic Google Maps tile URLs
    expect(SlippyTileLayer.getTileUrl(10, 800, 450, AppMapType.road), contains('google.com/vt/lyrs=m'));
    expect(SlippyTileLayer.getTileUrl(10, 800, 450, AppMapType.satellite), contains('google.com/vt/lyrs=y'));
    expect(SlippyTileLayer.getTileUrl(10, 800, 450, AppMapType.terrain), contains('google.com/vt/lyrs=p'));
  });

  test('SlippyTileLayer latLngToWorld and worldToLatLng inverse projection correctness', () {
    const lat = 26.1445;
    const lng = 91.7362;
    const z = 10;

    final world = SlippyTileLayer.latLngToWorld(lat, lng, z);
    final restored = SlippyTileLayer.worldToLatLng(world.dx, world.dy, z);

    expect((restored.dx - lat).abs(), lessThan(0.001));
    expect((restored.dy - lng).abs(), lessThan(0.001));
  });

  testWidgets('DriverMapScreen has zoom in, zoom out, compass, my location, and fit buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverMapScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 6 action button icons exist
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

    // Test Zoom In
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Test Zoom Out
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();

    // Test Compass North
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Map re-oriented to True North (0°)'), findsOneWidget);

    // Let previous SnackBar dismiss cleanly
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Test Fit Corridor
    await tester.tap(find.byIcon(Icons.center_focus_strong_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Map centered on active corridor'), findsOneWidget);
  });

  testWidgets('FieldWorkerMapScreen has zoom in, zoom out, compass, and fit buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FieldWorkerMapScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all action buttons exist in Field Worker screen
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

    // Tap Zoom In
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Tap Zoom Out
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();

    // Tap Fit Sector
    await tester.tap(find.byIcon(Icons.center_focus_strong_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Corridor overview: Entire patrol sector fitted to view'), findsOneWidget);
  });
}





