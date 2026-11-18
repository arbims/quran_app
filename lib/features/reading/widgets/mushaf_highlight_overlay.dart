import 'package:flutter/material.dart';

import '../../../core/constants/mushaf_constants.dart';
import '../../../data/models/mushaf_word_layout.dart';
import 'mushaf_page_coordinate_transform.dart';

class MushafHighlightOverlay extends StatelessWidget {
  const MushafHighlightOverlay({
    super.key,
    required this.layout,
    required this.highlightWordIds,
    required this.viewportSize,
    /// Couleur du trait (bordure). Le fond est dérivé plus transparent.
    this.color = const Color(0x99FFC107),
    this.fillOpacity = 0.18,
    this.strokeWidth = 1.5,
  });

  final MushafWordLayout layout;
  final Set<String> highlightWordIds;
  final Size viewportSize;
  final Color color;
  final double fillOpacity;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (highlightWordIds.isEmpty) return const SizedBox.shrink();

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
      painter: _MushafHighlightPainter(
        layout: layout,
        highlightWordIds: highlightWordIds,
        transform: transform,
        color: color,
        fillOpacity: fillOpacity,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _MushafHighlightPainter extends CustomPainter {
  _MushafHighlightPainter({
    required this.layout,
    required this.highlightWordIds,
    required this.transform,
    required this.color,
    required this.fillOpacity,
    required this.strokeWidth,
  });

  final MushafWordLayout layout;
  final Set<String> highlightWordIds;
  final MushafPageCoordinateTransform transform;
  final Color color;
  final double fillOpacity;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: fillOpacity);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    for (final word in layout.words) {
      if (!highlightWordIds.contains(word.id)) continue;
      final rect = word.rect.length >= 4 ? word.rect : null;
      if (rect == null) continue;
      final screenRect = transform.layoutRectToScreen(rect);
      if (screenRect.width <= 0 || screenRect.height <= 0) continue;
      final rrect =
          RRect.fromRectAndRadius(screenRect, const Radius.circular(2));
      canvas
        ..drawRRect(rrect, fill)
        ..drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MushafHighlightPainter oldDelegate) {
    return oldDelegate.highlightWordIds != highlightWordIds ||
        oldDelegate.layout.page != layout.page ||
        oldDelegate.transform.paintedRect != transform.paintedRect ||
        oldDelegate.color != color ||
        oldDelegate.fillOpacity != fillOpacity ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

Set<String> resolveHighlightWordIds({
  required MushafWordLayout layout,
  required List<String> requestedIds,
  int? surah,
  int? ayah,
}) {
  final onPage = requestedIds.where((id) {
    return layout.words.any((w) => w.id == id);
  }).toSet();

  if (onPage.isNotEmpty) return onPage;

  if (surah == null || ayah == null) return const {};

  return layout.words
      .where((w) => w.surah == surah && w.ayah == ayah)
      .map((w) => w.id)
      .toSet();
}

Size mushafDefaultImagePixelSize() => const Size(
      MushafConstants.mushafImagePixelWidth,
      MushafConstants.mushafImagePixelHeight,
    );
