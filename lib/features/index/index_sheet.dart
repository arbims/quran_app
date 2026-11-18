import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/audio_enabled.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/hizb.dart';
import '../../data/models/juzz.dart';
import '../../data/models/surah.dart';
import '../../providers/providers.dart';

class IndexSheet extends ConsumerStatefulWidget {
  const IndexSheet({super.key});

  @override
  ConsumerState<IndexSheet> createState() => _IndexSheetState();
}

class _IndexSheetState extends ConsumerState<IndexSheet> {
  int _segment = 0;
  final _searchController = TextEditingController();
  List<Surah> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = ref.read(catalogProvider).surahs;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final catalog = ref.read(catalogProvider);
    setState(() {
      _filteredSurahs = catalog.searchSurahs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToSurah(Surah s) async {
    await ref.read(readingProvider.notifier).goToSurahStart(s.id);
    if (kAudioEnabled) {
      await ref.read(audioProvider.notifier).seekToAyah(s.id, 1);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _goToJuzz(Juzz j) async {
    await ref.read(readingProvider.notifier).goToJuzz(j.number);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _goToHizb(Hizb h) async {
    await ref.read(readingProvider.notifier).goToHizb(h.number);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: AppColors.fahrasBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.headerBlue,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'الفهرس',
                              style: TextStyle(
                                color: AppColors.headerBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${catalog.surahs.length} سورة',
                              style: TextStyle(
                                color: AppColors.headerBlue.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.headerBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.format_list_bulleted,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FahrasSegments(
                    index: _segment,
                    onChanged: (i) => setState(() => _segment = i),
                  ),
                ),
                if (_segment == 0) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: '...ابحث عن سورة',
                        hintTextDirection: TextDirection.rtl,
                        filled: true,
                        fillColor: AppColors.fahrasSearchFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black87),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black87),
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: AppColors.headerBlue,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Expanded(
                  child: switch (_segment) {
                    0 => ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(bottom: 12 + bottomInset),
                        itemCount: _filteredSurahs.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.fahrasDivider,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final s = _filteredSurahs[index];
                          final page = catalog.displayPageForSurah(s);
                          return _SurahRow(
                            surah: s,
                            displayPage: page,
                            onTap: () => _goToSurah(s),
                          );
                        },
                      ),
                    1 => ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(bottom: 12 + bottomInset),
                        itemCount: catalog.juzz.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.fahrasDivider,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final j = catalog.juzz[index];
                          return _JuzzRow(
                            juzz: j,
                            displayPage: catalog.displayPageForJuzz(j),
                            onTap: () => _goToJuzz(j),
                          );
                        },
                      ),
                    _ => ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(bottom: 12 + bottomInset),
                        itemCount: catalog.hizb.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.fahrasDivider,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final h = catalog.hizb[index];
                          return _HizbRow(
                            hizb: h,
                            displayPage: catalog.displayPageForHizb(h),
                            onTap: () => _goToHizb(h),
                          );
                        },
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FahrasSegments extends StatelessWidget {
  const _FahrasSegments({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['السور', 'الأجزاء', 'الأحزاب'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fahrasTabTrack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fahrasDivider),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: Material(
              color: selected ? AppColors.fahrasTabSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.headerBlue,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.displayPage});

  final int displayPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fahrasPageBadge,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ص $displayPage',
        style: const TextStyle(
          color: AppColors.headerBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.headerBlue,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.displayPage,
    required this.onTap,
  });

  final Surah surah;
  final int displayPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _PageBadge(displayPage: displayPage),
            Expanded(
              child: Text(
                'سورة ${surah.nameAr}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.headerBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NumberBadge(number: surah.id),
          ],
        ),
      ),
    );
  }
}

class _JuzzRow extends StatelessWidget {
  const _JuzzRow({
    required this.juzz,
    required this.displayPage,
    required this.onTap,
  });

  final Juzz juzz;
  final int displayPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _PageBadge(displayPage: displayPage),
            Expanded(
              child: Text(
                'الجزء ${juzz.number}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.headerBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NumberBadge(number: juzz.number),
          ],
        ),
      ),
    );
  }
}

class _HizbRow extends StatelessWidget {
  const _HizbRow({
    required this.hizb,
    required this.displayPage,
    required this.onTap,
  });

  final Hizb hizb;
  final int displayPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _PageBadge(displayPage: displayPage),
            Expanded(
              child: Text(
                'الحزب ${hizb.number}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.headerBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NumberBadge(number: hizb.number),
          ],
        ),
      ),
    );
  }
}
