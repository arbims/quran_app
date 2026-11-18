import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/page_appearance.dart';
import '../../providers/providers.dart';
import '../adkar/adkar_hub_screen.dart';
import '../hifz/hifz_setup_sheet.dart';

class QuranMenuSheet extends ConsumerWidget {
  const QuranMenuSheet({super.key});

  static const Color sheetBg = Color(0xFFFDF8EE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'القائمة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headerBlueDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.headerBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _ReminderCard(
                enabled: settings.readingReminder,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).setReadingReminder(v);
                },
              ),
              const SizedBox(height: 20),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: AppColors.headerBlue),
                    const SizedBox(width: 8),
                    Text(
                      'مظهر الصفحات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerBlueDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    // RTL : premier = à droite. عادي par défaut.
                    Expanded(
                      child: _AppearanceChip(
                        label: 'عادي',
                        selected:
                            settings.pageAppearance == PageAppearance.normal,
                        pageColor: Colors.white,
                        inkColor: Colors.black87,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setPageAppearance(PageAppearance.normal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AppearanceChip(
                        label: 'دافئ',
                        selected:
                            settings.pageAppearance == PageAppearance.warm,
                        pageColor: const Color(0xFFF3E9D1),
                        inkColor: const Color(0xFF2A2118),
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setPageAppearance(PageAppearance.warm),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AppearanceChip(
                        label: 'ليلي',
                        selected:
                            settings.pageAppearance == PageAppearance.night,
                        pageColor: const Color(0xFF1F1C18),
                        inkColor: const Color(0xFFF5EFE4),
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setPageAppearance(PageAppearance.night),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _MenuRow(
                title: 'الورد اليومي',
                subtitle: 'حدّد وردك اليومي',
                icon: Icons.track_changes_outlined,
                onTap: () => _soon(context),
              ),
              const Divider(height: 1),
              _MenuRow(
                title: 'أذكار وأدعية متنوعة',
                subtitle:
                    'أذكار الصباح والمساء والنوم وأدعية كل مناسبة',
                icon: Icons.auto_awesome_outlined,
                showChevron: true,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdkarHubScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _MenuRow(
                title: 'مساعد الحفظ (تجريبي)',
                subtitle: 'اقرأ من حفظك ودع الجهاز يتابعك',
                icon: Icons.psychology_outlined,
                showChevron: true,
                onTap: () {
                  Navigator.of(context).pop();
                  HifzSetupSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً')),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: AppColors.headerBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تذكير القراءة',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'كل سبت • 15:00',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeTrackColor: AppColors.headerBlue.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.headerBlue;
                }
                return null;
              }),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceChip extends StatelessWidget {
  const _AppearanceChip({
    required this.label,
    required this.selected,
    required this.pageColor,
    required this.inkColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color pageColor;
  final Color inkColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.headerBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: pageColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final width in const [1.0, 0.85, 0.7])
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 3,
                        width: 48 * width,
                        decoration: BoxDecoration(
                          color: inkColor.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.headerBlue
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.showChevron = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.headerBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_left,
                  color: AppColors.headerBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
