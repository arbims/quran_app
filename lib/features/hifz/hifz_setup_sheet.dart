import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/hifz_enabled.dart';
import '../../core/theme/app_colors.dart';
import '../../data/surahs_data.dart';
import 'hifz_controller.dart';

/// Maquette `7ifd.jpg` — إعدادات مساعد الحفظ.
class HifzSetupSheet extends ConsumerWidget {
  const HifzSetupSheet({super.key});

  static const Color sheetBg = Color(0xFFFDF8EE);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HifzSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hifz = ref.watch(hifzProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.headerBlue,
          brightness: Brightness.light,
          surface: sheetBg,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
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
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              color: AppColors.headerBlue,
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    'مساعد الحفظ (تجريبي)',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.headerBlueDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'اقرأ من حفظك ودع الجهاز يتابعك',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5A5A5A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(
                                Icons.psychology_outlined,
                                color: AppColors.headerBlue,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: Color(0xFF2E7D32),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'هذا المساعد يعينك على المراجعة، ولا يغني عن العرض على شيخ لتصحيح التجويد والنطق.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'من أين تبدأ؟',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StartModeToggle(
                          mode: hifz.startMode,
                          onChanged: (m) =>
                              ref.read(hifzProvider.notifier).setStartMode(m),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hifz.startMode == HifzStartMode.currentPage
                              ? 'تبدأ من أول الصفحة المفتوحة أمامك'
                              : 'اختر السورة والآية للبداية',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (hifz.startMode == HifzStartMode.surahAyah) ...[
                          const SizedBox(height: 10),
                          _SurahAyahPickers(
                            surah: hifz.startSurah,
                            ayah: hifz.startAyah,
                            onChanged: (s, a) => ref
                                .read(hifzProvider.notifier)
                                .setStartSurahAyah(s, a),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          'خيارات العرض',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('إخفاء أرقام الآيات'),
                          subtitle: const Text('تبقى البسملة ظاهرة دائماً'),
                          value: hifz.hideAyahNumbers,
                          activeTrackColor:
                              AppColors.headerBlue.withValues(alpha: 0.45),
                          activeThumbColor: AppColors.headerBlue,
                          onChanged: (v) => ref
                              .read(hifzProvider.notifier)
                              .setHideAyahNumbers(v),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'كيف يعمل؟',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _HowRow(
                          icon: Icons.visibility_off_outlined,
                          text:
                              'تُخفى كلمات المقطع. اقرأ بصوت واضح، فتظهر الكلمة عندما يتعرّف عليها الجهاز بثبات، والأخطاء تُسطَّر بالأحمر.',
                        ),
                        const _HowRow(
                          icon: Icons.menu_book_outlined,
                          text:
                              'تابع القراءة كما تشاء؛ تُقلب الصفحات تلقائياً مع تقدّمك، ويمكنك الضغط على «إنهاء» في أي وقت.',
                        ),
                        const _HowRow(
                          icon: Icons.info_outline,
                          text:
                              'قد يخطئ التعرّف الآلي؛ الاختلاف وحده ليس بالضرورة خطأً منك، ولا يقيّم التشكيل أو التجويد أو جودة النطق.',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.headerBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: !kHifzEnabled
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await ref
                                    .read(hifzProvider.notifier)
                                    .startSession();
                              },
                        icon: const Icon(Icons.mic),
                        label: Text(
                          kHifzEnabled ? 'ابدأ' : 'غير متاح على الويب',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartModeToggle extends StatelessWidget {
  const _StartModeToggle({required this.mode, required this.onChanged});

  final HifzStartMode mode;
  final ValueChanged<HifzStartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: 'الصفحة الحالية',
              selected: mode == HifzStartMode.currentPage,
              onTap: () => onChanged(HifzStartMode.currentPage),
            ),
          ),
          Expanded(
            child: _Seg(
              label: 'سورة وآية',
              selected: mode == HifzStartMode.surahAyah,
              onTap: () => onChanged(HifzStartMode.surahAyah),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.headerBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.headerBlue : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}

class _SurahAyahPickers extends StatelessWidget {
  const _SurahAyahPickers({
    required this.surah,
    required this.ayah,
    required this.onChanged,
  });

  final int surah;
  final int ayah;
  final void Function(int surah, int ayah) onChanged;

  @override
  Widget build(BuildContext context) {
    final meta = kSurahs.firstWhere((s) => s.id == surah, orElse: () => kSurahs.first);
    final ayahCount = meta.ayahCount;
    final safeAyah = ayah.clamp(1, ayahCount);

    return Row(
      children: [
        Expanded(
          flex: 2,
                          child: DropdownButtonFormField<int>(
            // ignore: deprecated_member_use — value keeps surah/ayah in sync on rebuild
            value: meta.id,
            decoration: const InputDecoration(
              labelText: 'السورة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final s in kSurahs)
                DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.id}. ${s.nameAr}'),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              onChanged(v, 1);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
                          child: DropdownButtonFormField<int>(
            // ignore: deprecated_member_use — value keeps ayah in sync when surah changes
            value: safeAyah,
            decoration: const InputDecoration(
              labelText: 'الآية',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (var a = 1; a <= ayahCount; a++)
                DropdownMenuItem(value: a, child: Text('$a')),
            ],
            onChanged: (v) {
              if (v == null) return;
              onChanged(meta.id, v);
            },
          ),
        ),
      ],
    );
  }
}

class _HowRow extends StatelessWidget {
  const _HowRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.headerBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
