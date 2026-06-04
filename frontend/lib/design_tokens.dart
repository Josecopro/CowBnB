import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF1F6F6F);
  static const primaryHover = Color(0xFF1A5F5F);
  static const primarySoft = Color(0xFFE8F4F4);
  static const primaryInk = Color(0xFF0F4F4F);

  static const accent = Color(0xFFC8862D);
  static const accentHover = Color(0xFFB5761F);
  static const accentSoft = Color(0xFFF8EFDC);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFF8FAFA);
  static const surfaceContainerLow = Color(0xFFFBFCFC);
  static const surfaceSunken = Color(0xFFF0F4F4);

  static const ink = Color(0xFF15211F);
  static const inkMuted = Color(0xFF5A6B68);
  static const inkSoft = Color(0xFF6B7674);

  static const border = Color(0xFFDDE4E2);
  static const borderSoft = Color(0xFFEAEFEE);

  static const success = Color(0xFF2D8059);
  static const warning = Color(0xFF8C5E10);
  static const danger = Color(0xFFC04141);
  static const info = Color(0xFF3870B5);

  static const onPrimary = Color(0xFFFFFFFF);
  static const onAccent = Color(0xFF231D14);
  static const onDark = Color(0xFFFAFAFA);

  static const darkBg = Color(0xFF1A2E2C);
  static const darkBgDeep = Color(0xFF0F1F1D);

  static const shadowBase = Color(0x331C2E2C);

  static const primaryDark = primaryHover;
  static const primaryLight = primarySoft;
  static const secondary = primaryInk;
  static const error = danger;

  static const textPrimary = ink;
  static const textSecondary = inkMuted;
  static const surfaceContainerLowest = surface;
  static const darkBgVariant = darkBgDeep;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

class AppShadows {
  static const lift1 = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBase,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  static const lift2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x14202826),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  static const lift3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F202826),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];
  static const overlay = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A202826),
      blurRadius: 1,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x29202826),
      blurRadius: 64,
      offset: Offset(0, 24),
    ),
  ];
}

class AppTextStyles {
  static TextStyle get display => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -0.6,
        color: AppColors.ink,
      );

  static TextStyle get headlineLarge => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get headline => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.ink,
      );

  static TextStyle get headlineSmall => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.ink,
      );

  static TextStyle get title => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.ink,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.ink,
      );

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      );

  static TextStyle get labelSmall => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: AppColors.inkMuted,
      );
}

TextStyle _manropeStyle({
  required double fontSize,
  required FontWeight fontWeight,
  required double height,
  double letterSpacing = 0,
  required Color color,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.surfaceContainer,
    ),
    scaffoldBackgroundColor: AppColors.surface,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: _manropeStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),
      displayMedium: _manropeStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      displaySmall: _manropeStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      headlineLarge: _manropeStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      headlineMedium: _manropeStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      headlineSmall: _manropeStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.ink,
      ),
      titleLarge: _manropeStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.ink,
      ),
      titleMedium: _manropeStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      ),
      bodyLarge: _manropeStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.ink,
      ),
      bodyMedium: _manropeStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.ink,
      ),
      bodySmall: _manropeStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.inkMuted,
      ),
      labelLarge: _manropeStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      ),
      labelMedium: _manropeStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      ),
      labelSmall: _manropeStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: AppColors.inkMuted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.onDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerColor: AppColors.borderSoft,
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSoft,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
    splashFactory: InkSparkle.splashFactory,
  );
}
