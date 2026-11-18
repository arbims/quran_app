import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/mushaf_constants.dart';
import '../../core/platform/hifz_enabled.dart';
import '../../providers/reading_controller.dart';
import '../../providers/repository_providers.dart';
import 'hifz_asr_engine.dart';
import 'hifz_word_matcher.dart';

enum HifzStartMode { currentPage, surahAyah }

enum HifzPhase { idle, preparing, listening, error }

class HifzState {
  const HifzState({
    this.active = false,
    this.phase = HifzPhase.idle,
    this.hideAyahNumbers = false,
    this.startMode = HifzStartMode.currentPage,
    this.startSurah = 1,
    this.startAyah = 1,
    this.hiddenWordIds = const {},
    this.mistakeWordIds = const {},
    this.ayahEndWordIds = const {},
    this.lastHeard = '',
    this.errorMessage,
    this.mistakeCount = 0,
    this.revealedCount = 0,
  });

  final bool active;
  final HifzPhase phase;
  final bool hideAyahNumbers;
  final HifzStartMode startMode;
  final int startSurah;
  final int startAyah;
  final Set<String> hiddenWordIds;
  final Set<String> mistakeWordIds;
  final Set<String> ayahEndWordIds;
  final String lastHeard;
  final String? errorMessage;
  final int mistakeCount;
  final int revealedCount;

  HifzState copyWith({
    bool? active,
    HifzPhase? phase,
    bool? hideAyahNumbers,
    HifzStartMode? startMode,
    int? startSurah,
    int? startAyah,
    Set<String>? hiddenWordIds,
    Set<String>? mistakeWordIds,
    Set<String>? ayahEndWordIds,
    String? lastHeard,
    String? errorMessage,
    bool clearError = false,
    int? mistakeCount,
    int? revealedCount,
  }) {
    return HifzState(
      active: active ?? this.active,
      phase: phase ?? this.phase,
      hideAyahNumbers: hideAyahNumbers ?? this.hideAyahNumbers,
      startMode: startMode ?? this.startMode,
      startSurah: startSurah ?? this.startSurah,
      startAyah: startAyah ?? this.startAyah,
      hiddenWordIds: hiddenWordIds ?? this.hiddenWordIds,
      mistakeWordIds: mistakeWordIds ?? this.mistakeWordIds,
      ayahEndWordIds: ayahEndWordIds ?? this.ayahEndWordIds,
      lastHeard: lastHeard ?? this.lastHeard,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mistakeCount: mistakeCount ?? this.mistakeCount,
      revealedCount: revealedCount ?? this.revealedCount,
    );
  }
}

class HifzController extends Notifier<HifzState> {
  HifzAsrEngine? _engine;
  StreamSubscription<String>? _utteranceSub;
  HifzWordMatcher? _matcher;
  int? _page;

  @override
  HifzState build() {
    ref.onDispose(() {
      unawaited(_shutdownEngine());
    });
    return const HifzState();
  }

  void setStartMode(HifzStartMode mode) {
    state = state.copyWith(startMode: mode);
  }

  void setHideAyahNumbers(bool value) {
    state = state.copyWith(hideAyahNumbers: value);
  }

  void setStartSurahAyah(int surah, int ayah) {
    state = state.copyWith(startSurah: surah, startAyah: ayah);
  }

  Future<void> startSession() async {
    if (!kHifzEnabled) {
      state = state.copyWith(
        active: false,
        phase: HifzPhase.error,
        errorMessage: 'غير متاح على هذه المنصة',
      );
      return;
    }

    state = state.copyWith(
      active: true,
      phase: HifzPhase.preparing,
      clearError: true,
      hiddenWordIds: const {},
      mistakeWordIds: const {},
      ayahEndWordIds: const {},
      lastHeard: '',
      mistakeCount: 0,
      revealedCount: 0,
    );

    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        await _failSession('يلزم إذن الميكروفون لبدء مساعد الحفظ');
        return;
      }

      _engine ??= HifzAsrEngine();
      await _engine!.prepare();

      var page = ref.read(readingProvider).currentPage;
      if (state.startMode == HifzStartMode.surahAyah) {
        final resolved = await _resolveStartPage(
          state.startSurah,
          state.startAyah,
        );
        if (resolved != null && resolved != page) {
          page = resolved;
          await ref.read(readingProvider.notifier).setPage(page);
        }
      }

      final loaded = await _loadPage(page);
      if (!loaded) {
        await _failSession(
          state.errorMessage ?? 'لا توجد بيانات كلمات لهذه الصفحة',
        );
        return;
      }

      if (state.startMode == HifzStartMode.surahAyah) {
        _seekMatcherTo(state.startSurah, state.startAyah);
        _publishMatcher();
      }

      await _utteranceSub?.cancel();
      _utteranceSub = _engine!.utterances.listen(_onUtterance);

      await _engine!.start();
      state = state.copyWith(phase: HifzPhase.listening);
    } catch (e) {
      await _failSession(
        e.toString().toLowerCase().contains('permission')
            ? 'يلزم إذن الميكروفون لبدء مساعد الحفظ'
            : 'تعذّر تجهيز مساعد الحفظ',
      );
    }
  }

  Future<void> stopSession() async {
    await _utteranceSub?.cancel();
    _utteranceSub = null;
    await _engine?.stop();
    _matcher = null;
    _page = null;
    state = HifzState(
      hideAyahNumbers: state.hideAyahNumbers,
      startMode: state.startMode,
      startSurah: state.startSurah,
      startAyah: state.startAyah,
    );
  }

  Future<void> onReadingPageChanged(int page) async {
    if (!state.active || state.phase != HifzPhase.listening) return;
    if (_page == page) return;
    final ok = await _loadPage(page);
    if (!ok) {
      await _failSession(
        state.errorMessage ?? 'لا توجد بيانات كلمات لهذه الصفحة',
      );
    }
  }

  /// Remet la session en erreur visible (barre) sans laisser le micro tourner.
  Future<void> _failSession(String message) async {
    await _utteranceSub?.cancel();
    _utteranceSub = null;
    try {
      await _engine?.stop();
    } catch (_) {}
    _matcher = null;
    _page = null;
    state = state.copyWith(
      active: true,
      phase: HifzPhase.error,
      errorMessage: message,
      hiddenWordIds: const {},
      mistakeWordIds: const {},
      ayahEndWordIds: const {},
      lastHeard: '',
      mistakeCount: 0,
      revealedCount: 0,
    );
  }

  Future<bool> _loadPage(int page) async {
    final layout =
        await ref.read(mushafWordRepositoryProvider).loadPageLayout(page);
    if (layout == null) {
      state = state.copyWith(
        phase: HifzPhase.error,
        errorMessage: 'لا توجد بيانات كلمات لهذه الصفحة',
      );
      return false;
    }
    _page = page;
    _matcher = HifzWordMatcher(HifzWordMatcher.fromLayout(layout));
    _publishMatcher();
    return true;
  }

  Future<int?> _resolveStartPage(int surah, int ayah) async {
    final search = ref.read(quranTextSearchRepositoryProvider);
    final hits = await search.search('$surah:$ayah', limit: 1);
    if (hits.isEmpty) return null;
    return search.resolveHit(hits.first).page;
  }

  void _seekMatcherTo(int surah, int ayah) {
    final matcher = _matcher;
    if (matcher == null) return;
    for (var i = 0; i < matcher.words.length; i++) {
      final w = matcher.words[i].word;
      if (w.surah == surah && w.ayah == ayah) {
        for (var j = 0; j < i; j++) {
          if (!matcher.words[j].isBasmala) {
            matcher.words[j].status = HifzWordStatus.revealed;
          }
        }
        matcher.cursor = i;
        return;
      }
    }
  }

  void _onUtterance(String text) {
    final matcher = _matcher;
    if (matcher == null || !state.active) return;
    matcher.consumeUtterance(text);
    _publishMatcher(lastHeard: text);

    if (matcher.pageComplete) {
      unawaited(_advancePage());
    }
  }

  Future<void> _advancePage() async {
    final current = ref.read(readingProvider).currentPage;
    if (current >= MushafConstants.lastPage) {
      await stopSession();
      return;
    }
    final next = current + 1;
    await ref.read(readingProvider.notifier).setPage(next);
    final ok = await _loadPage(next);
    if (!ok) {
      await _failSession(
        state.errorMessage ?? 'لا توجد بيانات كلمات لهذه الصفحة',
      );
    }
  }

  void _publishMatcher({String? lastHeard}) {
    final matcher = _matcher;
    if (matcher == null) return;
    final mistakes =
        matcher.words.where((w) => w.status == HifzWordStatus.mistake).length;
    final revealed = matcher.words
        .where(
          (w) =>
              !w.isBasmala &&
              w.normalized.isNotEmpty &&
              w.status != HifzWordStatus.hidden,
        )
        .length;
    state = state.copyWith(
      hiddenWordIds: matcher.hiddenIds,
      mistakeWordIds: matcher.mistakeIds,
      ayahEndWordIds: matcher.ayahEndIds,
      lastHeard: lastHeard ?? state.lastHeard,
      mistakeCount: mistakes,
      revealedCount: revealed,
    );
  }

  Future<void> _shutdownEngine() async {
    await _utteranceSub?.cancel();
    await _engine?.dispose();
    _engine = null;
  }
}

final hifzProvider = NotifierProvider<HifzController, HifzState>(
  HifzController.new,
);
