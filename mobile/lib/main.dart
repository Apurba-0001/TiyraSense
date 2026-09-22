import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/driver_home_screen.dart';
import 'screens/field_worker_home_screen.dart';
import 'screens/official_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/offline_storage_service.dart';
import 'services/report_service.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  final provider = authProvider;
  await provider.initialize();
  await localizationService.initialize();
  await NotificationService().initialize();
  runApp(TiyraSenseApp(authProvider: provider));
}

class TiyraSenseApp extends StatefulWidget {
  final AuthProvider authProvider;

  const TiyraSenseApp({super.key, required this.authProvider});

  @override
  State<TiyraSenseApp> createState() => _TiyraSenseAppState();
}

class _TiyraSenseAppState extends State<TiyraSenseApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      offlineStorageService.autoSync();
      reportService.syncLiveReports().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localizationService, widget.authProvider]),
      builder: (context, _) {
        return MaterialApp(
          title: 'TiyraSense',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _resolveStartScreen(widget.authProvider),
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => LoginScreen(authProvider: widget.authProvider),
            '/signup': (_) => SignUpScreen(authProviderOverride: widget.authProvider),
            '/driver-home': (_) {
              final user = widget.authProvider.currentUser;
              if (widget.authProvider.isAuthenticated && user != null && user.role == UserRole.driver) {
                return DriverHomeScreen(user: user, authProvider: widget.authProvider);
              }
              return LoginScreen(authProvider: widget.authProvider);
            },
            '/field-worker-home': (_) {
              final user = widget.authProvider.currentUser;
              if (widget.authProvider.isAuthenticated && user != null && user.role == UserRole.fieldWorker) {
                return FieldWorkerHomeScreen(user: user, authProvider: widget.authProvider);
              }
              return LoginScreen(authProvider: widget.authProvider);
            },
            '/official-home': (_) {
              final user = widget.authProvider.currentUser;
              if (widget.authProvider.isAuthenticated && user != null && user.role == UserRole.official) {
                return OfficialHomeScreen(user: user, authProvider: widget.authProvider);
              }
              return LoginScreen(authProvider: widget.authProvider);
            },
            '/admin-home': (_) {
              final user = widget.authProvider.currentUser;
              if (widget.authProvider.isAuthenticated && user != null && user.role == UserRole.admin) {
                return AdminHomeScreen(user: user, authProvider: widget.authProvider);
              }
              return LoginScreen(authProvider: widget.authProvider);
            },
          },
        );
      },
    );
  }

  static Widget _resolveStartScreen(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return LoginScreen(authProvider: authProvider);
    }

    final user = authProvider.currentUser;
    if (user == null) {
      return LoginScreen(authProvider: authProvider);
    }

    return switch (user.role) {
      UserRole.driver => DriverHomeScreen(user: user, authProvider: authProvider),
      UserRole.fieldWorker => FieldWorkerHomeScreen(user: user, authProvider: authProvider),
      UserRole.official => OfficialHomeScreen(user: user, authProvider: authProvider),
      UserRole.admin => AdminHomeScreen(user: user, authProvider: authProvider),
    };
  }
}
