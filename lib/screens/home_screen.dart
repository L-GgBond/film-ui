import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/source_store.dart';
import '../models/media.dart';
import '../services/tmdb.dart';
import '../services/archive.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/category_tabs.dart';
import '../widgets/top_search_bar.dart';
import '../widgets/media_grid.dart';
import 'player_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'parse_screen.dart';
import 'clip_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import '../widgets/featured_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeNav = 'movie';
  String _activeSource = 'quantum';
  String _activeCategory = '最新';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  bool _loggedIn = false; // 登录门禁：仅登录后显示「用户管理」

  List<MediaItem> _items = [];
  bool _loading = true;
  String _mode = 'mock';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Build the multi-line playback source list from user-configured sources,
  /// then append the public/open-licensed fallback streams.
  static List<String> _buildSources(List<MediaSourceCfg> srcs) {
    final urls = <String>[];
    for (final s in srcs) {
      for (final u in s.urls) {
        if (u.trim().isNotEmpty && !urls.contains(u)) urls.add(u.trim());
      }
    }
    for (final u in MockData.sourcePool) {
      if (!urls.contains(u)) urls.add(u);
    }
    return urls.isEmpty ? MockData.sourcePool.toList() : urls;
  }

  Future<void> _load() async {
    final key = await SourceStore.loadTmdbKey();
    final srcs = await SourceStore.loadSources();
    final playSources = _buildSources(srcs);

    // 1) 立刻渲染本地 mock，保证永远有内容可见（不卡在被墙的外源上）
    if (mounted) {
      setState(() {
        _items = MockData.items
            .map((e) => MediaItem(
                  id: e.id,
                  title: e.title,
                  category: e.category,
                  status: e.status,
                  coverColor: e.coverColor,
                  source: e.source,
                  videoSources: playSources,
                  posterUrl: e.posterUrl,
                  overview: e.overview,
                ))
            .toList();
        _mode = 'mock';
        _loading = false;
      });
    }

    // 2) 后台尝试 TMDB（有 key 时），成功则替换
    if (key.isNotEmpty) {
      try {
        final tmdb = TmdbService(key);
        final list = await tmdb.fetchTrending();
        if (list.isNotEmpty && mounted) {
          setState(() {
            _items = list
                .map((e) => MediaItem(
                      id: e.id,
                      title: e.title,
                      category: e.category,
                      status: e.status,
                      coverColor: e.coverColor,
                      source: e.source,
                      videoSources: playSources,
                      posterUrl: e.posterUrl,
                      overview: e.overview,
                    ))
                .toList();
            _mode = 'tmdb';
          });
        }
      } catch (e) {
        // keep mock
      }
    }

    // 3) 后台尝试 archive.org 公共领域影视（带超时，失败不阻塞）
    try {
      final arch = await ArchiveService().fetchPublicDomain();
      if (arch.isNotEmpty && mounted) {
        setState(() {
          _items = arch
              .map((e) => MediaItem(
                    id: e.id,
                    title: e.title,
                    category: e.category,
                    status: e.status,
                    coverColor: e.coverColor,
                    source: e.source,
                    // archive's own mp4 first, then open-licensed fallback lines.
                    videoSources: [...e.videoSources, ...playSources],
                    posterUrl: e.posterUrl,
                    overview: e.overview,
                  ))
              .toList();
          _mode = 'archive';
        });
      }
    } catch (e) {
      // keep previous (mock or tmdb)
    }
  }

  String get _modeLabel {
    switch (_mode) {
      case 'tmdb':
        return 'TMDB 实时';
      case 'archive':
        return '公共领域影视库';
      default:
        return '本地 mock';
    }
  }

  List<MediaItem> get _filtered {
    final categoryMap = {
      '最新': null, // all
      '电影片': 'movie',
      '连续剧': 'tv',
      '动漫': 'anime',
      '综艺': 'variety',
      '纪录片': 'doc',
      '更多': null, // all
    };
    final catKey = categoryMap[_activeCategory];
    return _items.where((item) {
      final matchCat = catKey == null || item.category == catKey;
      final matchQuery = _query.isEmpty || item.title.contains(_query);
      return matchCat && matchQuery;
    }).toList();
  }

  void _onNav(String id) {
    if (id == 'settings') {
      _openSettings();
      return;
    }
    if (id == 'parse') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParseScreen()),
      );
      return;
    }
    if (id == 'clip') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ClipScreen()),
      );
      return;
    }
    if (id == 'admin') {
      if (!_loggedIn) {
        _openLogin();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
      return;
    }
    setState(() {
      _activeNav = id;
      // 影视回到首页，电视切换到连续剧
      if (id == 'movie') _activeCategory = '最新';
      if (id == 'tv') _activeCategory = '连续剧';
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (ok == true && mounted) {
      setState(() => _loggedIn = true);
      if (_activeNav == 'admin') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      }
    }
  }

  void _logout() {
    setState(() {
      _loggedIn = false;
      if (_activeNav == 'admin') _activeNav = 'movie';
    });
  }

  void _openPlayer(MediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item, items: _items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = MediaQuery.of(context).size.width < 720;
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            activeNavId: _activeNav,
            activeSourceId: _activeSource,
            collapsed: collapsed,
            onNavChanged: _onNav,
            onSourceChanged: (id) => setState(() => _activeSource = id),
            showAdmin: _loggedIn,
            onLogin: _openLogin,
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: CategoryTabs(
                          activeCategory: _activeCategory,
                          onCategoryChanged: (c) =>
                              setState(() => _activeCategory = c),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _loading
                              ? '加载中…'
                              : _modeLabel + ' · ${_items.length} 部',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TopSearchBar(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              FeaturedBanner(
                                items: _items,
                                onTap: _openPlayer,
                              ),
                              MediaGrid(
                                items: _filtered,
                                onTap: _openPlayer,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
