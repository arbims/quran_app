import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/mushaf_constants.dart';
import '../../core/platform/audio_enabled.dart';
import '../../core/platform/reading_system_ui.dart';
import '../../core/theme/page_appearance.dart';
import '../../providers/providers.dart';
import '../audio/audio_bar.dart';
import '../audio/listening_sheet.dart';
import '../hifz/widgets/hifz_session_bar.dart';
import '../index/index_sheet.dart';
import '../menu/quran_menu_sheet.dart';
import '../saved/save_page_dialog.dart';
import '../saved/saved_pages_sheet.dart';
import '../search/search_sheet.dart';
import 'widgets/mushaf_page_curl.dart';
import 'widgets/mushaf_page_view.dart';
import 'widgets/quran_app_bar.dart';
import 'widgets/quran_bottom_panel.dart';
import 'widgets/quran_chrome_bar.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final MushafPageCurlController _curlController = MushafPageCurlController();

  @override
  void initState() {
    super.initState();
    // Empêche la mise en veille pendant la lecture du mushaf.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchSheet(),
    );
  }

  void _openIndex() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IndexSheet(),
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuranMenuSheet(),
    );
  }

  void _openListening() {
    ListeningSheet.show(context);
  }

  /// Mushaf RTL : avancer = pli vers la droite, reculer = pli vers la gauche.
  void _previousPage() => _curlController.previous();

  void _nextPage() => _curlController.next();

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(readingProvider);
    final settings = ref.watch(settingsProvider);
    final audio = kAudioEnabled ? ref.watch(audioProvider) : null;
    final hifz = ref.watch(hifzProvider);

    ref.listen(readingProvider.select((s) => s.currentPage), (prev, next) {
      if (prev != next && kAudioEnabled) {
        ref.read(audioProvider.notifier).syncWithPage(next);
      }
      if (prev != next && hifz.active) {
        ref.read(hifzProvider.notifier).onReadingPageChanged(next);
      }
    });

    final catalog = ref.read(catalogProvider);
    final surah = catalog.surahForPage(reading.currentPage);
    final saved = ref.watch(savedPagesProvider);
    final isBookmarked = saved.containsPage(reading.currentPage);
    final showMenus = reading.toolbarVisible;
    final showAudioBar =
        !hifz.active && kAudioEnabled && (audio?.panelVisible ?? false);
    final showHifzBar = hifz.active;
    final appearance = settings.pageAppearance;
    final mushafBg = appearance.mushafBackground;
    final viewPadding = MediaQuery.viewPaddingOf(context);

    final systemUi = readingSystemUi(
      menusVisible: showMenus,
      mushafBackground: mushafBg,
    );

    final pageIndex = MushafConstants.pageIndexFromFilePage(reading.currentPage);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUi,
      child: Scaffold(
        backgroundColor: mushafBg,
        body: Column(
          children: [
            if (!showMenus) SizedBox(height: viewPadding.top),
            if (showMenus)
              QuranChromeBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: viewPadding.top,
                      width: double.infinity,
                    ),
                    QuranAppBar(
                      onMenu: _openMenu,
                      onSearch: _openSearch,
                      onAudio: kAudioEnabled ? _openListening : null,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  reading.ready
                      ? MushafPageView(
                          curlController: _curlController,
                          pageIndex: pageIndex,
                          backgroundColor: mushafBg,
                          colorFilter: appearance.mushafColorFilter,
                          fullScreen: !showMenus,
                          onTap: () {
                            final audioBusy = kAudioEnabled &&
                                ref.read(audioProvider).isActive;
                            if (!audioBusy) {
                              ref
                                  .read(readingProvider.notifier)
                                  .clearSearchHighlight();
                            }
                            ref.read(readingProvider.notifier).toggleToolbar();
                          },
                          onPageChanged: (page) {
                            final audioBusy = kAudioEnabled &&
                                ref.read(audioProvider).isActive;
                            if (!audioBusy) {
                              ref
                                  .read(readingProvider.notifier)
                                  .clearSearchHighlight();
                            }
                            ref.read(readingProvider.notifier).setPage(
                                  page,
                                  keepSearchHighlight: audioBusy,
                                );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                  if (showAudioBar)
                    const Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: AudioBar(),
                    ),
                  if (showHifzBar)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: HifzSessionBar(),
                    ),
                ],
              ),
            ),
            if (!showMenus) SizedBox(height: viewPadding.bottom),
            if (showMenus)
              QuranChromeBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuranBottomPanel(
                      surahNameAr: surah.nameAr,
                      currentPage: reading.currentPage,
                      displayPage: reading.currentPage,
                      isBookmarked: isBookmarked,
                      hasSavedPage: saved.pages.isNotEmpty,
                      onPreviousPage: _previousPage,
                      onNextPage: _nextPage,
                      onPageChanged: (page) {
                        ref.read(readingProvider.notifier).setPage(page);
                      },
                      onIndex: _openIndex,
                      onBookmark: () {
                        showSavePageDialog(
                          context,
                          page: reading.currentPage,
                        );
                      },
                      onSaved: () => showSavedPagesSheet(context),
                      onNotes: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ملاحظاتي — قريباً إن شاء الله'),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: viewPadding.bottom,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
