import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/page_appearance.dart';
import 'features/splash/app_bootstrap.dart';
import 'providers/providers.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  ThemeData _themeFor(PageAppearance appearance) {
    return switch (appearance) {
      PageAppearance.normal => AppTheme.light(),
      PageAppearance.warm => AppTheme.warm(),
      PageAppearance.night => AppTheme.dark(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'مصحف قالون',
      debugShowCheckedModeBanner: false,
      theme: _themeFor(settings.pageAppearance),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const AppBootstrap(),
    );
  }
}
