import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Pont natif MediaSession (Android) / MPNowPlayingInfoCenter (iOS)
/// via `audio_service` — équivalent Flutter de Track Player.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler() {
    _player.playbackEventStream.listen(_broadcastPlaybackState);
    // Position continue → barre de progression lock screen / notification.
    _positionSub = _player.positionStream.listen((_) {
      if (_player.playing) {
        _broadcastPlaybackState(_player.playbackEvent);
      }
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        onCompleted?.call();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;

  AudioPlayer get player => _player;

  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function()? onCompleted;

  Future<void> setMedia({
    required MediaItem item,
    required String url,
    Duration? initialPosition,
  }) async {
    final stamped = item.copyWith(
      duration: item.duration ?? Duration.zero,
    );
    queue.add([stamped]);
    mediaItem.add(stamped);

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(url)),
      initialPosition: initialPosition ?? Duration.zero,
      preload: true,
    );

    final duration = _player.duration;
    if (duration != null) {
      final withDuration = stamped.copyWith(duration: duration);
      queue.add([withDuration]);
      mediaItem.add(withDuration);
    }
    _broadcastPlaybackState(_player.playbackEvent);
  }

  /// Met à jour titre / artiste / pochette (ayah courant).
  void setNowPlaying(MediaItem item) {
    final duration = item.duration ?? _player.duration;
    final updated = item.copyWith(duration: duration);
    queue.add([updated]);
    mediaItem.add(updated);
    _broadcastPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipNext != null) await onSkipNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipPrevious != null) await onSkipPrevious!();
  }

  void _broadcastPlaybackState(PlaybackEvent event) {
    final playing = _player.playing;
    // Ordre lock screen : stop · précédent · play/pause · suivant
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.stop,
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.stop,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.play,
          MediaAction.pause,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }

  Future<void> disposePlayer() async {
    await _positionSub?.cancel();
    await _player.dispose();
  }
}

QuranAudioHandler? _quranAudioHandler;

QuranAudioHandler get quranAudioHandler {
  final h = _quranAudioHandler;
  if (h == null) {
    throw StateError('QuranAudioHandler not initialised');
  }
  return h;
}

bool get hasQuranAudioHandler => _quranAudioHandler != null;

Future<QuranAudioHandler> initQuranAudioHandler() async {
  if (_quranAudioHandler != null) return _quranAudioHandler!;
  _quranAudioHandler = await AudioService.init(
    builder: QuranAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.quran_app.channel.audio',
      androidNotificationChannelName: 'تلاوة القرآن',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      artDownscaleWidth: 200,
      artDownscaleHeight: 200,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
  return _quranAudioHandler!;
}
