import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyrasense_mobile/main.dart';
import 'package:tiyrasense_mobile/models/user_model.dart';
import 'package:tiyrasense_mobile/screens/driver_home_screen.dart';
import 'package:tiyrasense_mobile/screens/field_worker_home_screen.dart';
import 'package:tiyrasense_mobile/screens/login_screen.dart';
import 'package:tiyrasense_mobile/services/api_service.dart';
import 'package:tiyrasense_mobile/state/auth_provider.dart';

class FakeApiService extends ApiService {
  bool shouldFail = false;
  int? failStatusCode = 401;
  String failMessage = 'Invalid email or password';
  UserRole returnRole = UserRole.driver;

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
  });

  testWidgets('renders login screen with TiyraSense branding and fields', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('TiyraSense'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In to TiyraSense'), findsOneWidget);
    expect(find.text('Driver (Ramen)'), findsOneWidget);
    expect(find.text('Field Worker'), findsOneWidget);
  });

  testWidgets('displays validation error when submitting empty fields', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In to TiyraSense'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('quick fill button populates driver email and password', (tester) async {
    final fakeApi = FakeApiService();
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver (Ramen)'));
    await tester.pumpAndSettle();

    expect(find.text('driver@tiyrasense.in'), findsOneWidget);
    expect(find.text('DriverPass2026!'), findsOneWidget);
  });

  testWidgets('successful driver login navigates to DriverHomeScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver (Ramen)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In to TiyraSense'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.text('TiyraSense Driver'), findsOneWidget);
    expect(find.text('Corridor Status: PASSABLE'), findsOneWidget);
  });

  testWidgets('successful field worker login navigates to FieldWorkerHomeScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.fieldWorker;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Field Worker'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In to TiyraSense'));
    await tester.pumpAndSettle();

    expect(find.byType(FieldWorkerHomeScreen), findsOneWidget);
    expect(find.text('Field Worker Console'), findsOneWidget);
    expect(find.text('Report Road Hazard / Blockage'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('authentication error displays error banner', (tester) async {
    final fakeApi = FakeApiService()
      ..shouldFail = true
      ..failMessage = 'Invalid email or password. Please verify credentials.';
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver (Ramen)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In to TiyraSense'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password. Please verify credentials.'), findsOneWidget);
  });

  testWidgets('driver home screen logout button returns to LoginScreen', (tester) async {
    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver (Ramen)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In to TiyraSense'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverHomeScreen), findsOneWidget);

    // Tap logout action
    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('persisted session auto-authenticates into DriverHomeScreen upon app restart', (tester) async {
    final cachedUser = UserModel(
      id: '00000000-0000-0000-0000-000000000001',
      email: 'driver@tiyrasense.in',
      fullName: 'Ramen Driver',
      role: UserRole.driver,
    );

    // Simulate pre-existing credentials in secure storage from a previous session
    FlutterSecureStorage.setMockInitialValues({
      'tiyrasense_auth_token': 'saved_jwt_token_abc123',
      'tiyrasense_user_data': jsonEncode(cachedUser.toJson()),
    });

    final fakeApi = FakeApiService()..returnRole = UserRole.driver;
    final authProvider = AuthProvider(apiService: fakeApi);

    // App cold start initialization
    await authProvider.initialize();

    // App renders
    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    // User is directly on the DriverHomeScreen without having to re-authenticate
    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('TiyraSense Driver'), findsOneWidget);
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

    // Simulate offline network failure (no status code / socket exception)
    final offlineApi = FakeApiService()
      ..shouldFail = true
      ..failStatusCode = null
      ..failMessage = 'SocketException: Network unreachable';
    final authProvider = AuthProvider(apiService: offlineApi);

    await authProvider.initialize();

    await tester.pumpWidget(TiyraSenseApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    // Field worker should STILL be logged in thanks to offline cache
    expect(find.byType(FieldWorkerHomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('authoritative 401 expired token on launch wipes session and routes to LoginScreen', (tester) async {
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

    // Token was rejected with 401, so user lands back on LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DriverHomeScreen), findsNothing);
  });
}
