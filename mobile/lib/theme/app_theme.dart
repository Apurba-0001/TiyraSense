import 'package:flutter/material.dart';

class AppTheme {
  // TiyraSense Premium Light Theme Palette
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas Base (Slate 50)
  static const Color surfaceDeep = Color(0xFF0F172A); // Deep Accent / Contrast Element
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure White Surface Card
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevated Surface
  static const Color surfaceContainer = Color(0xFFF1F5F9); // Inner Container (Slate 100)
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0); // Header Container (Slate 200)

  static const Color borderSubtle = Color(0xFFE2E8F0); // Delicate Card Hairline (Slate 200)
  static const Color borderStrong = Color(0xFFCBD5E1); // Defined Boundary (Slate 300)

  static const Color textPrimary = Color(0xFF0F172A); // High-contrast Charcoal/Slate (Slate 900)
  static const Color textSecondary = Color(0xFF475569); // Mid-tier Legible Slate (Slate 600)
  static const Color textMuted = Color(0xFF64748B); // Informational / Muted (Slate 500)

  // Operational Status Colors
  static const Color statusOpen = Color(0xFF10B981); // Emerald (Passable)
  static const Color statusCaution = Color(0xFFF59E0B); // Amber (Caution)
  static const Color statusRestricted = Color(0xFFF97316); // Orange (Axle/Weight limit)
  static const Color statusHighRisk = Color(0xFFDC2626); // Crimson (High Risk)
  static const Color statusBlocked = Color(0xFF991B1B); // Dark Red (Blocked)

  // Telemetry & Interactive Tokens
  static const Color primary = Color(0xFF0284C7); // Primary Action Ocean Blue (Sky 600)
  static const Color primaryDark = Color(0xFF0369A1); // Sky 700
  static const Color primaryLight = Color(0xFFE0F2FE); // Soft Blue Tint (Sky 100)
  static const Color telemetryCyan = Color(0xFF0284C7); // Cyan / Blue Accent
  static const Color secondary = Color(0xFF0284C7);
  static const Color syncActive = Color(0xFF2563EB); // Blue 600

  // Semantic Aliases for Components
  static const Color tacticalNavy = Color(0xFF0F172A);
  static const Color tacticalSlate = Color(0xFF1E293B);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color cardBackground = surfaceCard;
  static const Color surfaceMuted = surfaceContainer;

  // Status mapping aliases
  static const Color success = statusOpen;
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = statusCaution;
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color critical = statusHighRisk;
  static const Color criticalBg = Color(0xFFFEF2F2);
  static const Color info = primary;
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color surface = surfaceCard;
  static const Color border = borderSubtle;

  // Primary Theme is now Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        surface: surfaceCard,
        primary: primary,
        secondary: secondary,
        error: critical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x14000000),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: critical, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: critical, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
