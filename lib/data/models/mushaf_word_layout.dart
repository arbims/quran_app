class MushafWordLayout {
  const MushafWordLayout({
    required this.page,
    required this.width,
    required this.height,
    required this.words,
  });

  final int page;
  final int width;
  final int height;
  final List<MushafWord> words;

  factory MushafWordLayout.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'] as List<dynamic>? ?? [];
    return MushafWordLayout(
      page: json['page'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      words: wordsJson
          .map((e) => MushafWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MushafWord {
  const MushafWord({
    required this.id,
    required this.text,
    required this.line,
    required this.rect,
    required this.parts,
    this.surah,
    this.ayah,
    this.marker,
  });

  final String id;
  final String text;
  final int line;
  final List<int> rect;
  final List<List<int>> parts;
  final int? surah;
  final int? ayah;

  /// Anneau du numéro d’ayah (x, y, w, h) sur le dernier mot de l’ayah.
  final List<int>? marker;

  factory MushafWord.fromJson(Map<String, dynamic> json) {
    final partsRaw = json['parts'] as List<dynamic>? ?? [];
    final markerRaw = json['marker'] as List<dynamic>?;
    return MushafWord(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      line: json['line'] as int? ?? 0,
      rect: (json['rect'] as List<dynamic>).cast<int>(),
      parts: partsRaw
          .map((p) => (p as List<dynamic>).cast<int>())
          .toList(),
      surah: json['surah'] as int?,
      ayah: json['ayah'] as int?,
      marker: markerRaw == null || markerRaw.length < 4
          ? null
          : markerRaw.cast<int>(),
    );
  }
}
