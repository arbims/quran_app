import 'package:flutter/material.dart';

/// Palette alignée sur l’ancienne appli (barres navy + motif géométrique).
class AppColors {
  AppColors._();

  /// Fond des menus haut / bas — extrait de `demo.jpg` (RGB 43,93,182).
  static const Color headerBlue = Color(0xFF2B5DB6);
  static const Color headerBlueDark = Color(0xFF234A92);

  /// Texte / icônes sur les barres.
  static const Color chromeForeground = Color(0xFFFFFFFF);
  static const Color chromeForegroundMuted = Color(0xD9FFFFFF);

  static const Color pageBackground = Color(0xFFF2F2F2);
  static const Color sliderGold = Color(0xFFD4A017);
  static const Color sliderTrack = Color(0xFF5B7FB8);
  static const Color fabBlue = Color(0xFF7EB8E8);

  /// Maquette `fahras.jpg`
  static const Color fahrasBackground = Color(0xFFF5F0E8);
  static const Color fahrasTabTrack = Color(0xFFFFFFFF);
  static const Color fahrasTabSelected = Color(0xFFC5D9F2);
  static const Color fahrasSearchFill = Color(0xFFFFFFFF);
  static const Color fahrasPageBadge = Color(0xFFE6E6E6);
  static const Color fahrasDivider = Color(0xFFD8D8D8);
}
