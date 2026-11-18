import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../hifz_controller.dart';
import '../hifz_setup_sheet.dart';

class HifzSessionBar extends ConsumerWidget {
  const HifzSessionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hifz = ref.watch(hifzProvider);
    final listening = hifz.phase == HifzPhase.listening;
    final preparing = hifz.phase == HifzPhase.preparing;
    final error = hifz.phase == HifzPhase.error;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFEBEE) : const Color(0xFFFDF8EE),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(
                preparing
                    ? Icons.hourglass_top_rounded
                    : error
                        ? Icons.error_outline_rounded
                        : Icons.mic_rounded,
                color: listening
                    ? Colors.redAccent
                    : error
                        ? const Color(0xFFC62828)
                        : AppColors.headerBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preparing
                          ? 'جاري تجهيز مساعد الحفظ…'
                          : listening
                              ? 'يستمع… اقرأ بوضوح'
                              : (hifz.errorMessage ?? 'مساعد الحفظ'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: error
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (listening) ...[
                      const SizedBox(height: 2),
                      Text(
                        'مكشوف ${hifz.revealedCount} • أخطاء ${hifz.mistakeCount}'
                        '${hifz.lastHeard.isEmpty ? '' : ' • ${hifz.lastHeard}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (error) ...[
                TextButton(
                  onPressed: () async {
                    await ref.read(hifzProvider.notifier).stopSession();
                    if (!context.mounted) return;
                    await HifzSetupSheet.show(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.headerBlue,
                  ),
                  child: const Text('إعادة'),
                ),
              ],
              TextButton(
                onPressed: () =>
                    ref.read(hifzProvider.notifier).stopSession(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      error ? const Color(0xFFC62828) : AppColors.headerBlue,
                ),
                child: Text(error ? 'إغلاق' : 'إنهاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
