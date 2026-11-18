import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/saved_page.dart';
import '../../providers/providers.dart';
import 'save_page_dialog.dart';

/// Feuille « الصفحات المحفوظة » (maquette `sauvgarde2.jpg`).
Future<void> showSavedPagesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SavedPagesSheet(),
  );
}

class SavedPagesSheet extends ConsumerStatefulWidget {
  const SavedPagesSheet({super.key});

  @override
  ConsumerState<SavedPagesSheet> createState() => _SavedPagesSheetState();
}

class _SavedPagesSheetState extends ConsumerState<SavedPagesSheet> {
  bool _selecting = false;
  final Set<String> _selected = {};

  String _countLabel(int n) {
    if (n == 0) return 'لا توجد صفحات محفوظة';
    if (n == 1) return 'صفحة واحدة محفوظة';
    if (n == 2) return 'صفحتان محفوظتان';
    if (n >= 3 && n <= 10) return '$n صفحات محفوظة';
    return '$n صفحة محفوظة';
  }

  Future<void> _openPage(SavedPage entry) async {
    await ref.read(readingProvider.notifier).setPage(entry.page);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _edit(SavedPage entry) async {
    await showSavePageDialog(context, editing: entry);
  }

  Future<void> _confirmDeleteOne(SavedPage entry) async {
    final title = entry.name.trim().isEmpty ? 'صفحة ${entry.page}' : entry.name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحفظ؟'),
          content: Text('هل تريد حذف «$title»؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ref.read(savedPagesProvider.notifier).remove(entry.id);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المحدد؟'),
          content: Text('حذف ${_selected.length} حفظ؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(savedPagesProvider.notifier).removeMany(_selected);
    setState(() {
      _selected.clear();
      _selecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedPagesProvider);
    final catalog = ref.watch(catalogProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.headerBlue),
                      ),
                      IconButton(
                        tooltip: _selecting ? 'حذف المحدد' : 'تحديد للحذف',
                        onPressed: saved.pages.isEmpty
                            ? null
                            : () async {
                                if (_selecting) {
                                  await _deleteSelected();
                                } else {
                                  setState(() => _selecting = true);
                                }
                              },
                        icon: Icon(
                          _selecting
                              ? Icons.delete_outline
                              : Icons.playlist_remove_outlined,
                          color: saved.pages.isEmpty
                              ? Colors.black26
                              : AppColors.headerBlue,
                        ),
                      ),
                      if (_selecting)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selecting = false;
                              _selected.clear();
                            });
                          },
                          child: const Text('إلغاء'),
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'الصفحات المحفوظة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.headerBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countLabel(saved.pages.length),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.headerBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.collections_bookmark,
                          color: AppColors.headerBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: saved.pages.isEmpty
                      ? const Center(
                          child: Text(
                            'احفظ صفحة من زر «حفظ» لإعادة قراءتها لاحقاً',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black45),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset),
                          itemCount: saved.pages.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = saved.pages[index];
                            final surah = catalog.surahForPage(entry.page);
                            final title = entry.name.trim().isEmpty
                                ? 'صفحة ${entry.page}'
                                : entry.name;
                            final selected = _selected.contains(entry.id);

                            return Dismissible(
                              key: ValueKey(entry.id),
                              direction: _selecting
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.red.shade700,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                await _confirmDeleteOne(entry);
                                return false;
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                leading: _selecting
                                    ? Checkbox(
                                        value: selected,
                                        activeColor: AppColors.headerBlue,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selected.add(entry.id);
                                            } else {
                                              _selected.remove(entry.id);
                                            }
                                          });
                                        },
                                      )
                                    : const Icon(
                                        Icons.bookmark,
                                        color: AppColors.sliderGold,
                                      ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'الصفحة ${entry.page} • سورة ${surah.nameAr}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: _selecting
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'تعديل',
                                            onPressed: () => _edit(entry),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.headerBlue,
                                              size: 20,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            onPressed: () =>
                                                _confirmDeleteOne(entry),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_left,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                onTap: () {
                                  if (_selecting) {
                                    setState(() {
                                      if (selected) {
                                        _selected.remove(entry.id);
                                      } else {
                                        _selected.add(entry.id);
                                      }
                                    });
                                    return;
                                  }
                                  _openPage(entry);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
