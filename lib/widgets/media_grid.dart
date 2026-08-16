import 'package:flutter/material.dart';
import '../models/media.dart';
import 'media_card.dart';

/// Responsive poster grid. Column count adapts to the available width so the
/// same widget works on phones, tablets, desktop and web.
class MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final ValueChanged<MediaItem>? onTap;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const MediaGrid({
    super.key,
    required this.items,
    this.onTap,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 180px target card width, min 2 columns on small screens.
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 8);
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2 / 3,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => MediaCard(
            item: items[index],
            onTap: onTap == null ? null : () => onTap!(items[index]),
          ),
        );
      },
    );
  }
}
