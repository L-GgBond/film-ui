import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

/// Short-video / clip page: a grid of mock clips (cover reuses open-license
/// posters). Playback is a UI placeholder.
class ClipScreen extends StatelessWidget {
  const ClipScreen({super.key});

  static const List<Map<String, String>> _clips = [
    {'t': '高燃混剪 · 宇宙篇', 'd': '00:38', 'v': '12.3万'},
    {'t': '治愈系日落合集', 'd': '01:12', 'v': '8.6万'},
    {'t': '街舞 battle 名场面', 'd': '00:45', 'v': '23.1万'},
    {'t': '一镜到底挑战', 'd': '00:22', 'v': '5.4万'},
    {'t': '美食快剪', 'd': '00:56', 'v': '9.9万'},
    {'t': '萌宠日常', 'd': '00:31', 'v': '31.7万'},
    {'t': '旅行 vlog 精选', 'd': '01:40', 'v': '4.2万'},
    {'t': '游戏高光时刻', 'd': '00:28', 'v': '18.5万'},
    {'t': '手势舞教程', 'd': '00:50', 'v': '7.1万'},
    {'t': '极简动画短片', 'd': '01:05', 'v': '15.0万'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('过刻剪辑'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 9 / 16,
        children: _clips.asMap().entries.map((e) {
          final c = e.value;
          final poster = MockData.posterPool[e.key % MockData.posterPool.length];
          return GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('短片播放为 UI 占位')),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(poster),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.play_arrow, color: Colors.white70, size: 28),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c['d']!,
                              style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(c['t']!,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${c['v']}次播放',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
