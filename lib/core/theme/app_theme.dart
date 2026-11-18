import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.pageBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.headerBlue,
        onPrimary: Colors.white,
        surface: AppColors.pageBackground,
        onSurface: Colors.black87,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.sliderTrack,
        inactiveTrackColor: AppColors.sliderTrack.withValues(alpha: 0.45),
        thumbColor: AppColors.sliderGold,
        overlayColor: AppColors.sliderGold.withValues(alpha: 0.2),
      ),
    );
  }

  static ThemeData warm() {
    const warmBg = Color(0xFFFDF8EE);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.headerBlue,
        onPrimary: Colors.white,
        surface: warmBg,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.headerBlue,
        onPrimary: Colors.white,
      ),
    );
  }
}
