import 'package:flutter/painting.dart';

import '../../../core/constants/mushaf_page_image_crop.dart';

/// Calage `word_data` (2481×3509, page complète) → pixels du WebP **déjà recadré**.
///
/// Les coordonnées mots sont relatives au scan source (équivalent 1900×2687).
/// Les images affichées ont perdu les marges de [MushafPageImageCrop]
/// (`crop.py`) : on retranche left/top avant le mapping vers l’écran.
class MushafPageCoordinateTransform {
  MushafPageCoordinateTransform._({
    required this.layoutSize,
    required this.paintedRect,
    required this.filePage,
  });

  final Size layoutSize;
  final Rect paintedRect;
  final int filePage;

  double get _left => MushafPageImageCrop.leftForPage(filePage);
  double get _top => MushafPageImageCrop.top;
  double get _contentWidth => MushafPageImageCrop.contentWidthForPage(filePage);
  double get _contentHeight => MushafPageImageCrop.contentHeight;

  static Rect paintedImageRect({
    required Size imagePixelSize,
    required Size containerSize,
    required BoxFit fit,
    Alignment alignment = Alignment.topCenter,
  }) {
    final fitted = applyBoxFit(fit, imagePixelSize, containerSize);
    return alignment.inscribe(
      fitted.destination,
      Offset.zero & containerSize,
    );
  }

  factory MushafPageCoordinateTransform.forLocalDest({
    required Size layoutSize,
    required Size destSize,
    required int filePage,
  }) {
    return MushafPageCoordinateTransform._(
      layoutSize: layoutSize,
      paintedRect: Offset.zero & destSize,
      filePage: filePage,
    );
  }

  /// Layout → coordonnées dans le WebP recadré (origine = coin haut-gauche utile).
  Offset layoutToCropped(double x, double y) {
    final sourceX =
        x / layoutSize.width * MushafPageImageCrop.sourceWidth;
    final sourceY =
        y / layoutSize.height * MushafPageImageCrop.sourceHeight;
    return Offset(sourceX - _left, sourceY - _top);
  }

  Offset layoutToScreen(double x, double y) {
    final cropped = layoutToCropped(x, y);
    return Offset(
      paintedRect.left + cropped.dx / _contentWidth * paintedRect.width,
      paintedRect.top + cropped.dy / _contentHeight * paintedRect.height,
    );
  }

  Rect layoutRectToScreen(List<int> rect) {
    if (rect.length < 4) return Rect.zero;
    final topLeft = layoutToScreen(rect[0].toDouble(), rect[1].toDouble());
    final bottomRight = layoutToScreen(
      rect[0].toDouble() + rect[2].toDouble(),
      rect[1].toDouble() + rect[3].toDouble(),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }
}
