import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/mushaf_constants.dart';
import '../../core/platform/audio_enabled.dart';
import '../../data/models/mushaf_word_layout.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/reciters_data.dart';
import '../../data/repositories/ayah_timing_repository.dart';
import '../../data/repositories/mushaf_word_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/repositories/quran_catalog_repository.dart';
import '../../data/surahs_data.dart';
import '../../providers/reading_controller.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_controller.dart';
import 'media_artwork.dart';
import 'quran_audio_handler.dart';

enum AudioPlaybackStatus { idle, loading, playing, paused, error }

class AudioState {
  const AudioState({
    this.surah = 1,
    this.ayah = 1,
    this.status = AudioPlaybackStatus.idle,
    this.autoAdvance = true,
    this.panelVisible = false,
    this.repeatAyah = false,
    this.speed = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.ayahStart = Duration.zero,
    this.ayahEnd = Duration.zero,
  });

  final int surah;
  final int ayah;
  final AudioPlaybackStatus status;
  final bool autoAdvance;
  final bool panelVisible;
  final bool repeatAyah;
  final double speed;
  final Duration position;
  final Duration duration;
  final Duration ayahStart;
  final Duration ayahEnd;

  bool get isActive =>
      status == AudioPlaybackStatus.playing ||
      status == AudioPlaybackStatus.paused ||
      status == AudioPlaybackStatus.loading;

  double get progress {
    final span = ayahEnd - ayahStart;
    if (span <= Duration.zero) return 0;
    final local = position - ayahStart;
    return (local.inMilliseconds / span.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioState copyWith({
    int? surah,
    int? ayah,
    AudioPlaybackStatus? status,
    bool? autoAdvance,
    bool? panelVisible,
    bool? repeatAyah,
    double? speed,
    Duration? position,
    Duration? duration,
    Duration? ayahStart,
    Duration? ayahEnd,
  }) {
    return AudioState(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      status: status ?? this.status,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      panelVisible: panelVisible ?? this.panelVisible,
      repeatAyah: repeatAyah ?? this.repeatAyah,
      speed: speed ?? this.speed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      ayahStart: ayahStart ?? this.ayahStart,
      ayahEnd: ayahEnd ?? this.ayahEnd,
    );
  }
}

class AudioController extends Notifier<AudioState> {
  QuranAudioHandler? _handler;
  AudioPlayer? get _player => _handler?.player;

  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlaybackState>? _serviceSub;

  late PreferencesRepository _prefs;
  late QuranCatalogRepository _catalog;
  late MushafWordRepository _words;
  late AyahTimingRepository _timingsRepo;

  bool _sessionReady = false;
  bool _handlingBoundary = false;
  int? _loadedSurah;
  String? _loadedReciterId;
  List<AyahTiming> _timings = const [];

  static const List<double> speedOptions = [0.75, 1.0, 1.25, 1.5];

  @override
  AudioState build() {
    _prefs = ref.read(preferencesProvider);
    _catalog = ref.read(catalogProvider);
    _words = ref.read(mushafWordRepositoryProvider);
    _timingsRepo = ref.read(ayahTimingRepositoryProvider);
    if (kAudioEnabled) {
      ref.onDispose(_dispose);
      unawaited(_init());
    }
    return const AudioState();
  }

  Future<void> _init() async {
    if (!kAudioEnabled) return;
    if (!hasQuranAudioHandler) return;

    _handler = quranAudioHandler;
    _handler!
      ..onSkipNext = nextAyah
      ..onSkipPrevious = previousAyah
      ..onCompleted = _onSurahCompleted;

    final (surah, ayah) = await _prefs.loadLastAyahPosition();
    state = state.copyWith(surah: surah, ayah: ayah);

    _playerSub = _player!.playerStateStream.listen(_onPlayerState);
    _positionSub = _player!.positionStream.listen(_onPosition);
    _durationSub = _player!.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
    _serviceSub = _handler!.playbackState.listen((ps) {
      // Sync UI si pause/play depuis la notification.
      if (!state.isActive && !state.panelVisible) return;
      if (ps.processingState == AudioProcessingState.idle && !ps.playing) {
        return;
      }
      if (ps.playing && state.status != AudioPlaybackStatus.playing) {
        state = state.copyWith(
          status: AudioPlaybackStatus.playing,
          panelVisible: true,
        );
      } else if (!ps.playing &&
          state.status == AudioPlaybackStatus.playing &&
          ps.processingState == AudioProcessingState.ready) {
        state = state.copyWith(status: AudioPlaybackStatus.paused);
      }
    });
  }

  void _onPlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      unawaited(_onSurahCompleted());
    }
  }

  Future<void> _ensureSession() async {
    if (!kAudioEnabled || _sessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
    _sessionReady = true;
  }

  Future<void> _dispose() async {
    await _playerSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _serviceSub?.cancel();
  }

  /// Android 13+ : sans POST_NOTIFICATIONS le son continue mais le widget
  /// média (lock screen / notif) est masqué.
  Future<bool> _ensureNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return true;
    status = await Permission.notification.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isDenied) {
      await openAppSettings();
    }
    status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Reciter _currentReciter() {
    final id = ref.read(settingsProvider).reciterId;
    return kReciters.firstWhere(
      (r) => r.id == id,
      orElse: () => kReciters.first,
    );
  }

  Surah _surahMeta(int id) => _catalog.surahById(id) ?? kSurahs.first;

  Future<void> syncWithPage(int page) async {
    if (!kAudioEnabled) return;
    if (state.isActive) return;
    final surah = _catalog.surahForPage(page);
    if (surah.id != state.surah) {
      state = state.copyWith(surah: surah.id, ayah: 1);
      await _prefs.saveLastAyahPosition(surah.id, 1);
    }
  }

  Future<void> seekToAyah(int surah, int ayah) async {
    if (!kAudioEnabled) return;
    final meta = _surahMeta(surah);
    final clampedAyah = ayah.clamp(1, meta.ayahCount);
    state = state.copyWith(surah: surah, ayah: clampedAyah);
    await _prefs.saveLastAyahPosition(surah, clampedAyah);
    await _highlightCurrentAyah();
    await _publishMediaItem();
  }

  Future<void> showPanel() async {
    state = state.copyWith(panelVisible: true);
    unawaited(_ensureNotificationPermission());
  }

  Future<void> hidePanel() async {
    state = state.copyWith(panelVisible: false);
  }

  Future<void> playPage() async {
    if (!kAudioEnabled) return;
    await ref.read(settingsProvider.notifier).setAudioPageMode(true);
    final page = ref.read(readingProvider).currentPage;
    final layout = await _words.loadPageLayout(page);
    final first = firstAyahOnPage(layout);
    if (first != null) {
      await seekToAyah(first.$1, first.$2);
    } else {
      await syncWithPage(page);
    }
    state = state.copyWith(panelVisible: true, autoAdvance: true);
    await play();
  }

  Future<void> playContinuous() async {
    if (!kAudioEnabled) return;
    await ref.read(settingsProvider.notifier).setAudioPageMode(false);
    final page = ref.read(readingProvider).currentPage;
    final layout = await _words.loadPageLayout(page);
    final onPage = ayahOnPage(layout, state.surah, state.ayah);
    if (!onPage) {
      final first = firstAyahOnPage(layout);
      if (first != null) {
        await seekToAyah(first.$1, first.$2);
      } else {
        await syncWithPage(page);
      }
    } else {
      await _highlightCurrentAyah();
    }
    state = state.copyWith(panelVisible: true, autoAdvance: true);
    await play();
  }

  Future<void> play() async {
    if (!kAudioEnabled || _handler == null) return;
    // Demande la permission AVANT de démarrer : sinon FGS sans notif visible.
    final notifOk = await _ensureNotificationPermission();
    await _ensureSession();
    state = state.copyWith(
      status: AudioPlaybackStatus.loading,
      panelVisible: true,
    );
    try {
      await _ensureSurahLoaded();
      final window = _windowForAyah(state.ayah);
      state = state.copyWith(
        ayahStart: window.$1,
        ayahEnd: window.$2,
        position: window.$1,
      );
      await _player!.seek(window.$1);
      await _player!.setSpeed(state.speed);
      await _highlightCurrentAyah();
      await _publishMediaItem();
      await _handler!.play();
      // Force l’affichage des boutons média (écran verrouillé / barre de notif).
      AudioService.androidForceEnableMediaButtons();
      if (!notifOk) {
        // Re-tente après ouverture éventuelle des réglages.
        await _ensureNotificationPermission();
        AudioService.androidForceEnableMediaButtons();
      }
      state = state.copyWith(status: AudioPlaybackStatus.playing);
    } catch (_) {
      state = state.copyWith(status: AudioPlaybackStatus.error);
    }
  }

  Future<void> _ensureSurahLoaded() async {
    final reciter = _currentReciter();
    final sameSurah = _loadedSurah == state.surah;
    final sameReciter = _loadedReciterId == reciter.id;
    if (sameSurah && sameReciter && _timings.isNotEmpty) {
      await _publishMediaItem();
      return;
    }

    final meta = _surahMeta(state.surah);
    final url = qaloonSurahUrl(server: reciter.server, surah: state.surah);
    final art = await MediaArtwork.uri();
    final item = MediaItem(
      id: '${reciter.id}-${meta.id}',
      album: 'مصحف قالون',
      title: 'سورة ${meta.nameAr} · الآية ${state.ayah}',
      artist: reciter.nameAr,
      artUri: art,
      displayTitle: 'سورة ${meta.nameAr} · الآية ${state.ayah}',
      displaySubtitle: reciter.nameAr,
    );

    await _handler!.setMedia(item: item, url: url);
    _timings = await _timingsRepo.load(
      moshafId: reciter.moshafId,
      surah: state.surah,
    );
    _loadedSurah = state.surah;
    _loadedReciterId = reciter.id;
  }

  Future<void> _publishMediaItem() async {
    if (_handler == null || _loadedSurah == null) return;
    final reciter = _currentReciter();
    final meta = _surahMeta(state.surah);
    final art = await MediaArtwork.uri();
    final window = _windowForAyah(state.ayah);
    _handler!.setNowPlaying(
      MediaItem(
        id: '${reciter.id}-${meta.id}-${state.ayah}',
        album: 'مصحف قالون',
        title: 'سورة ${meta.nameAr} · الآية ${state.ayah}',
        artist: reciter.nameAr,
        artUri: art,
        duration: _player?.duration,
        displayTitle: 'سورة ${meta.nameAr} · الآية ${state.ayah}',
        displaySubtitle: reciter.nameAr,
        extras: {
          'ayahStartMs': window.$1.inMilliseconds,
          'ayahEndMs': window.$2.inMilliseconds,
        },
      ),
    );
  }

  (Duration, Duration) _windowForAyah(int ayah) {
    for (final t in _timings) {
      if (t.ayah == ayah) return (t.start, t.end);
    }
    final total = _player?.duration ?? Duration.zero;
    if (total <= Duration.zero || _timings.isEmpty) {
      return (Duration.zero, total);
    }
    return (_timings.first.start, _timings.last.end);
  }

  Future<void> pause() async {
    if (!kAudioEnabled || _handler == null) return;
    await _handler!.pause();
    state = state.copyWith(status: AudioPlaybackStatus.paused);
  }

  Future<void> stop() async {
    if (!kAudioEnabled || _handler == null) return;
    await _handler!.stop();
    _loadedSurah = null;
    _loadedReciterId = null;
    _timings = const [];
    state = state.copyWith(
      status: AudioPlaybackStatus.idle,
      position: Duration.zero,
      duration: Duration.zero,
      ayahStart: Duration.zero,
      ayahEnd: Duration.zero,
      panelVisible: false,
    );
    ref.read(readingProvider.notifier).clearSearchHighlight();
  }

  Future<void> togglePlayPause() async {
    if (!kAudioEnabled) return;
    if (state.status == AudioPlaybackStatus.playing) {
      await pause();
    } else {
      state = state.copyWith(panelVisible: true);
      await play();
    }
  }

  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0);
    state = state.copyWith(speed: clamped);
    await _player?.setSpeed(clamped);
  }

  Future<void> cycleSpeed() async {
    final current = state.speed;
    final idx = speedOptions.indexWhere((s) => (s - current).abs() < 0.01);
    final next = speedOptions[(idx + 1) % speedOptions.length];
    await setSpeed(next);
  }

  void toggleRepeatAyah() {
    state = state.copyWith(repeatAyah: !state.repeatAyah);
  }

  Future<void> seekProgress(double progress) async {
    if (!kAudioEnabled || _player == null) return;
    final span = state.ayahEnd - state.ayahStart;
    if (span <= Duration.zero) return;
    final target = state.ayahStart + span * progress.clamp(0.0, 1.0);
    await _handler!.seek(target);
  }

  Future<void> nextAyah() async {
    if (!kAudioEnabled) return;
    final next = _nextAyahPosition(state.surah, state.ayah);
    if (next == null) return;
    final wasPlaying = state.status == AudioPlaybackStatus.playing;
    await seekToAyah(next.$1, next.$2);
    await _ensurePageShowsAyah(next.$1, next.$2);
    if (wasPlaying || state.panelVisible) {
      await play();
    }
  }

  Future<void> previousAyah() async {
    if (!kAudioEnabled) return;
    final prev = _previousAyahPosition(state.surah, state.ayah);
    if (prev == null) return;
    final wasPlaying = state.status == AudioPlaybackStatus.playing;
    await seekToAyah(prev.$1, prev.$2);
    await _ensurePageShowsAyah(prev.$1, prev.$2);
    if (wasPlaying || state.panelVisible) {
      await play();
    }
  }

  Future<void> nextPageMode(int currentPage) async {
    final next = (currentPage + 1).clamp(
      MushafConstants.firstPage,
      MushafConstants.lastPage,
    );
    await ref.read(readingProvider.notifier).setPage(next);
  }

  Future<void> previousPageMode(int currentPage) async {
    final prev = (currentPage - 1).clamp(
      MushafConstants.firstPage,
      MushafConstants.lastPage,
    );
    await ref.read(readingProvider.notifier).setPage(prev);
  }

  (int, int)? _nextAyahPosition(int surah, int ayah) {
    final meta = _surahMeta(surah);
    if (ayah < meta.ayahCount) return (surah, ayah + 1);
    if (surah < 114) return (surah + 1, 1);
    return null;
  }

  (int, int)? _previousAyahPosition(int surah, int ayah) {
    if (ayah > 1) return (surah, ayah - 1);
    if (surah > 1) {
      final prev = _surahMeta(surah - 1);
      return (surah - 1, prev.ayahCount);
    }
    return null;
  }

  Future<void> _highlightCurrentAyah() async {
    await ref.read(readingProvider.notifier).highlightAyah(
          surah: state.surah,
          ayah: state.ayah,
        );
  }

  Future<void> _ensurePageShowsAyah(int surah, int ayah) async {
    final currentPage = ref.read(readingProvider).currentPage;
    final currentLayout = await _words.loadPageLayout(currentPage);
    if (ayahOnPage(currentLayout, surah, ayah)) return;

    for (var p = currentPage;
        p <= MushafConstants.lastPage && p <= currentPage + 3;
        p++) {
      final layout = await _words.loadPageLayout(p);
      if (ayahOnPage(layout, surah, ayah)) {
        await ref
            .read(readingProvider.notifier)
            .setPage(p, keepSearchHighlight: true);
        return;
      }
    }
    for (var p = currentPage - 1;
        p >= MushafConstants.firstPage && p >= currentPage - 3;
        p--) {
      final layout = await _words.loadPageLayout(p);
      if (ayahOnPage(layout, surah, ayah)) {
        await ref
            .read(readingProvider.notifier)
            .setPage(p, keepSearchHighlight: true);
        return;
      }
    }
  }

  void _onPosition(Duration position) {
    if (!kAudioEnabled) return;
    state = state.copyWith(position: position);

    if (state.status != AudioPlaybackStatus.playing || _handlingBoundary) {
      return;
    }

    final end = state.ayahEnd;
    if (end > Duration.zero &&
        position >= end - const Duration(milliseconds: 40)) {
      _handlingBoundary = true;
      unawaited(_onAyahBoundaryReached());
    }
  }

  Future<void> _onAyahBoundaryReached() async {
    try {
      if (state.repeatAyah) {
        await _handler?.seek(state.ayahStart);
        return;
      }

      if (!state.autoAdvance) {
        await pause();
        return;
      }

      final pageMode = ref.read(settingsProvider).audioPageMode;
      final next = _nextAyahPosition(state.surah, state.ayah);
      if (next == null) {
        await stop();
        return;
      }

      if (pageMode) {
        final page = ref.read(readingProvider).currentPage;
        final layout = await _words.loadPageLayout(page);
        if (!ayahOnPage(layout, next.$1, next.$2)) {
          await pause();
          return;
        }
      }

      final sameSurah = next.$1 == state.surah;
      await seekToAyah(next.$1, next.$2);
      await _ensurePageShowsAyah(next.$1, next.$2);

      if (sameSurah && _timings.isNotEmpty) {
        final window = _windowForAyah(next.$2);
        state = state.copyWith(ayahStart: window.$1, ayahEnd: window.$2);
        await _handler?.seek(window.$1);
        await _publishMediaItem();
        if (state.status != AudioPlaybackStatus.playing) {
          await _handler?.play();
          state = state.copyWith(status: AudioPlaybackStatus.playing);
        }
      } else {
        await play();
      }
    } finally {
      _handlingBoundary = false;
    }
  }

  Future<void> _onSurahCompleted() async {
    if (!kAudioEnabled) return;
    if (state.repeatAyah) {
      await play();
      return;
    }
    if (!state.autoAdvance) {
      state = state.copyWith(status: AudioPlaybackStatus.paused);
      return;
    }
    final next = _nextAyahPosition(state.surah, state.ayah);
    if (next == null) {
      await stop();
      return;
    }
    final pageMode = ref.read(settingsProvider).audioPageMode;
    if (pageMode) {
      final page = ref.read(readingProvider).currentPage;
      final layout = await _words.loadPageLayout(page);
      if (!ayahOnPage(layout, next.$1, next.$2)) {
        await pause();
        return;
      }
    }
    await seekToAyah(next.$1, next.$2);
    await _ensurePageShowsAyah(next.$1, next.$2);
    await play();
  }
}

(int, int)? firstAyahOnPage(MushafWordLayout? layout) {
  if (layout == null) return null;
  for (final word in layout.words) {
    final s = word.surah;
    final a = word.ayah;
    if (s != null && a != null) return (s, a);
  }
  return null;
}

bool ayahOnPage(MushafWordLayout? layout, int surah, int ayah) {
  if (layout == null) return false;
  for (final word in layout.words) {
    if (word.surah == surah && word.ayah == ayah) return true;
  }
  return false;
}

final audioProvider = NotifierProvider<AudioController, AudioState>(
  AudioController.new,
);
