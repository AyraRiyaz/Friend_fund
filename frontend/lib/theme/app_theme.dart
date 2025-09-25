import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern, sophisticated dark violet color palette
  static const Color primaryViolet = Color(0xFF6B21A8); // Main brand color - deep violet
  static const Color secondaryViolet = Color(0xFF8B5CF6); // Lighter violet for accents
  static const Color accentViolet = Color(0xFF581C87); // Deeper violet for emphasis
  static const Color lightViolet = Color(0xFFF3E8FF); // Very light violet for backgrounds
  static const Color backgroundLight = Color(0xFFFAF7FF); // Main background with violet tint
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Card surfaces
  static const Color surfaceElevated = Color(0xFFFEFEFE); // Elevated surfaces
  static const Color textPrimary = Color(0xFF1E1B4B); // Primary text with violet tint
  static const Color textSecondary = Color(0xFF64748B); // Secondary text
  static const Color textTertiary = Color(0xFF94A3B8); // Tertiary text
  static const Color success = Color(0xFF10B981); // Success green
  static const Color successLight = Color(0xFFD1FAE5); // Light success
  static const Color warning = Color(0xFFF59E0B); // Warning orange
  static const Color warningLight = Color(0xFFFEF3C7); // Light warning
  static const Color error = Color(0xFFEF4444); // Error red
  static const Color errorLight = Color(0xFFFEE2E2); // Light error
  static const Color info = Color(0xFF06B6D4); // Info cyan
  static const Color infoLight = Color(0xFFCFFAFE); // Light info
  
  // Gradient colors
  static const List<Color> primaryGradient = [primaryViolet, secondaryViolet];
  static const List<Color> successGradient = [success, Color(0xFF34D399)];
  static const List<Color> warningGradient = [warning, Color(0xFFFBBF24)];
  static const List<Color> errorGradient = [error, Color(0xFFF87171)];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryViolet,
      secondary: secondaryViolet,
      surface: surfaceWhite,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
      surfaceContainerHighest: surfaceElevated,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.1,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: -0.1,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.1,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: surfaceWhite,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: surfaceWhite,
      foregroundColor: primaryViolet,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryViolet,
        letterSpacing: -0.25,
      ),
      iconTheme: const IconThemeData(color: primaryViolet, size: 24),
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.1,
        ),
        surfaceTintColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryViolet,
        side: BorderSide(color: primaryViolet.withValues(alpha: 0.3), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.1,
        ),
        surfaceTintColor: Colors.transparent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryViolet,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryViolet,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
      helperStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: error,
      ),
    ),
  );

  // Custom shadow definitions for consistent elevation
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Gradient decorations
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  );

  static BoxDecoration get successGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: successGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  );

  static BoxDecoration get warningGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: warningGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  );

  static BoxDecoration get errorGradientDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: errorGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  );

  // Card decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.grey.withValues(alpha: 0.08),
      width: 1,
    ),
    boxShadow: cardShadow,
  );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: primaryViolet.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: cardShadowHover,
  );

  // Status chip decorations
  static BoxDecoration getStatusChipDecoration(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BoxDecoration(
          color: successLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: success.withValues(alpha: 0.2)),
        );
      case 'closed':
        return BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        );
      case 'paused':
      case 'inactive':
        return BoxDecoration(
          color: warningLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: warning.withValues(alpha: 0.2)),
        );
      default:
        return BoxDecoration(
          color: lightViolet,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryViolet.withValues(alpha: 0.2)),
        );
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return success;
      case 'closed':
        return Colors.grey;
      case 'paused':
      case 'inactive':
        return warning;
      default:
        return primaryViolet;
    }
  }
}
