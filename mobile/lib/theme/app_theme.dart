import 'package:flutter/material.dart';

class AppTheme {
  // Canvas & Surfaces (Section 1)
  static const Color canvas = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color container = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderMed = Color(0xFFCBD5E1); // Slate 300

  // Text Hierarchy
  static const Color textHigh = Color(0xFF0F172A); // Slate 900
  static const Color textMid = Color(0xFF475569); // Slate 600
  static const Color textLow = Color(0xFF64748B); // Slate 500

  // Primary & Interactive Brand Tokens
  static const Color primaryBlue = Color(0xFF0284C7); // Sky 600
  static const Color blueLight = Color(0xFFE0F2FE); // Sky 100
  static const Color blueDark = Color(0xFF0369A1); // Sky 700

  // Operational State Spectrum
  static const Color green = Color(0xFF10B981); // Passable / Online / Synced (Emerald 500)
  static const Color amber = Color(0xFFF59E0B); // Caution / Warning (Amber 500)
  static const Color orange = Color(0xFFF97316); // Restricted access (Orange 500)
  static const Color red = Color(0xFFDC2626); // High risk / Critical (Red 600)
  static const Color darkRed = Color(0xFF991B1B); // Blocked / Emergency (Red 800)

  // Surface Tints
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color blueBg = Color(0xFFF0F9FF);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> activeShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> navShadow = [
    BoxShadow(color: Color(0xFFE2E8F0), offset: Offset(0, -1)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, -8)),
  ];
  static const List<BoxShadow> iconGlow = [
    BoxShadow(color: Color(0x2E0284C7), blurRadius: 32, offset: Offset(0, 8)),
  ];

  // Radii
  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusChip = 20.0;
  static const double radiusSheet = 24.0;

  // Backward compatibility aliases
  static const Color background = canvas;
  static const Color surfaceCard = surface;
  static const Color surfaceContainer = container;
  static const Color borderSubtle = borderLight;
  static const Color borderStrong = borderMed;
  static const Color textPrimary = textHigh;
  static const Color textSecondary = textMid;
  static const Color textMuted = textLow;
  static const Color primary = primaryBlue;
  static const Color primaryLightTint = blueLight;
  static const Color statusOpen = green;
  static const Color statusCaution = amber;
  static const Color statusRestricted = orange;
  static const Color statusHighRisk = red;
  static const Color statusBlocked = darkRed;
  static const Color success = green;
  static const Color successBg = greenBg;
  static const Color warning = amber;
  static const Color warningBg = amberBg;
  static const Color critical = red;
  static const Color criticalBg = redBg;
  static const Color info = primaryBlue;
  static const Color infoBg = blueBg;
  static const Color cardBackground = surface;
  static const Color border = borderLight;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        surface: surface,
        primary: primaryBlue,
        secondary: primaryBlue,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textHigh,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textMid, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textLow, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

