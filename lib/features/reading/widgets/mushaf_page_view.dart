import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/mushaf_constants.dart';
import '../../../data/models/mushaf_word_layout.dart';
import '../../../providers/providers.dart';
import '../../hifz/widgets/hifz_mask_overlay.dart';
import 'mushaf_highlight_overlay.dart';
import 'mushaf_page_curl.dart';

/// Lecteur mushaf — pli de papier ([MushafPageCurl]), lecture RTL.
class MushafPageView extends StatefulWidget {
  const MushafPageView({
    super.key,
    required this.curlController,
    required this.pageIndex,
    required this.onPageChanged,
    this.onTap,
    this.backgroundColor = defaultBackground,
    this.colorFilter,
    this.fullScreen = false,
  });

  final MushafPageCurlController curlController;

  /// Index 0-based (`firstPage` → 0).
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final ColorFilter? colorFilter;
  final bool fullScreen;

  static const Color defaultBackground = Color(0xFF2A2A2A);

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  /// Nombre de pages gardées décodées de part et d'autre de la page courante.
  static const int _cacheRadius = 1;

  final Map<int, ui.Image> _images = <int, ui.Image>{};
  final Set<int> _loading = <int>{};
  int _decodeWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final logicalWidth = media?.size.width ?? MushafConstants.mushafImagePixelWidth;
    final ratio = media?.devicePixelRatio ?? 1;
    final target = (logicalWidth * ratio)
        .clamp(480.0, MushafConstants.mushafImagePixelWidth)
        .round();
    if (target != _decodeWidth) {
      _decodeWidth = target;
      _disposeImages();
    }
    _syncCache();
  }

  @override
  void didUpdateWidget(covariant MushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) _syncCache();
  }

  @override
  void dispose() {
    _disposeImages();
    super.dispose();
  }

  void _disposeImages() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  void _syncCache() {
    for (var offset = 0; offset <= _cacheRadius; offset++) {
      unawaited(_load(widget.pageIndex - offset));
      unawaited(_load(widget.pageIndex + offset));
    }
    final keep = <int>{
      for (var i = -_cacheRadius; i <= _cacheRadius; i++) widget.pageIndex + i,
    };
    for (final index in _images.keys.toList()) {
      if (keep.contains(index)) continue;
      _images.remove(index)?.dispose();
    }
  }

  Future<void> _load(int index) async {
    if (index < 0 || index >= MushafConstants.pageCount) return;
    if (_images.containsKey(index) || !_loading.add(index)) return;

    try {
      final image = await _decodePage(index, _decodeWidth);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _images[index] = image);
    } catch (_) {
      // Page illisible : le fond reste visible, on réessaiera au prochain sync.
    } finally {
      _loading.remove(index);
    }
  }

  static Future<ui.Image> _decodePage(int index, int width) {
    final provider = ResizeImage(
      AssetImage(
        MushafConstants.assetPathForPage(index + MushafConstants.firstPage),
      ),
      width: width,
      allowUpscaling: false,
    );
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image.clone());
        info.dispose();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  int _filePageForIndex(int index) => index + MushafConstants.firstPage;

  @override
  Widget build(BuildContext context) {
    return MushafPageCurl(
      controller: widget.curlController,
      pageCount: MushafConstants.pageCount,
      pageIndex: widget.pageIndex,
      backgroundColor: widget.backgroundColor,
      colorFilter: widget.colorFilter,
      imageForIndex: (index) => _images[index],
      onTap: widget.onTap,
      onPageChanged: (index) => widget.onPageChanged(_filePageForIndex(index)),
      overlayBuilder: (context, size) => _MushafOverlayLayer(
        page: _filePageForIndex(widget.pageIndex),
        pageSize: size,
      ),
    );
  }
}

/// Surlignage recherche + masques مساعد الحفظ.
class _MushafOverlayLayer extends ConsumerStatefulWidget {
  const _MushafOverlayLayer({required this.page, required this.pageSize});

  final int page;
  final Size pageSize;

  @override
  ConsumerState<_MushafOverlayLayer> createState() =>
      _MushafOverlayLayerState();
}

class _MushafOverlayLayerState extends ConsumerState<_MushafOverlayLayer> {
  MushafWordLayout? _layout;
  int? _layoutPage;

  @override
  void didUpdateWidget(covariant _MushafOverlayLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _layout = null;
      _layoutPage = null;
    }
  }

  void _loadLayout() {
    if (_layoutPage == widget.page) return;
    final page = widget.page;
    ref.read(mushafWordRepositoryProvider).loadPageLayout(page).then((layout) {
      if (!mounted || page != widget.page) return;
      setState(() {
        _layout = layout;
        _layoutPage = page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(readingProvider);
    final hifz = ref.watch(hifzProvider);
    final appearance = ref.watch(settingsProvider).pageAppearance;
    final searchActive =
        reading.currentPage == widget.page && reading.hasSearchHighlight;
    final hifzActive = hifz.active && reading.currentPage == widget.page;

    if (!searchActive && !hifzActive) return const SizedBox.shrink();

    _loadLayout();

    final layout = _layout;
    if (layout == null || layout.page != widget.page) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    if (hifzActive) {
      children.add(
        HifzMaskOverlay(
          layout: layout,
          viewportSize: widget.pageSize,
          hiddenWordIds: hifz.hiddenWordIds,
          mistakeWordIds: hifz.mistakeWordIds,
          ayahEndWordIds: hifz.ayahEndWordIds,
          hideAyahNumbers: hifz.hideAyahNumbers,
          appearance: appearance,
        ),
      );
    }

    if (searchActive) {
      final resolvedIds = resolveHighlightWordIds(
        layout: layout,
        requestedIds: reading.searchHighlightWordIds.toList(),
        surah: reading.searchHighlightSurah,
        ayah: reading.searchHighlightAyah,
      );
      if (resolvedIds.isNotEmpty) {
        children.add(
          MushafHighlightOverlay(
            layout: layout,
            highlightWordIds: resolvedIds,
            viewportSize: widget.pageSize,
          ),
        );
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;
    return Stack(fit: StackFit.expand, children: children);
  }
}
