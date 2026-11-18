class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.server,
    required this.moshafId,
  });

  final String id;
  final String name;
  final String nameAr;

  /// Base CDN mp3quran (fichier sourate : `{server}001.mp3`).
  final String server;

  /// Identifiant « read / moshaf » pour l’API `ayat_timing`.
  final int moshafId;
}
