import 'package:flutter/material.dart';

/// Modes de lecture du mushaf (maquettes `1346` / `1347` / `1348`).
///
/// - [normal] عادي — page blanche d’origine
/// - [warm] دافئ — papier crème / sépia
/// - [night] ليلي — page inversée sur fond noir
enum PageAppearance {
  normal,
  warm,
  night,
}

extension PageAppearanceStorage on PageAppearance {
  String get storageKey => name;

  static PageAppearance fromStorage(String? value) {
    return PageAppearance.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PageAppearance.normal,
    );
  }
}

extension PageAppearanceVisual on PageAppearance {
  /// Fond derrière / autour de la page mushaf.
  Color get mushafBackground => switch (this) {
        PageAppearance.normal => const Color(0xFF2A2A2A),
        PageAppearance.warm => const Color(0xFF3A3228),
        PageAppearance.night => const Color(0xFF0D0D0D),
      };

  /// Filtre appliqué à l’image de page (null = aucun).
  ColorFilter? get mushafColorFilter => switch (this) {
        PageAppearance.normal => null,
        PageAppearance.warm => const ColorFilter.matrix(_warmMatrix),
        PageAppearance.night => const ColorFilter.matrix(_nightMatrix),
      };

  /// Teinte papier crème (approx. RGB 243,233,209 sur fond blanc).
  static const List<double> _warmMatrix = <double>[
    0.953, 0.000, 0.000, 0, 0,
    0.000, 0.914, 0.000, 0, 0,
    0.000, 0.000, 0.820, 0, 0,
    0.000, 0.000, 0.000, 1, 0,
  ];

  /// Inversion douce (papier sombre, encre claire) — mode nuit.
  static const List<double> _nightMatrix = <double>[
    -1.0, 0.0, 0.0, 0, 255,
    0.0, -0.96, 0.0, 0, 245,
    0.0, 0.0, -0.90, 0, 230,
    0.0, 0.0, 0.0, 1, 0,
  ];
}
