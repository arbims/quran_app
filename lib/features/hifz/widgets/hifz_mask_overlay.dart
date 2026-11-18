import 'package:flutter/material.dart';

import '../../../core/theme/page_appearance.dart';
import '../../../data/models/mushaf_word_layout.dart';
import '../../reading/widgets/mushaf_page_coordinate_transform.dart';

/// Masque les mots cachés / souligne les fautes (مساعد الحفظ).
///
/// Les anneaux de numéros d’ayah (`marker`) restent visibles tant que
/// [hideAyahNumbers] est désactivé — on ne peint plus de bande continue
/// qui les recouvrait au milieu des lignes.
class HifzMaskOverlay extends StatelessWidget {
  const HifzMaskOverlay({
    super.key,
    required this.layout,
    required this.viewportSize,
    required this.hiddenWordIds,
    required this.mistakeWordIds,
    required this.ayahEndWordIds,
    required this.hideAyahNumbers,
    this.appearance = PageAppearance.normal,
  });

  final MushafWordLayout layout;
  final Size viewportSize;
  final Set<String> hiddenWordIds;
  final Set<String> mistakeWordIds;
  final Set<String> ayahEndWordIds;
  final bool hideAyahNumbers;
  final PageAppearance appearance;

  @override
  Widget build(BuildContext context) {
    if (hiddenWordIds.isEmpty &&
        mistakeWordIds.isEmpty &&
        !(hideAyahNumbers && ayahEndWordIds.isNotEmpty)) {
      return const SizedBox.shrink();
    }

    final layoutSize = Size(
      layout.width.toDouble(),
      layout.height.toDouble(),
    );
    final transform = MushafPageCoordinateTransform.forLocalDest(
      layoutSize: layoutSize,
      destSize: viewportSize,
      filePage: layout.page,
    );

    return CustomPaint(
      size: viewportSize,
      painter: _HifzMaskPainter(
        layout: layout,
        transform: transform,
        hiddenWordIds: hiddenWordIds,
        mistakeWordIds: mistakeWordIds,
        ayahEndWordIds: ayahEndWordIds,
        hideAyahNumbers: hideAyahNumbers,
        maskColor: paperColor(appearance),
      ),
    );
  }

  /// Couleur papier visible (overlay hors [ColorFiltered] de la page).
  static Color paperColor(PageAppearance appearance) {
    return switch (appearance) {
      PageAppearance.normal => const Color(0xFFFFFFFF),
      PageAppearance.warm => const Color(0xFFF3E9D1),
      PageAppearance.night => const Color(0xFF000000),
    };
  }
}

class _HifzMaskPainter extends CustomPainter {
  _HifzMaskPainter({
    required this.layout,
    required this.transform,
    required this.hiddenWordIds,
    required this.mistakeWordIds,
    required this.ayahEndWordIds,
    required this.hideAyahNumbers,
    required this.maskColor,
  });

  final MushafWordLayout layout;
  final MushafPageCoordinateTransform transform;
  final Set<String> hiddenWordIds;
  final Set<String> mistakeWordIds;
  final Set<String> ayahEndWordIds;
  final bool hideAyahNumbers;
  final Color maskColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hideFill = Paint()
      ..style = PaintingStyle.fill
      ..color = maskColor
      ..isAntiAlias = false;
    final underline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE53935);

    for (final word in layout.words) {
      if (word.rect.length < 4) continue;
      final screen = transform.layoutRectToScreen(word.rect);
      if (screen.width <= 0 || screen.height <= 0) continue;

      if (hiddenWordIds.contains(word.id)) {
        // Masque mot par mot (pas de bande ligne entière) pour laisser
        // visibles les anneaux de numéros entre les mots.
        final maskRect = _wordMaskRect(word, screen);
        canvas.drawRect(maskRect, hideFill);
      }

      if (mistakeWordIds.contains(word.id)) {
        final y = screen.bottom - screen.height * 0.08;
        canvas.drawLine(
          Offset(screen.left + 2, y),
          Offset(screen.right - 2, y),
          underline,
        );
      }

      if (hideAyahNumbers &&
          (ayahEndWordIds.contains(word.id) || word.marker != null)) {
        final markerScreen = _markerScreenRect(word);
        if (markerScreen != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              markerScreen.inflate(1),
              const Radius.circular(4),
            ),
            hideFill,
          );
        }
      }
    }
  }

  /// Rectangle de masquage du mot, sans empiéter sur son `marker` d’ayah.
  Rect _wordMaskRect(MushafWord word, Rect screen) {
    var left = screen.left - 1;
    var top = screen.top - screen.height * 0.04;
    var right = screen.right + 1;
    var bottom = screen.bottom + screen.height * 0.06;

    final marker = _markerScreenRect(word);
    if (marker != null) {
      // Le marqueur est à gauche du mot (RTL) : on s’arrête avant.
      if (marker.right <= screen.center.dx) {
        left = left > marker.right + 1 ? left : marker.right + 1;
      } else if (marker.left >= screen.center.dx) {
        right = right < marker.left - 1 ? right : marker.left - 1;
      }
    }

    if (right <= left) return screen;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect? _markerScreenRect(MushafWord word) {
    final marker = word.marker;
    if (marker == null || marker.length < 4) return null;
    final screen = transform.layoutRectToScreen(marker);
    if (screen.width <= 0 || screen.height <= 0) return null;
    return screen;
  }

  @override
  bool shouldRepaint(covariant _HifzMaskPainter oldDelegate) {
    return oldDelegate.hiddenWordIds != hiddenWordIds ||
        oldDelegate.mistakeWordIds != mistakeWordIds ||
        oldDelegate.ayahEndWordIds != ayahEndWordIds ||
        oldDelegate.hideAyahNumbers != hideAyahNumbers ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.layout.page != layout.page;
  }
}
