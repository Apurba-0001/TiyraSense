import 'package:flutter/material.dart';

/// Centralized Responsive Breakpoints and Adaptive Layout Utilities for TiyraSense.
///
/// Designed to support:
/// - Ultra-compact phones (width < 360)
/// - Standard & large smartphones (width 360..599)
/// - Tablets and foldables (width 600..1023)
/// - Desktop and wide displays (width >= 1024)
/// - Portrait and landscape orientations
/// - Accessibility text scaling
class Responsive {
  Responsive._();

  // Breakpoint constants
  static const double compactWidth = 360.0;
  static const double tabletWidth = 600.0;
  static const double desktopWidth = 1024.0;
  static const double maxContentWidthDefault = 640.0;
  static const double maxDialogWidthDefault = 480.0;

  /// Returns true if the screen width is smaller than 360 logical pixels.
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compactWidth;
  }

  /// Returns true if the screen width is between 0 and 599 logical pixels.
  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < tabletWidth;
  }

  /// Returns true if the screen width is 600 logical pixels or greater.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletWidth;
  }

  /// Returns true if the screen width is 1024 logical pixels or greater.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopWidth;
  }

  /// Returns true if device is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Returns true if screen height is constrained (< 600 logical pixels), common in landscape mode.
  static bool isShortScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 600.0;
  }

  /// Returns dynamic horizontal padding appropriate for the screen size.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactWidth) return 12.0;
    if (width < tabletWidth) return 16.0;
    if (width < desktopWidth) return 24.0;
    return 32.0;
  }

  /// Computes adaptive grid column count based on available width.
  static int gridColumns(
    BuildContext context, {
    int compact = 2,
    int phone = 2,
    int tablet = 4,
    int desktop = 4,
    int? defaultCols,
    int? tabletCols,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactWidth) return compact;
    if (width < tabletWidth) return defaultCols ?? phone;
    if (width < desktopWidth) return tabletCols ?? tablet;
    return desktop;
  }

  /// Computes adaptive bottom sheet height ratio.
  static double sheetHeightRatio(BuildContext context, {double defaultRatio = 0.85}) {
    if (isLandscape(context) || isShortScreen(context)) {
      return 0.94;
    }
    return defaultRatio;
  }

  /// Clamps text scale factor to maintain readability while preventing broken layouts.
  static double clampedTextScale(BuildContext context, {double maxScale = 1.35}) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return scale.clamp(0.85, maxScale);
  }
}

/// A responsive container that centers content and enforces maximum width constraints on tablets & desktops.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidthDefault,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: Responsive.horizontalPadding(context),
      vertical: 12.0,
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

/// A responsive dialog wrapper that enforces max width and vertical scrollability.
class ResponsiveDialogWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveDialogWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxDialogWidthDefault,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxH,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: child,
        ),
      ),
    );
  }
}
