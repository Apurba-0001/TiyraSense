import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/driver_home_screen.dart';
import 'screens/field_worker_home_screen.dart';
import 'screens/login_screen.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  // Restore session from secure storage before the first frame is drawn.
  // Users who were previously logged in are taken directly to their home
  // screen; only unauthenticated users see the login screen.
  await authProvider.initialize();
  runApp(TiyraSenseApp(authProvider: authProvider));
}

class TiyraSenseApp extends StatelessWidget {
  final AuthProvider authProvider;

  const TiyraSenseApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TiyraSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveStartScreen(authProvider),
    );
  }

  /// Returns the correct starting screen based on persisted auth state.
  ///
  /// Called once after [AuthProvider.initialize] completes, so [isAuthenticated]
  /// already reflects the restored session (if any).
  static Widget _resolveStartScreen(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return LoginScreen(authProvider: authProvider);
    }

    final user = authProvider.currentUser!;
    return switch (user.role) {
      UserRole.driver => DriverHomeScreen(user: user, authProvider: authProvider),
      UserRole.fieldWorker => FieldWorkerHomeScreen(user: user, authProvider: authProvider),
      // Official / Admin accounts belong on the Web Dashboard.
      // Show login so they can read the redirect message.
      _ => LoginScreen(authProvider: authProvider),
    };
  }
}
