import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'driver_home_screen.dart';
import 'field_worker_home_screen.dart';
import 'official_home_screen.dart';
import 'admin_home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const LoginScreen({super.key, required this.authProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = widget.authProvider.currentUser;
      if (user != null) {
        if (user.role == UserRole.driver) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DriverHomeScreen(
                user: user,
                authProvider: widget.authProvider,
              ),
            ),
          );
        } else if (user.role == UserRole.fieldWorker) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => FieldWorkerHomeScreen(
                user: user,
                authProvider: widget.authProvider,
              ),
            ),
          );
        } else if (user.role == UserRole.official) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OfficialHomeScreen(
                user: user,
                authProvider: widget.authProvider,
              ),
            ),
          );
        } else if (user.role == UserRole.admin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AdminHomeScreen(
                user: user,
                authProvider: widget.authProvider,
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.authProvider.errorMessage ?? 'Authentication failed',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppTheme.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Block (Center-aligned)
                  const Center(
                    child: AppLogo.icon(
                      size: 72,
                      radius: 18,
                      glow: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TiyraSense',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textHigh,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'NER Logistics Intelligence',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLow,
                    ),
                  ),
                  const SizedBox(height: 28),


                  // Form Section
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@domain.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.textLow),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter your email';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLow),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textLow,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter your password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // Sign In Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.authProvider.isLoading ? null : _handleLogin,
                      child: widget.authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Text('Sign In'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer: Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New here? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLow,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SignUpScreen(authProviderOverride: widget.authProvider),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
