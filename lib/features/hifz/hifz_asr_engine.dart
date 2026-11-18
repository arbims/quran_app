import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'hifz_model_assets.dart';

/// Moteur ASR Quran CTC (sherpa-onnx) + VAD Silero — comme l’ancienne app.
class HifzAsrEngine {
  AudioRecorder? _recorder;
  StreamSubscription<List<int>>? _micSub;
  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _vad;
  bool _ready = false;
  bool _listening = false;

  final _utteranceController = StreamController<String>.broadcast();
  Stream<String> get utterances => _utteranceController.stream;

  bool get isReady => _ready;
  bool get isListening => _listening;

  Future<void> prepare() async {
    if (_ready) return;
    sherpa.initBindings();
    final paths = await HifzModelAssets.ensureReady();

    _recognizer = await sherpa.OfflineRecognizer.createAsync(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          nemoCtc: sherpa.OfflineNemoEncDecCtcModelConfig(
            model: paths.modelPath,
          ),
          tokens: paths.tokensPath,
          numThreads: 2,
          provider: 'cpu',
        ),
      ),
    );

    _vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: paths.vadPath,
          minSilenceDuration: 0.45,
          minSpeechDuration: 0.2,
          windowSize: 512,
        ),
        sampleRate: 16000,
        numThreads: 1,
        provider: 'cpu',
      ),
      bufferSizeInSeconds: 60,
    );

    _recorder = AudioRecorder();
    _ready = true;
  }

  Future<bool> ensureMicPermission() async {
    final recorder = _recorder ?? AudioRecorder();
    _recorder = recorder;
    return recorder.hasPermission();
  }

  Future<void> start() async {
    if (!_ready || _listening || _recorder == null || _vad == null) return;
    final ok = await ensureMicPermission();
    if (!ok) {
      throw StateError('microphone_permission_denied');
    }

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    final stream = await _recorder!.startStream(config);
    _listening = true;
    _micSub = stream.listen(_onPcmChunk);
  }

  Future<void> stop() async {
    _listening = false;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    _drainVad(forceRecognize: true);
  }

  void _onPcmChunk(List<int> bytes) {
    if (!_listening || _vad == null) return;
    final samples = _pcm16ToFloat32(Uint8List.fromList(bytes));
    if (samples.isEmpty) return;
    _vad!.acceptWaveform(samples);
    _drainVad();
  }

  void _drainVad({bool forceRecognize = false}) {
    final vad = _vad;
    final recognizer = _recognizer;
    if (vad == null || recognizer == null) return;

    // flush() pousse le segment ouvert dans la file avant drain.
    if (forceRecognize) {
      try {
        vad.flush();
      } catch (_) {}
    }

    while (!vad.isEmpty()) {
      final segment = vad.front();
      vad.pop();
      final text = _recognize(segment.samples);
      if (text.isNotEmpty && !_utteranceController.isClosed) {
        _utteranceController.add(text);
      }
    }
  }

  String _recognize(Float32List samples) {
    final recognizer = _recognizer;
    if (recognizer == null || samples.isEmpty) return '';
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }

  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    if (bytes.length < 2) return Float32List(0);
    final even = bytes.length & ~1;
    final count = even ~/ 2;
    final out = Float32List(count);
    final data = ByteData.sublistView(bytes, 0, even);
    for (var i = 0; i < count; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  Future<void> dispose() async {
    await stop();
    _vad?.free();
    _vad = null;
    _recognizer?.free();
    _recognizer = null;
    await _utteranceController.close();
    _ready = false;
  }
}
