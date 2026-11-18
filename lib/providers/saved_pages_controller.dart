import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/mushaf_constants.dart';
import '../data/models/saved_page.dart';
import '../data/repositories/preferences_repository.dart';
import 'repository_providers.dart';

class SavedPagesState {
  const SavedPagesState({
    this.pages = const [],
    this.ready = false,
  });

  final List<SavedPage> pages;
  final bool ready;

  bool containsPage(int page) => pages.any((p) => p.page == page);

  SavedPagesState copyWith({
    List<SavedPage>? pages,
    bool? ready,
  }) {
    return SavedPagesState(
      pages: pages ?? this.pages,
      ready: ready ?? this.ready,
    );
  }
}

class SavedPagesController extends Notifier<SavedPagesState> {
  late PreferencesRepository _prefs;

  @override
  SavedPagesState build() {
    _prefs = ref.read(preferencesProvider);
    _bootstrap();
    return const SavedPagesState();
  }

  Future<void> _bootstrap() async {
    final pages = await _prefs.loadSavedPages();
    state = SavedPagesState(pages: pages, ready: true);
  }

  Future<void> _persist(List<SavedPage> pages) async {
    state = state.copyWith(pages: pages);
    await _prefs.saveSavedPages(pages);
  }

  /// Même nom (ex. « ورد اليوم ») → écrase l’entrée existante au lieu d’en créer une nouvelle.
  Future<({SavedPage page, bool replaced})> upsert({
    required int page,
    required String name,
  }) async {
    final resolvedName = name.trim().isEmpty ? 'للحفظ' : name.trim();
    final resolvedPage = MushafConstants.resolveFilePage(page);
    final existingIndex = state.pages.indexWhere(
      (p) => _sameName(p.name, resolvedName),
    );

    if (existingIndex >= 0) {
      final previous = state.pages[existingIndex];
      final updated = previous.copyWith(
        page: resolvedPage,
        name: resolvedName,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      final next = [...state.pages]..removeAt(existingIndex);
      await _persist([updated, ...next]);
      return (page: updated, replaced: true);
    }

    final entry = SavedPage(
      id: 'sp_${DateTime.now().microsecondsSinceEpoch}',
      page: resolvedPage,
      name: resolvedName,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist([entry, ...state.pages]);
    return (page: entry, replaced: false);
  }

  Future<void> update({
    required String id,
    String? name,
    int? page,
  }) async {
    final resolvedName = name?.trim();
    final resolvedPage =
        page != null ? MushafConstants.resolveFilePage(page) : null;

    // Renommer vers un nom déjà pris → fusionne en écrasant l’autre entrée.
    if (resolvedName != null && resolvedName.isNotEmpty) {
      SavedPage? conflict;
      for (final p in state.pages) {
        if (p.id != id && _sameName(p.name, resolvedName)) {
          conflict = p;
          break;
        }
      }
      if (conflict != null) {
        final current = state.pages.firstWhere((p) => p.id == id);
        final merged = conflict.copyWith(
          page: resolvedPage ?? current.page,
          name: resolvedName,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        );
        final next = state.pages
            .where((p) => p.id != id && p.id != conflict!.id)
            .toList();
        await _persist([merged, ...next]);
        return;
      }
    }

    final next = state.pages.map((p) {
      if (p.id != id) return p;
      return p.copyWith(
        name: resolvedName ?? p.name,
        page: resolvedPage ?? p.page,
      );
    }).toList();
    await _persist(next);
  }

  static bool _sameName(String a, String b) =>
      a.trim() == b.trim() && a.trim().isNotEmpty;

  Future<void> remove(String id) async {
    await _persist(state.pages.where((p) => p.id != id).toList());
  }

  Future<void> removeMany(Set<String> ids) async {
    if (ids.isEmpty) return;
    await _persist(state.pages.where((p) => !ids.contains(p.id)).toList());
  }
}

final savedPagesProvider =
    NotifierProvider<SavedPagesController, SavedPagesState>(
  SavedPagesController.new,
);
