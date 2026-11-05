import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../data/source_store.dart';

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
  final String? id; // 用于观看历史去重；缺省回退到 title
  final String? posterUrl;
  final int initialPositionMs; // 续播：打开时跳转到上次进度

  const PlayerScreen({
    super.key,
    required this.title,
    required this.videoSources,
    this.episodes = const [],
    this.initialEpisode = 0,
    this.id,
    this.posterUrl,
    this.initialPositionMs = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  late Future<void> _initFuture;
  int _sourceIndex = 0;
  bool _showControls = true;
  bool _drawerOpen = false;
  int _episode = 0;
  double _speed = 1.0;
  bool _fullscreen = false;
  Timer? _hideTimer;
  final FocusNode _focusNode = FocusNode();

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _episode = widget.initialEpisode;
    // 单部电影：线路从 0 开始；连续剧：选集索引对可用源数取模，避免越界
    //（演示数据源数 < 集数时循环复用，而非全部回落到最后一集）。
    _sourceIndex = widget.episodes.isEmpty || widget.videoSources.isEmpty
        ? 0
        : widget.initialEpisode % widget.videoSources.length;
    _createController();
  }

  void _createController() {
    _hideTimer?.cancel();
    if (widget.videoSources.isEmpty) {
      _controller = null;
      _initFuture = Future.error('暂无可用播放地址');
      return;
    }
    final index = _sourceIndex.clamp(0, widget.videoSources.length - 1);
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoSources[index]));
    _controller = controller;
    _initFuture = controller.initialize().then((_) {
      // 用局部变量，避免切换线路时旧回调错误操作新控制器。
      if (mounted) {
        controller.setPlaybackSpeed(_speed);
        // 续播：打开时跳转到上次观看进度。
        if (widget.initialPositionMs > 0) {
          controller.seekTo(Duration(milliseconds: widget.initialPositionMs));
        }
        controller.play();
        _scheduleHide();
      }
    }).catchError((_) {
      // 初始化失败由 FutureBuilder 的 snapshot.hasError 统一展示。
    });
  }

  void _switchSource(int i) {
    if (i < 0 || i >= widget.videoSources.length || i == _sourceIndex) return;
    _controller?.dispose();
    setState(() {
      _sourceIndex = i;
      _showControls = true;
      _createController();
    });
  }

  void _selectEpisode(int i) {
    if (i < 0 || i >= widget.episodes.length) return;
    if (i == _episode && widget.episodes.isNotEmpty) return;
    _controller?.dispose();
    setState(() {
      _episode = i;
      // 选集对可用源数取模，源数不足时循环复用，避免越界只播最后一集。
      _sourceIndex = widget.episodes.isEmpty || widget.videoSources.isEmpty
          ? 0
          : i % widget.videoSources.length;
      _drawerOpen = false;
      _showControls = true;
      _createController();
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
      _showControls = true;
    });
    _scheduleHide();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final c = _controller;
    if (_showControls && c != null && c.value.isInitialized && c.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _setSpeed(double v) {
    final c = _controller;
    setState(() => _speed = v);
    if (c != null && c.value.isInitialized) c.setPlaybackSpeed(v);
  }

  // ---- 键盘快捷键（桌面 / Web）----
  // 空格：播放/暂停；←/→：快退/快进 10s；F：全屏切换；Esc：退出全屏或返回。
  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final c = _controller;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlay();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (c != null && c.value.isInitialized) {
        final target = c.value.position - const Duration(seconds: 10);
        c.seekTo(target < Duration.zero ? Duration.zero : target);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (c != null && c.value.isInitialized) {
        c.seekTo(c.value.position + const Duration(seconds: 10));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _toggleFullscreen();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_fullscreen) {
        _toggleFullscreen();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  // 全屏：横屏 + 沉浸式隐藏系统 UI；退出时恢复竖屏 + 正常 UI。
  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  String get _fullTitle =>
      widget.episodes.isEmpty ? widget.title : '${widget.title} · 第 ${_episode + 1} 集';

  @override
  void dispose() {
    _hideTimer?.cancel();
    // 退出时记录观看进度（按 id 去重，供首页「继续观看」续播）。
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      final pos = c.value.position.inMilliseconds;
      final dur = c.value.duration.inMilliseconds;
      if (pos > 0 && dur > 0) {
        SourceStore.recordWatch(
          id: widget.id ?? widget.title,
          title: widget.title,
          posterUrl: widget.posterUrl,
          videoSources: widget.videoSources,
          positionMs: pos,
          durationMs: dur,
        );
      }
    }
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _focusNode.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEp = widget.episodes.isNotEmpty;
    final isLast = _sourceIndex >= widget.videoSources.length - 1;
    final isLastEp = _episode >= widget.episodes.length - 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: _handleKey,
          child: Stack(
            children: [
          // video
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || _controller == null) {
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
                return GestureDetector(
                  onTap: _toggleControls,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
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
                    // 单部电影：切换播放线路；连续剧：选集即在抽屉内切换。
                    if (!hasEp)
                      PopupMenuButton<int>(
                        onSelected: _switchSource,
                        itemBuilder: (ctx) => List.generate(
                            widget.videoSources.length,
                            (i) => PopupMenuItem(
                                  value: i,
                                  child: Text(
                                      '线路 ${i + 1}${i == _sourceIndex ? ' ✓' : ''}'),
                                )),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('线路 ${_sourceIndex + 1}/${widget.videoSources.length}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                      ),
                    PopupMenuButton<double>(
                      onSelected: _setSpeed,
                      itemBuilder: (ctx) => _speeds
                          .map((s) => PopupMenuItem(
                                value: s,
                                child: Text(
                                    '${s == 1.0 ? '1.0' : s}x${s == _speed ? ' ✓' : ''}'),
                              ))
                          .toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_speed == 1.0 ? '1.0' : _speed}x',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      tooltip: '全屏 (F)',
                      onPressed: _toggleFullscreen,
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
                    _controller != null &&
                            _controller!.value.isInitialized &&
                            _controller!.value.isPlaying
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
                child: _controller != null && _controller!.value.isInitialized
                    ? VideoProgressIndicator(
                        _controller!,
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
                          const Text('选集',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
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
                              backgroundColor:
                                  active ? AppTheme.accent : const Color(0xFF262a33),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                                label.replaceFirst('第 ', '').replaceFirst(' 集', ''),
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
        ),
      ),
    );
  }
}
