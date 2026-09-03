import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiyrasense_mobile/main.dart';
import 'package:tiyrasense_mobile/models/user_model.dart';
import 'package:tiyrasense_mobile/screens/driver_home_screen.dart';
import 'package:tiyrasense_mobile/screens/field_worker_home_screen.dart';
import 'package:tiyrasense_mobile/screens/login_screen.dart';
import 'package:tiyrasense_mobile/services/api_service.dart';
import 'package:tiyrasense_mobile/state/auth_provider.dart';

class FakeApiService extends ApiService {
  bool shouldFail = false;
  String failMessage = 'Invalid email or password';
  UserRole returnRole = UserRole.driver;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (shouldFail) {
      throw ApiException(failMessage, 401);
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
    return UserModel(
      id: '00000000-0000-0000-0000-000000000001',
      email: 'test@tiyrasense.in',
      fullName: 'Test User',
      role: returnRole,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
}
