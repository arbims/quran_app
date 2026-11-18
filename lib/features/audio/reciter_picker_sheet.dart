import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/reciters_data.dart';
import '../../providers/providers.dart';

class ReciterPickerSheet extends ConsumerWidget {
  const ReciterPickerSheet({super.key});

  static const Color sheetBg = Color(0xFFFDF8EE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(settingsProvider).reciterId;
    return Container(
      decoration: const BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.headerBlue,
                    ),
                    const Expanded(
                      child: Text(
                        'تغيير القارئ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headerBlueDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...kReciters.map((r) {
              final selected = selectedId == r.id;
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  title: Text(
                    r.nameAr,
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(r.name),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.headerBlue,
                        )
                      : null,
                  onTap: () async {
                    await ref
                        .read(settingsProvider.notifier)
                        .setReciterId(r.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
