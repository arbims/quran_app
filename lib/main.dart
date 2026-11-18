import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/audio_enabled.dart';
import 'core/platform/native_splash_enabled.dart';
import 'features/audio/quran_audio_handler.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (kNativeSplashEnabled) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Comme l’ancienne app : audio_service (notification + boutons lock screen).
  if (kAudioEnabled) {
    await initQuranAudioHandler();
  }

  runApp(
    const ProviderScope(
      child: QuranApp(),
    ),
  );
}
