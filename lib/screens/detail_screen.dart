import 'package:flutter/material.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// Movie / series detail screen: backdrop poster, title, meta, overview,
/// and a mock episode / line list with a play button.
class DetailScreen extends StatelessWidget {
  final MediaItem item;
  final List<MediaItem> items;

  const DetailScreen({super.key, required this.item, required this.items});

  // Mock episode list for UI learning (no real catalog data involved).
  // 单部电影(movie)显示 1 条播放线路，其余类型（含 latest 连更剧集、
  // tv/anime/variety/doc）均展示选集。
  List<String> get _episodes {
    final n = switch (item.category) {
      'movie' => 1,
      'doc' => 6,
      _ => 12,
    };
    return List.generate(n, (i) => '第 ${i + 1} 集');
  }

  // Related recommendations: same category first, then fill with others.
  List<MediaItem> get _related {
    final same = items.where((o) => o != item && o.category == item.category).toList();
    if (same.length < 4) {
      same.addAll(items.where((o) => o != item && o.category != item.category));
    }
    return same.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final poster = item.posterUrl;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // backdrop: gradient (or poster if available)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.coverColor.withOpacity(0.9),
                          item.coverColor.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  if (poster != null)
                    Opacity(
                      opacity: 0.25,
                      child: Image.network(poster, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            item.coverColor.withOpacity(0.95),
                            item.coverColor.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: poster != null
                          ? Image.network(poster, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.movie_outlined, size: 36, color: Colors.white70)))
                          : const Center(
                              child: Icon(Icons.movie_outlined, size: 36, color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.status,
                              style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _play(context, 0),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('立即播放'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.overview != null && item.overview!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('简介', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(item.overview!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(_episodes.length > 1 ? '选集' : '播放线路',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ElevatedButton(
                  onPressed: () => _play(context, i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceAlt,
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_episodes[i]),
                ),
                childCount: _episodes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('相关推荐',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final rec = _related[i];
                  final poster = rec.posterUrl;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(item: rec, items: items),
                      ),
                    ),
                    child: Container(
                      width: 120,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.surfaceAlt,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    rec.coverColor.withOpacity(0.95),
                                    rec.coverColor.withOpacity(0.6),
                                  ],
                                ),
                                image: poster != null
                                    ? DecorationImage(
                                        image: NetworkImage(poster),
                                        fit: BoxFit.cover,
                                        onError: (_, __) {},
                                      )
                                    : null,
                              ),
                              child: poster == null
                                  ? const Center(
                                      child: Icon(Icons.movie_outlined,
                                          size: 28, color: Colors.white70))
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec.title,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(rec.status,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 11)),
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
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _play(BuildContext context, int epIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          videoSources: item.videoSources.isNotEmpty
              ? item.videoSources
              : const ['https://media.w3.org/2010/05/sintel/trailer.mp4'],
          episodes: _episodes.length > 1 ? _episodes : const [],
          initialEpisode: epIndex,
        ),
      ),
    );
  }
}
