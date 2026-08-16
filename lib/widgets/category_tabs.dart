import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

/// Top category tabs: 最新 / 电影片 / 连续剧 / 更多
class CategoryTabs extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryTabs({
    super.key,
    required this.activeCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MockData.categories.map((cat) {
        final active = cat == activeCategory;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  active ? AppTheme.accent.withOpacity(0.16) : Colors.transparent,
              foregroundColor:
                  active ? AppTheme.accent : AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => onCategoryChanged(cat),
            child: Text(cat, style: const TextStyle(fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }
}
