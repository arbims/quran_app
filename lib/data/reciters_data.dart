import 'models/reciter.dart';

/// Récitants رواية قالون — mêmes cheikhs que l’ancienne app
/// (`الحصري`, `الحذيفي`, `الدوكالي`).
const List<Reciter> kReciters = [
  Reciter(
    id: 'dokali',
    name: 'Al-Dokali Muhammad Al-Alim',
    nameAr: 'الدوكالي محمد العالم',
    server: 'https://cdn.mp3quran.net/audio/dokali-alim/r1/',
    moshafId: 208,
  ),
  Reciter(
    id: 'husary_qaloon',
    name: 'Mahmoud Khalil Al-Husary',
    nameAr: 'محمود خليل الحصري',
    server: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r5/',
    moshafId: 270,
  ),
  Reciter(
    id: 'hudhaifi_qaloon',
    name: 'Ali Abdur-Rahman Al-Hudhaifi',
    nameAr: 'علي بن عبدالرحمن الحذيفي',
    server: 'https://cdn.mp3quran.net/audio/ali-hudhaifi/r2/',
    moshafId: 75,
  ),
];

String qaloonSurahUrl({
  required String server,
  required int surah,
}) {
  final s = surah.toString().padLeft(3, '0');
  return '$server$s.mp3';
}

String ayatTimingUrl({
  required int moshafId,
  required int surah,
}) {
  return 'https://mp3quran.net/api/v3/ayat_timing?surah=$surah&read=$moshafId';
}
