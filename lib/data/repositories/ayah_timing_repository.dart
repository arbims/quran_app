import 'dart:convert';
import 'dart:io';

import '../reciters_data.dart';

class AyahTiming {
  const AyahTiming({
    required this.ayah,
    required this.start,
    required this.end,
  });

  final int ayah;
  final Duration start;
  final Duration end;
}

/// Timings verset (ms) via mp3quran — pour seek dans le MP3 sourate.
class AyahTimingRepository {
  final Map<String, List<AyahTiming>> _cache = {};

  Future<List<AyahTiming>> load({
    required int moshafId,
    required int surah,
  }) async {
    final key = '$moshafId:$surah';
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.parse(ayatTimingUrl(moshafId: moshafId, surah: surah));
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        _cache[key] = const [];
        return const [];
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        _cache[key] = const [];
        return const [];
      }

      final timings = <AyahTiming>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final ayah = item['ayah'];
        final start = item['start_time'];
        final end = item['end_time'];
        if (ayah is! num || start is! num || end is! num) continue;
        timings.add(
          AyahTiming(
            ayah: ayah.toInt(),
            start: Duration(milliseconds: start.toInt()),
            end: Duration(milliseconds: end.toInt()),
          ),
        );
      }
      timings.sort((a, b) => a.ayah.compareTo(b.ayah));
      _cache[key] = timings;
      return timings;
    } catch (_) {
      _cache[key] = const [];
      return const [];
    } finally {
      client.close();
    }
  }

  void clearCache() => _cache.clear();
}
