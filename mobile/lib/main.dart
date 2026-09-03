import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
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
      home: LoginScreen(authProvider: authProvider),
    );
  }
}
