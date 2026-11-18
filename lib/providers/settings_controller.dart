import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/page_appearance.dart';
import '../data/repositories/preferences_repository.dart';
import 'repository_providers.dart';

class SettingsState {
  const SettingsState({
    this.pageAppearance = PageAppearance.normal,
    this.readingReminder = true,
    this.reciterId = 'dokali',
    this.audioPageMode = false,
    this.ready = false,
  });

  final PageAppearance pageAppearance;
  final bool readingReminder;
  final String reciterId;
  final bool audioPageMode;
  final bool ready;

  ThemeMode get themeMode {
    return switch (pageAppearance) {
      PageAppearance.night => ThemeMode.dark,
      PageAppearance.normal || PageAppearance.warm => ThemeMode.light,
    };
  }

  SettingsState copyWith({
    PageAppearance? pageAppearance,
    bool? readingReminder,
    String? reciterId,
    bool? audioPageMode,
    bool? ready,
  }) {
    return SettingsState(
      pageAppearance: pageAppearance ?? this.pageAppearance,
      readingReminder: readingReminder ?? this.readingReminder,
      reciterId: reciterId ?? this.reciterId,
      audioPageMode: audioPageMode ?? this.audioPageMode,
      ready: ready ?? this.ready,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  late PreferencesRepository _prefs;

  @override
  SettingsState build() {
    _prefs = ref.read(preferencesProvider);
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final appearance = PageAppearanceStorage.fromStorage(
      await _prefs.loadPageAppearance(),
    );
    final reminder = await _prefs.loadReadingReminder();
    final reciterId = await _prefs.loadReciterId();
    final pageMode = await _prefs.loadAudioPageMode();
    state = state.copyWith(
      pageAppearance: appearance,
      readingReminder: reminder,
      reciterId: reciterId,
      audioPageMode: pageMode,
      ready: true,
    );
  }

  Future<void> setPageAppearance(PageAppearance appearance) async {
    state = state.copyWith(pageAppearance: appearance);
    await _prefs.savePageAppearance(appearance.storageKey);
  }

  Future<void> setReadingReminder(bool enabled) async {
    state = state.copyWith(readingReminder: enabled);
    await _prefs.saveReadingReminder(enabled);
  }

  Future<void> setReciterId(String id) async {
    state = state.copyWith(reciterId: id);
    await _prefs.saveReciterId(id);
  }

  Future<void> setAudioPageMode(bool value) async {
    state = state.copyWith(audioPageMode: value);
    await _prefs.saveAudioPageMode(value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
