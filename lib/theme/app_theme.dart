import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System & Theme untuk LaundryKu
/// Menggunakan konsep Blue Professional Trust Theme dengan dukungan Dark Mode.
class AppTheme {
  AppTheme._();

  // ─── LIGHT PALETTE ──────────────────────────────────────────────────
  static const Color lightPrimary = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color lightPrimaryVariant = Color(0xFF2563EB); // Royal Blue
  static const Color lightAccent = Color(0xFF38BDF8); // Sky Blue (badge/accent)
  static const Color lightCta = Color(0xFFF97316); // Warm Orange (CTA/FAB)
  static const Color lightBackground = Color(0xFFF1F5F9); // Cool Neutral Slate 100
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Card
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Border Slate 200
  static const Color lightInputFill = Color(0xFFF8FAFC); // Slate 50
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextHint = Color(0xFF94A3B8); // Slate 400
  static const Color lightShadow = Color(0x0F1E3A8A); // Navy shadow @ 6%

  // ─── DARK PALETTE ───────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A); // Deep Slate Navy
  static const Color darkSurface = Color(0xFF1E293B); // Slate Card 800
  static const Color darkPrimary = Color(0xFF38BDF8); // Sky Blue (kontras di dark)
  static const Color darkPrimaryVariant = Color(0xFF60A5FA); // Blue 400
  static const Color darkAccent = Color(0xFF38BDF8); // Sky Blue
  static const Color darkCta = Color(0xFFFB923C); // Warm Orange 400 (pop di dark)
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkInputFill = Color(0xFF0F172A); // Darker Slate 900
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Off-White Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextHint = Color(0xFF64748B); // Slate 500
  static const Color darkShadow = Color(0x00000000); // No shadow, gunakan surface

  // ─── SEMANTIC STATUS PALETTE ────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF10B981); // Emerald
  static const Color statusWarning = Color(0xFFF59E0B); // Amber
  static const Color statusError = Color(0xFFEF4444); // Red
  static const Color statusInfo = Color(0xFF0EA5E9); // Ocean Blue

  // ─── CRAFTED RADII ──────────────────────────────────────────────────
  static const double radiusSmall = 8.0; // Chips, badges, tag
  static const double radiusMedium = 12.0; // Inputs, form fields, small buttons
  static const double radiusLarge = 18.0; // Regular cards, dialogs
  static const double radiusXL = 24.0; // Hero banner, carousel card, bottom sheets

  // ─── SPACING CONSTANTS ──────────────────────────────────────────────
  static const double spacingExtraSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXL = 32.0;

  // ─── SIGNATURE ACCENT BAR ───────────────────────────────────────────
  static const double signatureAccentWidth = 3.5;
  static const Color signatureAccentColor = Color(0xFF38BDF8);

  // ─── HELPERS CONTEXT AWARE ──────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color ctaColor(BuildContext context) =>
      isDark(context) ? darkCta : lightCta;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color signatureColor(BuildContext context) =>
      isDark(context) ? darkAccent : lightAccent;

  // ─── LIGHT THEME ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        primaryContainer: Color(0xFFDBEAFE), // Blue 100
        secondary: lightAccent,
        secondaryContainer: Color(0xFFE0F2FE), // Sky 100
        tertiary: lightCta,
        surface: lightSurface,
        error: statusError,
        onPrimary: Colors.white,
        onSecondary: lightTextPrimary,
        onSurface: lightTextPrimary,
        onError: Colors.white,
        outline: lightBorder,
      ),

      // Typography Hierarchy (Plus Jakarta Sans for Headings, Inter for Body)
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTheme.displayLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: headingTheme.displayMedium?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        headlineLarge: headingTheme.headlineLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: headingTheme.headlineMedium?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: headingTheme.headlineSmall?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: headingTheme.titleLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: headingTheme.titleMedium?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: headingTheme.titleSmall?.copyWith(
          color: lightTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: lightTextPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: lightTextSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: lightTextHint,
          fontSize: 12,
          height: 1.35,
        ),
        labelLarge: headingTheme.labelLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: lightTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: lightTextHint,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Card Theme (Varied radius 18dp, subtle navy shadow + border)
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shadowColor: lightShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Elevated Button (Primary Brand Action)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: const BorderSide(color: lightBorder, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimaryVariant,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightPrimaryVariant, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusError, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: lightTextHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: lightTextSecondary,
          fontSize: 14,
        ),
      ),

      // Floating Action Button (Warm Orange CTA)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightCta,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFF1F5F9),
        selectedColor: Color(0xFFE0F2FE),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── DARK THEME ─────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final headingTheme =
        GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary, // Sky Blue on dark
        primaryContainer: Color(0xFF1E3A8A), // Navy 900
        secondary: darkAccent,
        secondaryContainer: Color(0xFF0369A1), // Sky 700
        tertiary: darkCta, // Warm Orange 400
        surface: darkSurface,
        error: statusError,
        onPrimary: Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onSurface: darkTextPrimary,
        onError: Colors.white,
        outline: darkBorder,
      ),

      // Typography Hierarchy Dark Mode
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTheme.displayLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: headingTheme.displayMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        headlineLarge: headingTheme.headlineLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: headingTheme.headlineMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: headingTheme.headlineSmall?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: headingTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: headingTheme.titleMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: headingTheme.titleSmall?.copyWith(
          color: darkTextSecondary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: darkTextHint,
          fontSize: 12,
          height: 1.35,
        ),
        labelLarge: headingTheme.labelLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: darkTextHint,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar Dark Mode (Slate Navy)
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),

      // Card Theme Dark Mode (Slate 800 + Slate 700 Border)
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Elevated Button Dark Mode (Sky Blue with dark text for high readability)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined Button Dark Mode
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: const BorderSide(color: darkBorder, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Dark Mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Dark Mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusError, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: darkTextHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),

      // Floating Action Button Dark Mode
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkCta,
        foregroundColor: Color(0xFF0F172A),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Divider Dark Mode
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Chip Dark Mode
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedColor: Color(0xFF0284C7),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      // Snackbar Dark Mode
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
