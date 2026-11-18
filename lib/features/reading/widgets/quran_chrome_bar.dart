import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fond des menus haut/bas : bleu + motif géométrique (style ancienne appli).
class QuranChromeBar extends StatelessWidget {
  const QuranChromeBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.headerBlue,
      child: CustomPaint(
        painter: const _IslamicChromePatternPainter(),
        child: child,
      ),
    );
  }
}

/// Tessellation proche de l’ancienne appli : étoiles à 8 branches (Rub el Hizb),
/// octogones et connecteurs en losange — traits moyens, densité équilibrée.
class _IslamicChromePatternPainter extends CustomPainter {
  const _IslamicChromePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x48D8E4F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..isAntiAlias = true;

    const step = 72.0;
    final cols = (size.width / step).ceil() + 2;
    final rows = (size.height / step).ceil() + 2;

    for (var iy = -1; iy < rows; iy++) {
      for (var ix = -1; ix < cols; ix++) {
        final cx = ix * step;
        final cy = iy * step;
        if ((ix + iy).isEven) {
          _drawMainMotif(canvas, paint, Offset(cx, cy), step);
        } else {
          _drawConnector(canvas, paint, Offset(cx, cy), step);
        }
      }
    }
  }

  void _drawMainMotif(Canvas canvas, Paint paint, Offset c, double step) {
    final ro = step * 0.42;
    final ri = step * 0.175;

    _octagon(canvas, paint, c, ro);
    _star8(canvas, paint, c, ro * 0.92, ri);
    _square(canvas, paint, c, step * 0.14, math.pi / 4);
    canvas.drawCircle(c, step * 0.07, paint);

    for (var k = 0; k < 8; k++) {
      final ang = math.pi / 8 + k * math.pi / 4;
      final a = Offset(
        c.dx + ri * 1.15 * math.cos(ang),
        c.dy + ri * 1.15 * math.sin(ang),
      );
      final b = Offset(
        c.dx + ro * 0.72 * math.cos(ang),
        c.dy + ro * 0.72 * math.sin(ang),
      );
      canvas.drawLine(a, b, paint);
    }
  }

  void _drawConnector(Canvas canvas, Paint paint, Offset c, double step) {
    _square(canvas, paint, c, step * 0.26, 0);
    _square(canvas, paint, c, step * 0.26, math.pi / 4);
    canvas.drawCircle(c, step * 0.09, paint);
  }

  void _star8(Canvas canvas, Paint paint, Offset c, double ro, double ri) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final ang = -math.pi / 2 + i * math.pi / 8;
      final r = i.isEven ? ro : ri;
      final p = Offset(c.dx + r * math.cos(ang), c.dy + r * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _octagon(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final ang = math.pi / 8 + i * math.pi / 4;
      final p = Offset(c.dx + r * math.cos(ang), c.dy + r * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _square(Canvas canvas, Paint paint, Offset c, double r, double rot) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final ang = rot + i * math.pi / 2;
      final p = Offset(c.dx + r * math.cos(ang), c.dy + r * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
