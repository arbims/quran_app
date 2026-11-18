import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/ayah_timing_repository.dart';
import '../data/repositories/mushaf_word_repository.dart';
import '../data/repositories/preferences_repository.dart';
import '../data/repositories/quran_catalog_repository.dart';
import '../data/repositories/quran_text_search_repository.dart';

final catalogProvider = Provider<QuranCatalogRepository>(
  (ref) => QuranCatalogRepository(),
);

final preferencesProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(),
);

final mushafWordRepositoryProvider = Provider<MushafWordRepository>(
  (ref) => MushafWordRepository(),
);

final quranTextSearchRepositoryProvider = Provider<QuranTextSearchRepository>(
  (ref) => QuranTextSearchRepository(),
);

final ayahTimingRepositoryProvider = Provider<AyahTimingRepository>(
  (ref) => AyahTimingRepository(),
);
