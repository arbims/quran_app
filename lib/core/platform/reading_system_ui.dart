import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Style des barres **système** (heure, batterie, boutons Android), pas l’UI de l’app.
SystemUiOverlayStyle readingSystemUi({
  required bool menusVisible,
  required Color mushafBackground,
}) {
  if (menusVisible) {
    return const SystemUiOverlayStyle(
      statusBarColor: AppColors.headerBlue,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.headerBlue,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );
  }

  final darkBg = mushafBackground.computeLuminance() < 0.5;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: darkBg ? Brightness.light : Brightness.dark,
    statusBarBrightness: darkBg ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: mushafBackground,
    systemNavigationBarIconBrightness: darkBg ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
