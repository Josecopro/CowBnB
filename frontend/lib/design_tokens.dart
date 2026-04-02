import 'package:flutter/material.dart';

/// Design System - Color Tokens
class AppColors {
  static const primary = Color(0xFF5CA275);
  static const primaryDark = Color(0xFF4A8A62);
  static const primaryLight = Color(0xFF7BBF93);

  static const secondary = Color(0xFF577763);

  static const success = Color(0xFF51CC7F);
  static const error = Color(0xFFD64545);
  static const warning = Color(0xFFE6A23C);

  static const textPrimary = Color(0xFF454D48);
  static const textSecondary = Color(0xFF8A918D);
  static const border = Color(0xFFDADDD9);

  static const surface = Color(0xFFFAFAF9);
  static const surfaceContainer = Color(0xFFF2F2F0);
  static const surfaceContainerLow = Color(0xFFF7F7F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);

  static const darkBg = Color(0xFF1D3325);
  static const darkBgVariant = Color(0xFF111e16);
}

/// Design System - Spacing Tokens (8pt grid)
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Design System - Radius Tokens
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Design System - Typography
class AppTextStyles {
  static const headline = TextStyle(
    fontFamily: 'Headline',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const headlineLarge = TextStyle(
    fontFamily: 'Headline',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const headlineSmall = TextStyle(
    fontFamily: 'Headline',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: 'Body',
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Body',
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontFamily: 'Headline',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Headline',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

/// Build App Theme
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.headlineLarge,
      headlineSmall: AppTextStyles.headlineSmall,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySmall,
      labelMedium: AppTextStyles.label,
      labelSmall: AppTextStyles.labelSmall,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headline.copyWith(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
  );
}
