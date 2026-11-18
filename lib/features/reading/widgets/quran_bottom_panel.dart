import 'package:flutter/material.dart';

import '../../../core/constants/mushaf_constants.dart';
import '../../../core/theme/app_colors.dart';

class QuranBottomPanel extends StatelessWidget {
  const QuranBottomPanel({
    super.key,
    required this.surahNameAr,
    required this.currentPage,
    required this.displayPage,
    required this.isBookmarked,
    required this.hasSavedPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageChanged,
    required this.onIndex,
    required this.onBookmark,
    required this.onSaved,
    required this.onNotes,
  });

  final String surahNameAr;
  final int currentPage;
  final int displayPage;
  final bool isBookmarked;
  final bool hasSavedPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onIndex;
  final VoidCallback onBookmark;
  final VoidCallback onSaved;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPage - MushafConstants.firstPage) /
        (MushafConstants.lastPage - MushafConstants.firstPage);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onNextPage,
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.chromeForeground,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'سورة $surahNameAr',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: AppColors.chromeForeground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OpenBookSideIcon(
                          isLeftPage: MushafConstants.isLeftPage(displayPage),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'الصفحة $displayPage',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: AppColors.chromeForegroundMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPreviousPage,
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.chromeForeground,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final page = MushafConstants.firstPage +
                    (v *
                            (MushafConstants.lastPage -
                                MushafConstants.firstPage))
                        .round();
                onPageChanged(page);
              },
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0x33FFFFFF)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.format_list_bulleted,
                    label: 'الفهرس',
                    onTap: onIndex,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: 'حفظ الصفحة',
                    onTap: onBookmark,
                    highlighted: isBookmarked,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.collections_bookmark_outlined,
                    label: 'الصفحات المحفوظة',
                    onTap: onSaved,
                    highlighted: hasSavedPage,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.edit_note_outlined,
                    label: 'ملاحظاتي',
                    onTap: onNotes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Icône « livre ouvert » : le feuillet actif (gauche/droite) est mis en avant.
/// Page 2 = gauche, puis alterne.
class _OpenBookSideIcon extends StatelessWidget {
  const _OpenBookSideIcon({required this.isLeftPage});

  final bool isLeftPage;

  @override
  Widget build(BuildContext context) {
    const active = AppColors.sliderGold;
    const idle = AppColors.chromeForegroundMuted;
    return SizedBox(
      width: 22,
      height: 16,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isLeftPage ? active : idle,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                border: Border.all(color: Colors.white54, width: 0.8),
              ),
            ),
          ),
          Container(width: 1.2, color: Colors.white70),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isLeftPage ? idle : active,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
                border: Border.all(color: Colors.white54, width: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: highlighted
                  ? AppColors.sliderGold
                  : AppColors.chromeForeground,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlighted
                    ? AppColors.sliderGold
                    : AppColors.chromeForegroundMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
