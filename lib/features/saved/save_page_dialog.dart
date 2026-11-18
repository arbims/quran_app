import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/saved_page.dart';
import '../../providers/providers.dart';

/// Dialogue « حفظ الصفحة » (maquette `sauvgarde1.jpg`).
Future<void> showSavePageDialog(
  BuildContext context, {
  SavedPage? editing,
  int? page,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => SavePageDialog(
      editing: editing,
      page: page,
    ),
  );
}

class SavePageDialog extends ConsumerStatefulWidget {
  const SavePageDialog({
    super.key,
    this.editing,
    this.page,
  });

  final SavedPage? editing;
  final int? page;

  static const int maxNameLength = 40;

  @override
  ConsumerState<SavePageDialog> createState() => _SavePageDialogState();
}

class _SavePageDialogState extends ConsumerState<SavePageDialog> {
  late final TextEditingController _controller;
  late final int _page;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _page = editing?.page ??
        widget.page ??
        ref.read(readingProvider).currentPage;
    _controller = TextEditingController(text: editing?.name ?? '');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _quickTags(String surahName) => [
        'للحفظ',
        'للمراجعة',
        'ورد اليوم',
        'سورة $surahName',
      ];

  Future<void> _save() async {
    final name = _controller.text.trim();
    final notifier = ref.read(savedPagesProvider.notifier);
    final editing = widget.editing;
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (editing != null) {
      await notifier.update(id: editing.id, name: name, page: _page);
    } else {
      final result = await notifier.upsert(page: _page, name: name);
      if (result.replaced && mounted) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث «${result.page.name}» → الصفحة ${result.page.page}',
              textDirection: TextDirection.rtl,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final surah = catalog.surahForPage(_page);
    final tags = _quickTags(surah.nameAr);
    final count = _controller.text.characters.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.fahrasBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.editing == null ? 'حفظ الصفحة' : 'تعديل الحفظ',
                          style: const TextStyle(
                            color: AppColors.headerBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الصفحة $_page • سورة ${surah.nameAr}',
                          style: TextStyle(
                            color: AppColors.headerBlue.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.headerBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      color: AppColors.headerBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                maxLength: SavePageDialog.maxNameLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: 'اسم الصفحة (اختياري)',
                  hintText: 'مثال: مراجعة سورة الكهف',
                  counterText: '$count/${SavePageDialog.maxNameLength}',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: const TextStyle(color: AppColors.headerBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.headerBlue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.headerBlue.withValues(alpha: 0.55),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.headerBlue,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    ActionChip(
                      label: Text(tag),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: AppColors.headerBlue.withValues(alpha: 0.35),
                      ),
                      labelStyle: const TextStyle(
                        color: AppColors.headerBlue,
                        fontSize: 13,
                      ),
                      onPressed: () {
                        _controller.text = tag;
                        _controller.selection = TextSelection.collapsed(
                          offset: tag.length,
                        );
                        setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.headerBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(
                        widget.editing == null ? 'حفظ' : 'تحديث',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.headerBlue,
                        fontSize: 16,
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
}
