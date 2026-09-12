import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/auth_provider.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Await initialization and a 2-second hold for brand presentation
    await Future.wait([
      authProvider.initialize(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final role = authProvider.currentUser!.role;
      if (role == UserRole.fieldWorker) {
        Navigator.of(context).pushReplacementNamed('/field-worker-home');
      } else {
        Navigator.of(context).pushReplacementNamed('/driver-home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F8FC),
      body: Center(
        child: AppLogo.splash(size: 96, radius: 22),
      ),
    );
  }
}
