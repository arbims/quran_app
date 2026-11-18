import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/reciters_data.dart';
import '../../providers/providers.dart';
import 'recitation_settings_sheet.dart';
import 'reciter_picker_sheet.dart';

/// Maquette `lecture1.jpg` — choix du mode d’écoute.
class ListeningSheet extends ConsumerWidget {
  const ListeningSheet({super.key});

  static const Color sheetBg = Color(0xFFFDF8EE);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ListeningSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reading = ref.watch(readingProvider);
    final audio = ref.watch(audioProvider);
    final catalog = ref.read(catalogProvider);
    final surah = catalog.surahById(audio.surah) ?? catalog.surahs.first;
    final reciter = kReciters.firstWhere(
      (r) => r.id == settings.reciterId,
      orElse: () => kReciters.first,
    );

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: sheetBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.headerBlue,
          brightness: Brightness.light,
          surface: sheetBg,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: AppColors.headerBlue,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الاستماع إلى التلاوة',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headerBlueDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'القارئ: ${reciter.nameAr}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.headerBlue.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _ListenRow(
                  title: 'استماع الصفحة',
                  subtitle: 'الصفحة ${reading.currentPage}',
                  icon: Icons.menu_book_outlined,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(audioProvider.notifier).playPage();
                  },
                ),
                const Divider(height: 1, indent: 56),
                _ListenRow(
                  title: 'استماع متواصل',
                  subtitle:
                      'من سورة ${surah.nameAr} - الآية ${audio.ayah}',
                  icon: Icons.playlist_play_rounded,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(audioProvider.notifier).playContinuous();
                  },
                ),
                const Divider(height: 1, indent: 56),
                _ListenRow(
                  title: 'إعدادات التلاوة',
                  subtitle: 'السرعة والتكرار',
                  icon: Icons.tune_rounded,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await RecitationSettingsSheet.show(context);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _ListenRow(
                  title: 'تغيير القارئ',
                  subtitle: reciter.nameAr,
                  icon: Icons.record_voice_over_outlined,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ReciterPickerSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListenRow extends StatelessWidget {
  const _ListenRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.headerBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.headerBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
