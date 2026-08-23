import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/source_store.dart';
import '../models/media.dart';
import '../services/resource_collector.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/category_tabs.dart';
import '../widgets/top_search_bar.dart';
import '../widgets/media_grid.dart';
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
  String _activeSource = 'all';
  String _activeCategory = '最新';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  bool _loggedIn = false; // 登录门禁：仅登录后显示「用户管理」

  List<MediaItem> _items = [];
  bool _loading = true;
  bool _collecting = false;
  String _mode = 'demo';
  DateTime? _collectedAt;
  String? _collectMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Build the multi-line playback source list from user-configured raw links,
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
    final srcs = await SourceStore.loadSources();
    final autoCollect = await SourceStore.loadAutoCollect();
    final cached = await SourceStore.loadCollectedItems();
    final cachedAt = await SourceStore.loadCollectedAt();
    final playSources = _buildSources(srcs);

    if (mounted) {
      setState(() {
        _items = cached.isNotEmpty ? cached : _demoItems(playSources);
        _mode = cached.isNotEmpty ? 'cache' : 'demo';
        _collectedAt = cachedAt;
        _loading = false;
      });
    }

    if (autoCollect) {
      await _collectResources(silent: true);
    }
  }

  List<MediaItem> _demoItems(List<String> playSources) {
    return MockData.items
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
  }

  Future<void> _collectResources({bool silent = false}) async {
    if (_collecting) return;
    final key = await SourceStore.loadTmdbKey();
    final srcs = await SourceStore.loadSources();
    if (mounted) {
      setState(() {
        _collecting = true;
        if (!silent) _collectMessage = null;
      });
    }

    try {
      final result = await const ResourceCollector().collect(
        sources: srcs,
        tmdbKey: key,
      );
      if (!mounted) return;
      setState(() {
        if (result.items.isNotEmpty) {
          _items = result.items;
          _mode = 'collected';
          _collectedAt = DateTime.now();
        }
        _collectMessage = result.messages.join('；');
      });
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.items.isEmpty ? '未采集到可用资源' : '采集完成：${result.items.length} 部',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _collectMessage = '采集失败：$e');
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('采集失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  String get _modeLabel {
    switch (_mode) {
      case 'tmdb':
        return 'TMDB 实时';
      case 'archive':
        return '公共领域影视库';
      case 'collected':
        return '真实采集';
      case 'cache':
        return '采集缓存';
      default:
        return '演示数据';
    }
  }

  String get _statusText {
    final count = '${_items.length} 部';
    if (_collecting) return '采集中… · $count';
    final at = _collectedAt;
    if (at == null) return '$_modeLabel · $count';
    final mm = at.minute.toString().padLeft(2, '0');
    return '$_modeLabel · $count · ${at.hour}:$mm';
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
      final matchSource = _matchesSource(item);
      final matchQuery = _query.isEmpty || item.title.contains(_query);
      return matchCat && matchSource && matchQuery;
    }).toList();
  }

  bool _matchesSource(MediaItem item) {
    switch (_activeSource) {
      case 'archive':
        return item.source == 'Internet Archive';
      case 'cc':
        return item.status.contains('CC') || item.status.contains('公共领域');
      case 'cms':
        return item.id.startsWith('cms_');
      case 'raw':
        return item.status == '直链资源';
      case 'local':
        return item.source == '演示数据';
      case 'tmdb':
        return item.source == 'TMDB';
      default:
        return true;
    }
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Tooltip(
                          message: _collectMessage ?? '读取真实采集缓存；刷新会拉取公共领域/授权接口资源',
                          child: Text(
                            _loading ? '加载中…' : _statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '采集资源',
                        onPressed: _collecting ? null : () => _collectResources(),
                        icon: _collecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync, size: 20),
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
