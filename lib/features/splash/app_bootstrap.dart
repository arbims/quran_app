import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/native_splash_enabled.dart';
import '../../providers/providers.dart';
import '../reading/reading_screen.dart';

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  /// Basmala (بسم الله) — même image que le splash natif Android / iOS / web.
  static const String basmalaAsset = 'assets/branding/splash_basmala.png';

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _nativeSplashRemoved = false;

  void _removeNativeSplashIfNeeded() {
    if (!kNativeSplashEnabled || _nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(readingProvider);
    final settings = ref.watch(settingsProvider);

    if (!reading.ready || !settings.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeNativeSplashIfNeeded();
      });
      return const _LaunchSplash();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeNativeSplashIfNeeded();
    });

    return const ReadingScreen();
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: _SplashBasmala(),
      ),
    );
  }
}

class _SplashBasmala extends StatelessWidget {
  const _SplashBasmala();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Toute la basmala visible : bornée en largeur et en hauteur.
    final maxW = size.width * 0.72;
    final maxH = size.height * 0.62;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
      child: Image.asset(
        AppBootstrap.basmalaAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        alignment: Alignment.center,
      ),
    );
  }
}
