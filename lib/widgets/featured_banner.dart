import 'package:flutter/material.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';

/// Horizontal "featured" carousel shown at the top of the home feed.
/// Each card uses a gradient (or real poster) backdrop with a title + play badge.
class FeaturedBanner extends StatelessWidget {
  final List<MediaItem> items;
  final ValueChanged<MediaItem> onTap;

  const FeaturedBanner({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final featured = items.take(6).toList();
    if (featured.isEmpty) return const SizedBox.shrink();
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW < 520 ? screenW - 32 : 320.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('🔥 精选推荐',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final it = featured[i];
              final poster = it.posterUrl;
              return GestureDetector(
                onTap: () => onTap(it),
                child: Container(
                  width: cardW,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        it.coverColor.withOpacity(0.9),
                        it.coverColor.withOpacity(0.5),
                      ],
                    ),
                    image: poster != null
                        ? DecorationImage(
                            image: NetworkImage(poster),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38, blurRadius: 12, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              it.status +
                                  (it.overview != null && it.overview!.isNotEmpty
                                      ? ' · ${it.overview!.length > 22 ? it.overview!.substring(0, 22) : it.overview!}'
                                      : ''),
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
