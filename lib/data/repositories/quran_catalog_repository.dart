import '../hizb_data.dart';
import '../juzz_data.dart';
import '../models/hizb.dart';
import '../models/juzz.dart';
import '../models/surah.dart';
import '../surah_start_pages.dart';
import '../surahs_data.dart';
import '../../core/constants/mushaf_constants.dart';

class QuranCatalogRepository {
  List<Surah> get surahs => kSurahs;

  List<Juzz> get juzz => kJuzz;

  List<Hizb> get hizb => kHizb;

  Surah? surahById(int id) {
    try {
      return kSurahs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  int filePageForSurahId(int surahId) {
    final page = kSurahStartFilePage[surahId] ?? MushafConstants.firstPage;
    return MushafConstants.resolveFilePage(page);
  }

  int filePageForSurah(Surah surah) => filePageForSurahId(surah.id);

  int displayPageForSurah(Surah surah) => filePageForSurah(surah);

  int filePageForJuzz(Juzz juzz) =>
      MushafConstants.resolveFilePage(juzz.startPage);

  int displayPageForJuzz(Juzz juzz) => juzz.startPage;

  int filePageForHizb(Hizb h) =>
      MushafConstants.resolveFilePage(h.startPage);

  int displayPageForHizb(Hizb h) => h.startPage;

  Surah surahForPage(int filePage) {
    final page = MushafConstants.resolveFilePage(filePage);
    Surah result = kSurahs.first;
    for (final s in kSurahs) {
      final start = filePageForSurah(s);
      if (start <= page) {
        result = s;
      } else {
        break;
      }
    }
    return result;
  }

  List<Surah> searchSurahs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return kSurahs;

    final surahMatch = RegExp(r'^(\d{1,3})$').firstMatch(q);
    if (surahMatch != null) {
      final id = int.parse(surahMatch.group(1)!);
      final s = surahById(id);
      return s != null ? [s] : [];
    }

    final ayahMatch = RegExp(r'^(\d{1,3})\s*[:]\s*(\d{1,3})$').firstMatch(q);
    if (ayahMatch != null) {
      final id = int.parse(ayahMatch.group(1)!);
      final s = surahById(id);
      return s != null ? [s] : [];
    }

    return kSurahs.where((s) {
      return s.nameEn.toLowerCase().contains(q) ||
          s.nameAr.contains(query.trim()) ||
          s.id.toString() == q;
    }).toList();
  }

  int? ayahFromSearchQuery(String query) {
    final ayahMatch = RegExp(r'^(\d{1,3})\s*[:]\s*(\d{1,3})$').firstMatch(
      query.trim(),
    );
    if (ayahMatch == null) return null;
    return int.parse(ayahMatch.group(2)!);
  }

  int? surahIdFromSearchQuery(String query) {
    final ayahMatch = RegExp(r'^(\d{1,3})\s*[:]\s*(\d{1,3})$').firstMatch(
      query.trim(),
    );
    if (ayahMatch != null) {
      return int.parse(ayahMatch.group(1)!);
    }
    final surahMatch = RegExp(r'^(\d{1,3})$').firstMatch(query.trim());
    if (surahMatch != null) {
      return int.parse(surahMatch.group(1)!);
    }
    return null;
  }
}
