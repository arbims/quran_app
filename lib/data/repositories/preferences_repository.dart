import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/mushaf_constants.dart';
import '../models/saved_page.dart';

class PreferencesRepository {
  static const _lastPageKey = 'last_page';
  static const _bookmarkPageKey = 'bookmark_page';
  static const _savedPagesKey = 'saved_pages_v1';
  static const _reciterIdKey = 'reciter_id';
  static const _themeModeKey = 'theme_mode';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';
  static const _audioPageModeKey = 'audio_page_mode';
  static const _pageAppearanceKey = 'page_appearance';
  static const _pageAppearanceDefaultV2Key = 'page_appearance_default_v2';
  static const _readingReminderKey = 'reading_reminder';

  Future<int> loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPageKey) ?? MushafConstants.firstPage;
  }

  Future<void> saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageKey, page);
  }

  Future<int?> loadBookmarkPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bookmarkPageKey);
  }

  Future<void> saveBookmarkPage(int? page) async {
    final prefs = await SharedPreferences.getInstance();
    if (page == null) {
      await prefs.remove(_bookmarkPageKey);
    } else {
      await prefs.setInt(_bookmarkPageKey, page);
    }
  }

  /// Liste des pages sauvegardées (مخطط sauvgarde1 / sauvgarde2).
  /// Migre l’ancien signet unique s’il existe encore.
  Future<List<SavedPage>> loadSavedPages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedPagesKey);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedPage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final legacy = prefs.getInt(_bookmarkPageKey);
    if (legacy == null) return const [];

    final migrated = [
      SavedPage(
        id: 'legacy_$legacy',
        page: MushafConstants.resolveFilePage(legacy),
        name: 'للحفظ',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    await saveSavedPages(migrated);
    await prefs.remove(_bookmarkPageKey);
    return migrated;
  }

  Future<void> saveSavedPages(List<SavedPage> pages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(pages.map((e) => e.toJson()).toList());
    await prefs.setString(_savedPagesKey, encoded);
  }

  Future<String> loadReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_reciterIdKey) ?? 'dokali';
    const known = {'dokali', 'husary_qaloon', 'hudhaifi_qaloon'};
    return known.contains(id) ? id : 'dokali';
  }

  Future<void> saveReciterId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reciterIdKey, id);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<(int surah, int ayah)> loadLastAyahPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_lastSurahKey) ?? 1;
    final ayah = prefs.getInt(_lastAyahKey) ?? 1;
    return (surah, ayah);
  }

  Future<void> saveLastAyahPosition(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSurahKey, surah);
    await prefs.setInt(_lastAyahKey, ayah);
  }

  Future<bool> loadAudioPageMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_audioPageModeKey) ?? false;
  }

  Future<void> saveAudioPageMode(bool pageMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioPageModeKey, pageMode);
  }

  Future<String> loadPageAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    // Une fois : forcer عادي comme défaut (au cas où دافئ était resté en cache).
    if (!(prefs.getBool(_pageAppearanceDefaultV2Key) ?? false)) {
      await prefs.setString(_pageAppearanceKey, 'normal');
      await prefs.setBool(_pageAppearanceDefaultV2Key, true);
      return 'normal';
    }
    return prefs.getString(_pageAppearanceKey) ?? 'normal';
  }

  Future<void> savePageAppearance(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pageAppearanceKey, value);
    await prefs.setBool(_pageAppearanceDefaultV2Key, true);
  }

  Future<bool> loadReadingReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readingReminderKey) ?? true;
  }

  Future<void> saveReadingReminder(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readingReminderKey, enabled);
  }
}
