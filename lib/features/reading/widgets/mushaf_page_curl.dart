import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Réglages visuels du pli cylindrique (`shaders/mushaf_page_curl.frag`).
class MushafCurlStyle {
  const MushafCurlStyle._();

  /// Rayon du cylindre, en fraction de la largeur de page.
  static const double radius = 0.085;

  /// Largeur de l'ombre portée, relative au rayon.
  static const double shadowWidth = 0.12;

  /// Opacité du dos de feuille (effet vélin : le recto transparaît).
  static const double backOpacity = 0.55;

  static const Duration flipDuration = Duration(milliseconds: 480);

  /// Au-delà de cette fraction de largeur parcourue, le relâchement valide le
  /// changement de page au lieu de revenir en arrière.
  static const double commitThreshold = 0.28;

  /// Vitesse (px/s) au-delà de laquelle un geste bref valide quand même.
  static const double commitVelocity = 420;
}

/// Sens du pli. Glisser vers la droite avance, vers la gauche recule.
enum MushafCurlDirection { next, previous }

/// Pilote le pli depuis l'extérieur (flèches de la barre du bas).
class MushafPageCurlController {
  _MushafPageCurlState? _state;

  bool get canGoNext => _state?._canGo(MushafCurlDirection.next) ?? false;

  bool get canGoPrevious =>
      _state?._canGo(MushafCurlDirection.previous) ?? false;

  void next() => _state?.animateFlip(MushafCurlDirection.next);

  void previous() => _state?.animateFlip(MushafCurlDirection.previous);
}

/// Lecteur de pages avec pli de papier façon mushaf papier.
class MushafPageCurl extends StatefulWidget {
  const MushafPageCurl({
    super.key,
    required this.controller,
    required this.pageCount,
    required this.pageIndex,
    required this.imageForIndex,
    required this.onPageChanged,
    this.onTap,
    this.overlayBuilder,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.colorFilter,
  });

  final MushafPageCurlController controller;
  final int pageCount;

  /// Index 0-based de la page affichée.
  final int pageIndex;

  /// Fournit l'image décodée d'une page ; `null` tant qu'elle charge.
  final ui.Image? Function(int index) imageForIndex;

  final ValueChanged<int> onPageChanged;
  final VoidCallback? onTap;

  /// Calque dessiné par-dessus la page au repos (surlignage de recherche).
  final Widget Function(BuildContext context, Size size)? overlayBuilder;

  final Color backgroundColor;

  /// Filtre de mode de lecture (عادي / دافئ / ليلي) sur l’image mushaf.
  final ColorFilter? colorFilter;

  @override
  State<MushafPageCurl> createState() => _MushafPageCurlState();
}

class _MushafPageCurlState extends State<MushafPageCurl>
    with SingleTickerProviderStateMixin {
  static const String _shaderAsset = 'shaders/mushaf_page_curl.frag';

  ui.FragmentShader? _shader;
  late final AnimationController _animation;

  MushafCurlDirection? _direction;
  double _dragStartProgress = 0;
  double _dragDx = 0;
  double _viewWidth = 1;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _animation = AnimationController(vsync: this)
      ..addListener(() => setState(() {}));
    unawaited(_loadShader());
  }

  @override
  void didUpdateWidget(covariant MushafPageCurl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _animation.dispose();
    _shader?.dispose();
    super.dispose();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Pli indisponible (shader non supporté) : la page reste affichée à plat.
    }
  }

  /// Page qui se replie physiquement pendant le geste.
  int get _frontIndex => _direction == MushafCurlDirection.previous
      ? widget.pageIndex - 1
      : widget.pageIndex;

  /// Page révélée sous la feuille qui se replie.
  int get _backIndex => _direction == MushafCurlDirection.previous
      ? widget.pageIndex
      : widget.pageIndex + 1;

  bool _canGo(MushafCurlDirection direction) {
    final target = direction == MushafCurlDirection.next
        ? widget.pageIndex + 1
        : widget.pageIndex - 1;
    return target >= 0 && target < widget.pageCount;
  }

  /// `0` = feuille à plat, `1` = feuille entièrement rabattue.
  double get _progress => _animation.value;

  bool get _flipping => _direction != null;

  void animateFlip(MushafCurlDirection direction) {
    if (_flipping || !_canGo(direction)) return;
    setState(() {
      _direction = direction;
      _animation.value = direction == MushafCurlDirection.next ? 0 : 1;
    });
    _settle(commit: true);
  }

  void _settle({required bool commit}) {
    final direction = _direction;
    if (direction == null) return;

    final goingForward = direction == MushafCurlDirection.next;
    // Rabattre jusqu'à 1 fait avancer, dérouler jusqu'à 0 fait reculer.
    final target = commit == goingForward ? 1.0 : 0.0;
    final distance = (target - _animation.value).abs();
    if (distance < 1e-3) {
      _finishFlip(commit: commit);
      return;
    }

    _animation
        .animateTo(
          target,
          duration: MushafCurlStyle.flipDuration * distance,
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
      if (mounted) _finishFlip(commit: commit);
    });
  }

  void _finishFlip({required bool commit}) {
    final direction = _direction;
    if (direction == null) return;
    setState(() {
      _direction = null;
      _animation.value = 0;
    });
    if (!commit) return;
    widget.onPageChanged(
      direction == MushafCurlDirection.next
          ? widget.pageIndex + 1
          : widget.pageIndex - 1,
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_animation.isAnimating) _animation.stop();
    _dragDx = 0;
    _dragStartProgress = _progress;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;

    if (_direction == null) {
      // Vers la droite = on avance, vers la gauche = on recule (reliure à droite).
      final direction = _dragDx > 0
          ? MushafCurlDirection.next
          : MushafCurlDirection.previous;
      if (!_canGo(direction)) return;
      _direction = direction;
      _dragStartProgress =
          direction == MushafCurlDirection.next ? 0.0 : 1.0;
    }

    final travelled = _dragDx / _viewWidth;
    setState(() {
      _animation.value = (_dragStartProgress + travelled).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final direction = _direction;
    if (direction == null) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final travelled = (_progress - _dragStartProgress).abs();
    final goingForward = direction == MushafCurlDirection.next;
    final flungForward = velocity > MushafCurlStyle.commitVelocity;
    final flungBackward = velocity < -MushafCurlStyle.commitVelocity;

    final commit = (goingForward && flungForward) ||
        (!goingForward && flungBackward) ||
        (travelled >= MushafCurlStyle.commitThreshold &&
            !(goingForward ? flungBackward : flungForward));

    _settle(commit: commit);
  }

  Widget _maybeFilter(ColorFilter? filter, Widget child) {
    if (filter == null) return child;
    return ColorFiltered(colorFilter: filter, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _viewWidth = size.width <= 0 ? 1 : size.width;

        final front = widget.imageForIndex(
          _flipping ? _frontIndex : widget.pageIndex,
        );
        final back = _flipping ? widget.imageForIndex(_backIndex) : null;
        final overlay = widget.overlayBuilder;

        return ColoredBox(
          color: widget.backgroundColor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (front != null)
                  _maybeFilter(
                    widget.colorFilter,
                    CustomPaint(
                      painter: _MushafCurlPainter(
                        front: front,
                        back: back,
                        shader: _shader,
                        progress: _flipping ? _progress : 0,
                      ),
                    ),
                  ),
                if (overlay != null && !_flipping)
                  IgnorePointer(child: overlay(context, size)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MushafCurlPainter extends CustomPainter {
  _MushafCurlPainter({
    required this.front,
    required this.back,
    required this.shader,
    required this.progress,
  });

  final ui.Image front;
  final ui.Image? back;
  final ui.FragmentShader? shader;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final back = this.back;
    final shader = this.shader;
    if (shader == null || back == null || progress <= 0) {
      _drawStretched(canvas, size, front);
      return;
    }
    if (progress >= 1) {
      _drawStretched(canvas, size, back);
      return;
    }

    const radius = MushafCurlStyle.radius;
    // Bord libre à gauche (mushaf) : le cylindre va de 0 → 1+r.
    // Avancer = progress↑ (la page part vers la droite) ;
    // reculer = progress↓ (la page revient depuis la droite).
    final curlX = progress * (1 + radius);

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, curlX)
      ..setFloat(3, 0.5)
      ..setFloat(4, -1) // révèle la page sous le bord gauche
      ..setFloat(5, 0)
      ..setFloat(6, radius)
      ..setFloat(7, MushafCurlStyle.shadowWidth)
      ..setFloat(8, MushafCurlStyle.backOpacity)
      ..setFloat(9, 0)
      ..setImageSampler(0, front)
      ..setImageSampler(1, back);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _drawStretched(Canvas canvas, Size size, ui.Image image) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _MushafCurlPainter oldDelegate) {
    return oldDelegate.front != front ||
        oldDelegate.back != back ||
        oldDelegate.shader != shader ||
        oldDelegate.progress != progress;
  }
}
