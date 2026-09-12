import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Brand & Logo component implementing the official TiyraSense assets.
///
/// Uses the existing project assets without generating new ones:
/// - `assets/images/splash_logo.png` (Official splash emblem)
/// - `assets/icon/app_icon.png` (Official app icon emblem)
/// - `assets/images/logo.png` (Official horizontal brand logo with wordmark)
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  final bool glow;
  final bool isSplash;
  final bool isHorizontal;
  final double? height;

  const AppLogo.icon({
    super.key,
    this.size = 36,
    this.radius = 9,
    this.glow = false,
  })  : isSplash = false,
        isHorizontal = false,
        height = null;

  const AppLogo.splash({
    super.key,
    this.size = 96,
    this.radius = 22,
  })  : glow = true,
        isSplash = true,
        isHorizontal = false,
        height = null;

  const AppLogo.horizontal({
    super.key,
    this.height = 36,
  })  : size = 0,
        radius = 0,
        glow = false,
        isSplash = false,
        isHorizontal = true;

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Image.asset(
        'assets/images/logo.png',
        height: height ?? 36,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(
          'assets/icon/app_icon.png',
          height: height ?? 36,
          fit: BoxFit.contain,
        ),
      );
    }

    final assetPath = isSplash
        ? 'assets/images/splash_logo.png'
        : 'assets/icon/app_icon.png';
    final fallbackPath = isSplash
        ? 'assets/icon/app_icon.png'
        : 'assets/images/splash_logo.png';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? AppTheme.iconGlow
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
