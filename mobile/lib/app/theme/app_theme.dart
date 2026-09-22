import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Spacing System
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
}

/// Centralized Corner Radius System
class AppRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double button = 14.0;
  static const double md = 16.0;
  static const double card = 18.0;
  static const double panel = 22.0;
  static const double sheet = 26.0;
  static const double full = 999.0;

  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get buttonRadius => BorderRadius.circular(button);
  static BorderRadius get panelRadius => BorderRadius.circular(panel);
  static BorderRadius get sheetRadius => const BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Centralized Micro-Shadows
class AppShadows {
  static List<BoxShadow> card({bool isDark = false}) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(6),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ];

  static List<BoxShadow> floating({bool isDark = false}) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(18),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ];

  static List<BoxShadow> subtle({bool isDark = false}) => card(isDark: isDark);

  static List<BoxShadow> primaryButton(Color color) => [
        BoxShadow(
          color: color.withAlpha(65),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  // Brand Color Palette
  static const Color primaryColor = Color(0xFF1E40AF); // Royal Sapphire
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Blue
  static const Color secondaryColor = Color(0xFF0D9488); // Teal
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color teal = Color(0xFF0D9488);
  static const Color indigo = Color(0xFF6366F1);
  static const Color purple = Color(0xFF8B5CF6);

  // Light Mode Surfaces & Neutrals
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400

  // Dark Mode Surfaces & Neutrals
  static const Color darkBg = Color(0xFF0B0F19); // Obsidian Slate
  static const Color darkSurface = Color(0xFF111827); // Dark Surface
  static const Color darkCard = Color(0xFF131C2E); // Deep Card Slate
  static const Color darkBorder = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextTertiary = Color(0xFF64748B); // Slate 500

  // Backward compatibility aliases
  static const Color backgroundColor = lightBg;
  static const Color surfaceColor = lightSurface;
  static const Color cardColor = lightCard;
  static const Color borderColor = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;

  // Context-aware dynamic accessors
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color cardBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;

  static Color borderColorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color surfaceColorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  // Semantic Colors (Restrained)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Builds Modern Light Theme
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        scaffoldBg: lightBg,
        surface: lightSurface,
        cardBg: lightCard,
        border: lightBorder,
        textPrimary: lightTextPrimary,
        textSecondary: lightTextSecondary,
        primary: primaryColor,
        isDark: false,
      );

  /// Builds Luxury Dark Theme
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        scaffoldBg: darkBg,
        surface: darkSurface,
        cardBg: darkCard,
        border: darkBorder,
        textPrimary: darkTextPrimary,
        textSecondary: darkTextSecondary,
        primary: primaryLight,
        isDark: true,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
    required bool isDark,
  }) {
    final baseTextTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF161F33) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: TextStyle(color: textSecondary.withAlpha(180), fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 20,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: border),
        backgroundColor: isDark ? darkCard : Colors.white,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get textSecondary => isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get textTertiary => isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary;
  Color get cardBg => isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get border => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
}

