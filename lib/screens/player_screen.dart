import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Full-screen player with multiple playback sources, line/speed pickers,
/// and an episode drawer for series.
///
/// Sources are public/open-licensed sample streams only. In production replace
/// them with your own authorized content.
class PlayerScreen extends StatefulWidget {
  final String title;
  final List<String> videoSources;
  final List<String> episodes; // 选集标签；空列表 = 单部电影（播放线路）
  final int initialEpisode;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.videoSources,
    this.episodes = const [],
    this.initialEpisode = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initFuture;
  int _sourceIndex = 0;
  bool _showControls = true;
  bool _drawerOpen = false;
  int _episode = 0;
  double _speed = 1.0;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _episode = widget.initialEpisode;
    _createController();
  }

  void _createController() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoSources[_sourceIndex]),
    );
    _initFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setPlaybackSpeed(_speed);
        _controller.play();
      }
    });
  }

  void _switchSource(int i) {
    if (i == _sourceIndex) return;
    _controller.dispose();
    setState(() {
      _sourceIndex = i;
      _showControls = true;
      _createController();
    });
  }

  void _selectEpisode(int i) {
    setState(() {
      _episode = i;
      _sourceIndex = 0;
      _drawerOpen = false;
      _showControls = true;
      _createController();
    });
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _setSpeed(double v) {
    setState(() {
      _speed = v;
      if (_controller.value.isInitialized) _controller.setPlaybackSpeed(v);
    });
  }

  String get _fullTitle =>
      widget.episodes.isEmpty ? widget.title : '${widget.title} · 第 ${_episode + 1} 集';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _sourceIndex >= widget.videoSources.length - 1;
    final hasEp = widget.episodes.isNotEmpty;
    final isLastEp = _episode >= widget.episodes.length - 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // video
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.white38),
                          const SizedBox(height: 16),
                          const Text('当前线路加载失败', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          if (!isLast)
                            ElevatedButton(
                              onPressed: () => _switchSource(_sourceIndex + 1),
                              child: const Text('切换线路重试'),
                            )
                          else
                            const Text(
                              '所有公开线路均无法访问：可能为网络限制，建议替换为你的自有/授权视频源',
                              style: TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                );
              },
            ),
          ),
          // top bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.only(top: 40, bottom: 16, left: 8, right: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(_fullTitle,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                    ),
                    PopupMenuButton<int>(
                      onSelected: _switchSource,
                      itemBuilder: (ctx) => List.generate(widget.videoSources.length, (i) =>
                        PopupMenuItem(
                          value: i,
                          child: Text('线路 ${i + 1}${i == _sourceIndex ? ' ✓' : ''}'),
                        )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('线路 ${_sourceIndex + 1}/${widget.videoSources.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                    PopupMenuButton<double>(
                      onSelected: _setSpeed,
                      itemBuilder: (ctx) => _speeds.map((s) =>
                        PopupMenuItem(
                          value: s,
                          child: Text('${s == 1.0 ? '1.0' : s}x${s == _speed ? ' ✓' : ''}'),
                        )).toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_speed == 1.0 ? '1.0' : _speed}x',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                    if (hasEp)
                      IconButton(
                        icon: const Icon(Icons.list_alt, color: Colors.white),
                        tooltip: '选集',
                        onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
                      ),
                    if (hasEp && !isLastEp)
                      TextButton(
                        onPressed: () => _selectEpisode(_episode + 1),
                        child: const Text('下一集', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          // center play/pause
          if (_showControls)
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isInitialized && _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          // bottom progress
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: _controller.value.isInitialized
                    ? VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: AppTheme.accent,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          // episode drawer
          if (_drawerOpen)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 300,
              child: Container(
                color: const Color(0xFF0c0d10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF2c313a))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('选集', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => setState(() => _drawerOpen = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.all(12),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: widget.episodes.asMap().entries.map((e) {
                          final i = e.key;
                          final label = e.value;
                          final active = i == _episode;
                          return ElevatedButton(
                            onPressed: () => _selectEpisode(i),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active ? AppTheme.accent : const Color(0xFF262a33),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(label.replaceFirst('第 ', '').replaceFirst(' 集', ''),
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
