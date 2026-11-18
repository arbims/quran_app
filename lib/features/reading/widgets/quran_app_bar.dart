import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QuranAppBar extends StatelessWidget {
  const QuranAppBar({
    super.key,
    required this.onMenu,
    required this.onSearch,
    this.onAudio,
  });

  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback? onAudio;

  static const String titleAr = 'القرآن الكريم';
  static const String subtitleAr = 'رواية قالون عن نافع المدني';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          if (onAudio != null)
            IconButton(
              onPressed: onAudio,
              icon: const Icon(
                Icons.headphones,
                color: AppColors.chromeForeground,
              ),
              tooltip: 'الصوت',
            )
          else
            const SizedBox(width: 8),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(
              Icons.search,
              color: AppColors.chromeForeground,
            ),
            tooltip: 'بحث',
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  titleAr,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: AppColors.chromeForeground,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                Text(
                  subtitleAr,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.chromeForegroundMuted,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(
              Icons.menu,
              color: AppColors.chromeForeground,
            ),
            tooltip: 'القائمة',
          ),
        ],
      ),
    );
  }
}
