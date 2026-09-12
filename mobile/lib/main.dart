import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/driver_home_screen.dart';
import 'screens/field_worker_home_screen.dart';
import 'screens/official_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = authProvider;
  await provider.initialize();
  await localizationService.initialize();
  await NotificationService().initialize();
  runApp(TiyraSenseApp(authProvider: provider));
}

class TiyraSenseApp extends StatelessWidget {
  final AuthProvider authProvider;

  const TiyraSenseApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localizationService, authProvider]),
      builder: (context, _) {
        return MaterialApp(
          title: 'TiyraSense',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _resolveStartScreen(authProvider),
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => LoginScreen(authProvider: authProvider),
            '/signup': (_) => SignUpScreen(authProviderOverride: authProvider),
            '/driver-home': (_) {
              final user = authProvider.currentUser;
              if (authProvider.isAuthenticated && user != null && user.role == UserRole.driver) {
                return DriverHomeScreen(user: user, authProvider: authProvider);
              }
              return LoginScreen(authProvider: authProvider);
            },
            '/field-worker-home': (_) {
              final user = authProvider.currentUser;
              if (authProvider.isAuthenticated && user != null && user.role == UserRole.fieldWorker) {
                return FieldWorkerHomeScreen(user: user, authProvider: authProvider);
              }
              return LoginScreen(authProvider: authProvider);
            },
            '/official-home': (_) {
              final user = authProvider.currentUser;
              if (authProvider.isAuthenticated && user != null && user.role == UserRole.official) {
                return OfficialHomeScreen(user: user, authProvider: authProvider);
              }
              return LoginScreen(authProvider: authProvider);
            },
            '/admin-home': (_) {
              final user = authProvider.currentUser;
              if (authProvider.isAuthenticated && user != null && user.role == UserRole.admin) {
                return AdminHomeScreen(user: user, authProvider: authProvider);
              }
              return LoginScreen(authProvider: authProvider);
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
