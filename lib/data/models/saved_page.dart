class SavedPage {
  const SavedPage({
    required this.id,
    required this.page,
    required this.name,
    required this.createdAtMs,
  });

  final String id;
  final int page;
  final String name;
  final int createdAtMs;

  SavedPage copyWith({
    String? id,
    int? page,
    String? name,
    int? createdAtMs,
  }) {
    return SavedPage(
      id: id ?? this.id,
      page: page ?? this.page,
      name: name ?? this.name,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'name': name,
        'createdAtMs': createdAtMs,
      };

  factory SavedPage.fromJson(Map<String, dynamic> json) {
    return SavedPage(
      id: json['id'] as String,
      page: json['page'] as int,
      name: json['name'] as String? ?? '',
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
}
