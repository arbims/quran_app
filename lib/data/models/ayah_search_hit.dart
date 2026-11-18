class AyahSearchHit {
  const AyahSearchHit({
    required this.page,
    required this.sourceId,
    required this.surah,
    required this.sourceAyah,
    required this.searchText,
    required this.displayText,
    required this.wordIds,
  });

  final int page;
  final String sourceId;
  final int surah;
  final int sourceAyah;
  final String searchText;
  final String displayText;
  final List<String> wordIds;

  factory AyahSearchHit.fromJson(Map<String, dynamic> json) {
    return AyahSearchHit(
      page: json['page'] as int,
      sourceId: json['sourceId'] as String? ?? '',
      surah: json['surah'] as int,
      sourceAyah: json['sourceAyah'] as int,
      searchText: json['searchText'] as String? ?? '',
      displayText: json['text'] as String? ?? json['searchText'] as String? ?? '',
      wordIds: (json['wordIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
