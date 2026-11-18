import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/mushaf_constants.dart';
import '../data/repositories/preferences_repository.dart';
import '../data/repositories/quran_catalog_repository.dart';
import 'repository_providers.dart';

class ReadingState {
  const ReadingState({
    this.currentPage = MushafConstants.firstPage,
    this.bookmarkPage,
    this.toolbarVisible = true,
    this.ready = false,
    this.searchHighlightWordIds = const [],
    this.searchHighlightSurah,
    this.searchHighlightAyah,
  });

  final int currentPage;
  final int? bookmarkPage;
  final bool toolbarVisible;
  final bool ready;
  final List<String> searchHighlightWordIds;
  final int? searchHighlightSurah;
  final int? searchHighlightAyah;

  bool get hasSearchHighlight =>
      searchHighlightWordIds.isNotEmpty ||
      (searchHighlightSurah != null && searchHighlightAyah != null);

  ReadingState copyWith({
    int? currentPage,
    int? bookmarkPage,
    bool clearBookmark = false,
    bool? toolbarVisible,
    bool? ready,
    List<String>? searchHighlightWordIds,
    int? searchHighlightSurah,
    int? searchHighlightAyah,
    bool clearSearchHighlight = false,
  }) {
    return ReadingState(
      currentPage: currentPage ?? this.currentPage,
      bookmarkPage: clearBookmark ? null : (bookmarkPage ?? this.bookmarkPage),
      toolbarVisible: toolbarVisible ?? this.toolbarVisible,
      ready: ready ?? this.ready,
      searchHighlightWordIds: clearSearchHighlight
          ? const []
          : (searchHighlightWordIds ?? this.searchHighlightWordIds),
      searchHighlightSurah: clearSearchHighlight
          ? null
          : (searchHighlightSurah ?? this.searchHighlightSurah),
      searchHighlightAyah: clearSearchHighlight
          ? null
          : (searchHighlightAyah ?? this.searchHighlightAyah),
    );
  }
}

class ReadingController extends Notifier<ReadingState> {
  late PreferencesRepository _prefs;
  late QuranCatalogRepository _catalog;

  @override
  ReadingState build() {
    _prefs = ref.read(preferencesProvider);
    _catalog = ref.read(catalogProvider);
    _bootstrap();
    return const ReadingState();
  }

  Future<void> _bootstrap() async {
    final lastPage = MushafConstants.resolveFilePage(await _prefs.loadLastPage());
    final bookmark = await _prefs.loadBookmarkPage();
    state = state.copyWith(
      currentPage: lastPage,
      bookmarkPage: bookmark,
      ready: true,
    );
  }

  Future<void> setPage(int page, {bool keepSearchHighlight = false}) async {
    final resolved = MushafConstants.resolveFilePage(page);
    final samePage = resolved == state.currentPage;
    final shouldClearHighlight =
        !keepSearchHighlight && state.searchHighlightWordIds.isNotEmpty;
    if (samePage && !shouldClearHighlight) return;

    state = state.copyWith(
      currentPage: resolved,
      clearSearchHighlight: !keepSearchHighlight,
    );
    if (!samePage) {
      await _prefs.saveLastPage(resolved);
    }
  }

  Future<void> goToSearchHit({
    required int page,
    required List<String> wordIds,
    int? surah,
    int? ayah,
  }) async {
    final resolved = MushafConstants.resolveFilePage(page);
    state = state.copyWith(
      currentPage: resolved,
      searchHighlightWordIds: wordIds,
      searchHighlightSurah: surah,
      searchHighlightAyah: ayah,
    );
    await _prefs.saveLastPage(resolved);
  }

  void clearSearchHighlight() {
    if (!state.hasSearchHighlight) return;
    state = state.copyWith(clearSearchHighlight: true);
  }

  /// Surligne un verset sur la page courante (écoute audio / recherche).
  Future<void> highlightAyah({
    required int surah,
    required int ayah,
  }) async {
    state = state.copyWith(
      searchHighlightWordIds: const [],
      searchHighlightSurah: surah,
      searchHighlightAyah: ayah,
    );
  }

  void toggleToolbar() {
    state = state.copyWith(toolbarVisible: !state.toolbarVisible);
  }

  Future<void> toggleBookmark() async {
    if (state.bookmarkPage == state.currentPage) {
      state = state.copyWith(clearBookmark: true);
      await _prefs.saveBookmarkPage(null);
    } else {
      state = state.copyWith(bookmarkPage: state.currentPage);
      await _prefs.saveBookmarkPage(state.currentPage);
    }
  }

  Future<void> goToBookmark() async {
    final page = state.bookmarkPage;
    if (page != null) {
      await setPage(page);
    }
  }

  Future<void> goToSurahStart(int surahId) async {
    final surah = _catalog.surahById(surahId);
    if (surah == null) return;
    await setPage(_catalog.filePageForSurah(surah));
  }

  Future<void> goToJuzz(int juzzNumber) async {
    final juzz = _catalog.juzz.firstWhere((j) => j.number == juzzNumber);
    await setPage(_catalog.filePageForJuzz(juzz));
  }

  Future<void> goToHizb(int hizbNumber) async {
    final h = _catalog.hizb.firstWhere((e) => e.number == hizbNumber);
    await setPage(_catalog.filePageForHizb(h));
  }
}

final readingProvider = NotifierProvider<ReadingController, ReadingState>(
  ReadingController.new,
);
