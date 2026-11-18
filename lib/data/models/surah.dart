class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.startPage,
    required this.ayahCount,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final int startPage;
  final int ayahCount;
}
