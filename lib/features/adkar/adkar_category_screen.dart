import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/adkar/adkar_data.dart';
import '../../data/adkar/adkar_models.dart';

class AdkarCategoryScreen extends StatelessWidget {
  const AdkarCategoryScreen({
    super.key,
    required this.category,
  });

  final AdkarCategory category;

  static const Color bg = Color(0xFFFDF8EE);

  @override
  Widget build(BuildContext context) {
    final items = adkarItemsForCategory(category.id);

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.headerBlue,
          foregroundColor: Colors.white,
          title: Text(
            category.titleAr,
            textDirection: TextDirection.rtl,
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdkarCard(item: item, index: index + 1),
            );
          },
        ),
      ),
    );
  }
}

class _AdkarCard extends StatelessWidget {
  const _AdkarCard({
    required this.item,
    required this.index,
  });

  final AdkarItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (item.reference != null)
                  Expanded(
                    child: Text(
                      item.reference!,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.headerBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.headerBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '× ${item.repeat}',
                    style: const TextStyle(
                      color: AppColors.headerBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.textAr,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 20,
                height: 1.8,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
