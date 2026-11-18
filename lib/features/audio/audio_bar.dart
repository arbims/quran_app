import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/reciters_data.dart';
import '../../providers/providers.dart';
import 'recitation_settings_sheet.dart';

/// Maquette `lecture2.jpg` — lecteur flottant pendant l’écoute.
class AudioBar extends ConsumerWidget {
  const AudioBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = ref.read(catalogProvider);
    final surah = catalog.surahById(audio.surah);
    final reciter = kReciters.firstWhere(
      (r) => r.id == settings.reciterId,
      orElse: () => kReciters.first,
    );

    final isPlaying = audio.status == AudioPlaybackStatus.playing;
    final isLoading = audio.status == AudioPlaybackStatus.loading;
    final isError = audio.status == AudioPlaybackStatus.error;
    final speedLabel = _speedLabel(audio.speed);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F1FA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isError
                              ? 'تعذّر تشغيل التلاوة'
                              : 'القارئ: ${reciter.nameAr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isError
                                ? const Color(0xFFB71C1C)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isError
                              ? 'تحقق من الاتصال ثم أعد المحاولة'
                              : 'سورة ${surah?.nameAr ?? ''} • الآية ${audio.ayah}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isError
                                ? const Color(0xFFC62828)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إعدادات التلاوة',
                    onPressed: () => RecitationSettingsSheet.show(context),
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.headerBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: AppColors.headerBlue,
                  inactiveTrackColor: AppColors.headerBlue.withValues(
                    alpha: 0.2,
                  ),
                  thumbColor: AppColors.headerBlue,
                ),
                child: Slider(
                  value: audio.progress,
                  onChanged: (v) {
                    ref.read(audioProvider.notifier).seekProgress(v);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'إيقاف',
                    onPressed: () => ref.read(audioProvider.notifier).stop(),
                    icon: const Icon(Icons.stop_rounded),
                    color: AppColors.headerBlueDark,
                  ),
                  IconButton(
                    tooltip: 'الآية السابقة',
                    onPressed: () =>
                        ref.read(audioProvider.notifier).previousAyah(),
                    icon: const Icon(Icons.skip_next_rounded),
                    color: AppColors.headerBlueDark,
                  ),
                  Material(
                    color: AppColors.headerBlue,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isLoading
                          ? null
                          : () => ref
                              .read(audioProvider.notifier)
                              .togglePlayPause(),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isError
                                      ? Icons.refresh_rounded
                                      : isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'الآية التالية',
                    onPressed: () =>
                        ref.read(audioProvider.notifier).nextAyah(),
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: AppColors.headerBlueDark,
                  ),
                  IconButton(
                    tooltip: 'تكرار الآية',
                    onPressed: () =>
                        ref.read(audioProvider.notifier).toggleRepeatAyah(),
                    icon: Icon(
                      audio.repeatAyah
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                    ),
                    color: audio.repeatAyah
                        ? AppColors.headerBlue
                        : AppColors.headerBlueDark,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(audioProvider.notifier).cycleSpeed(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.headerBlueDark,
                      minimumSize: const Size(40, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      speedLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _speedLabel(double speed) {
    if ((speed - 1.0).abs() < 0.01) return '1x';
    if (speed == speed.roundToDouble()) return '${speed.toInt()}x';
    return '${speed}x';
  }
}
