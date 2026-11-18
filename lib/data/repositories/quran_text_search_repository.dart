import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/mushaf_constants.dart';
import '../../core/text/arabic_search_normalize.dart';
import '../models/ayah_search_hit.dart';

class QuranTextSearchRepository {
  List<AyahSearchHit>? _entries;
  List<_IndexedAyah>? _indexed;

  Future<void> ensureLoaded() async {
    if (_entries != null) return;
    final raw = await rootBundle.loadString('assets/search/ayah_search.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _entries = list
        .map((e) => AyahSearchHit.fromJson(e as Map<String, dynamic>))
        .toList();
    _indexed = _entries!
        .map(
          (e) => _IndexedAyah(
            hit: e,
            normalized: normalizeArabicForSearch(e.searchText),
          ),
        )
        .toList();
  }

  Future<List<AyahSearchHit>> search(String query, {int limit = 50}) async {
    await ensureLoaded();
    final indexed = _indexed!;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _entries!.take(limit).toList();
    }

    final refMatch = RegExp(r'^(\d{1,3})\s*:\s*(\d{1,3})$').firstMatch(trimmed);
    if (refMatch != null) {
      final sid = int.parse(refMatch.group(1)!);
      final ayah = int.parse(refMatch.group(2)!);
      final id = '$sid:$ayah';
      final hit = _entries!.where((e) => e.sourceId == id).toList();
      return hit.take(limit).toList();
    }

    final q = collapseSearchSpaces(normalizeArabicForSearch(trimmed));
    if (q.isEmpty) return [];

    final results = <AyahSearchHit>[];
    for (final row in indexed) {
      if (row.normalized.contains(q)) {
        results.add(row.hit);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  AyahSearchHit resolveHit(AyahSearchHit hit) {
    final page = MushafConstants.resolveFilePage(hit.page);
    if (page == hit.page) return hit;
    return AyahSearchHit(
      page: page,
      sourceId: hit.sourceId,
      surah: hit.surah,
      sourceAyah: hit.sourceAyah,
      searchText: hit.searchText,
      displayText: hit.displayText,
      wordIds: hit.wordIds,
    );
  }
}

class _IndexedAyah {
  const _IndexedAyah({required this.hit, required this.normalized});

  final AyahSearchHit hit;
  final String normalized;
}
