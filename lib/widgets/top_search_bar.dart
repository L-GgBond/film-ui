import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Search input shown at the top of the content area.
class TopSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const TopSearchBar({
    super.key,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, minWidth: 120),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '搜索影片、剧集...',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
