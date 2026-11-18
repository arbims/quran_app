import 'dart:convert' show jsonDecode, utf8;

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import '../../core/constants/mushaf_constants.dart';
import '../models/mushaf_word_layout.dart';

class MushafWordRepository {
  final Map<int, MushafWordLayout> _cache = {};
  static const int _maxCache = 6;

  Future<MushafWordLayout?> loadPageLayout(int filePage) async {
    final page = MushafConstants.resolveFilePage(filePage);
    final cached = _cache[page];
    if (cached != null) return cached;

    try {
      final data = await rootBundle.load(
        'assets/word_data/pages_gz/$page.json.gz',
      );
      final decoded = utf8.decode(
        GZipDecoder().decodeBytes(data.buffer.asUint8List()),
      );
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final layout = MushafWordLayout.fromJson(json);
      _remember(page, layout);
      return layout;
    } catch (_) {
      return null;
    }
  }

  void _remember(int page, MushafWordLayout layout) {
    if (_cache.length >= _maxCache) {
      _cache.remove(_cache.keys.first);
    }
    _cache[page] = layout;
  }

  void clearCache() => _cache.clear();
}
