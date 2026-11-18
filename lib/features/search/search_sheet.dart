import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/audio_enabled.dart';
import '../../data/models/ayah_search_hit.dart';
import '../../data/models/surah.dart';
import '../../providers/providers.dart';

class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final _controller = TextEditingController();
  List<AyahSearchHit> _ayahResults = [];
  List<Surah> _surahResults = [];
  bool _loadingIndex = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    _loadIndex();
  }

  Future<void> _loadIndex() async {
    await ref.read(quranTextSearchRepositoryProvider).ensureLoaded();
    if (!mounted) return;
    setState(() {
      _loadingIndex = false;
      _surahResults = ref.read(catalogProvider).surahs;
    });
    _onQueryChanged();
  }

  Future<void> _onQueryChanged() async {
    if (_loadingIndex) return;
    final query = _controller.text;
    final catalog = ref.read(catalogProvider);
    final textRepo = ref.read(quranTextSearchRepositoryProvider);
    final ayah = await textRepo.search(query);
    if (!mounted) return;
    setState(() {
      _ayahResults = ayah;
      _surahResults = catalog.searchSurahs(query);
    });
  }

  Future<void> _openAyahHit(AyahSearchHit raw) async {
    final hit = ref.read(quranTextSearchRepositoryProvider).resolveHit(raw);
    await ref.read(readingProvider.notifier).goToSearchHit(
          page: hit.page,
          wordIds: hit.wordIds,
          surah: hit.surah,
          ayah: hit.sourceAyah,
        );
    if (kAudioEnabled && hit.sourceId.isNotEmpty) {
      final parts = hit.sourceId.split(':');
      if (parts.length == 2) {
        final surahId = int.tryParse(parts[0]);
        final ayah = int.tryParse(parts[1]);
        if (surahId != null && ayah != null) {
          await ref.read(audioProvider.notifier).seekToAyah(surahId, ayah);
        }
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _selectSurah(Surah surah) async {
    final catalog = ref.read(catalogProvider);
    final query = _controller.text;
    final ayah = catalog.ayahFromSearchQuery(query) ?? 1;
    ref.read(readingProvider.notifier).clearSearchHighlight();
    await ref.read(readingProvider.notifier).goToSurahStart(surah.id);
    if (kAudioEnabled) {
      await ref.read(audioProvider.notifier).seekToAyah(surah.id, ayah);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAyah = _ayahResults.isNotEmpty;
    final hasSurah = _surahResults.isNotEmpty && _controller.text.trim().isNotEmpty;
    final showSurahs = hasSurah && !hasAyah;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'كلمة، آية، 2:255 أو nom de sourate',
                    hintTextDirection: TextDirection.ltr,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_loadingIndex)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (hasAyah) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'آيات',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ..._ayahResults.map(
                          (hit) => ListTile(
                            leading: CircleAvatar(
                              child: Text('${hit.page}'),
                            ),
                            title: Text(
                              hit.displayText,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${hit.sourceId} · صفحة ${hit.page}',
                              textDirection: TextDirection.rtl,
                            ),
                            onTap: () => _openAyahHit(hit),
                          ),
                        ),
                      ],
                      if (showSurahs) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Sourates',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ..._surahResults.map(
                          (s) => ListTile(
                            leading: CircleAvatar(
                              child: Text('${s.id}'),
                            ),
                            title: Text(s.nameEn),
                            subtitle: Text(
                              '${s.nameAr} · page ${ref.read(catalogProvider).displayPageForSurah(s)}',
                              textDirection: TextDirection.rtl,
                            ),
                            onTap: () => _selectSurah(s),
                          ),
                        ),
                      ],
                      if (!hasAyah && !showSurahs && _controller.text.trim().isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Aucun résultat'),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
