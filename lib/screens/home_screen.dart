import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../data/source_store.dart';
import '../models/media.dart';
import '../services/resource_collector.dart';
import '../services/cms_service.dart';
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
import 'player_screen.dart';
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

  Set<String> _favoriteIds = {}; // 收藏的影片 id 集合（用于心形状态 + 收藏源过滤）
  List<Map<String, dynamic>> _history = []; // 观看历史（用于首页「继续观看」）
  List<MediaSourceCfg> _cmsSearchSources = []; // 配置了可搜索的 CMS 源

  // 真实 CMS 搜索结果（null = 未发起搜索；非 null = 展示搜索结果视图）
  List<MediaItem>? _searchResults;
  bool _searching = false;
  String? _searchError;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final autoCollect = await SourceStore.loadAutoCollect();
    final cached = await SourceStore.loadCollectedItems();
    final cachedAt = await SourceStore.loadCollectedAt();
    final loggedIn = await SourceStore.loadLoggedIn();
    final favorites = await SourceStore.loadFavorites();
    final history = await SourceStore.loadHistory();
    final srcs = await SourceStore.loadSources();
    final cmsSearchSources = srcs
        .where((s) => s.endpoint.trim().isNotEmpty && s.searchMode != 'off')
        .toList();

    if (mounted) {
      setState(() {
        _items = cached.isNotEmpty ? cached : _demoItems();
        _mode = cached.isNotEmpty ? 'cache' : 'demo';
        _collectedAt = cachedAt;
        _loggedIn = loggedIn;
        _favoriteIds = favorites.toSet();
        _history = history;
        _cmsSearchSources = cmsSearchSources;
        _loading = false;
      });
    }

    // 采集缓存 6 小时内视为新鲜，避免每次冷启动都打 24+ 个网络请求。
    if (autoCollect &&
        (cachedAt == null ||
            DateTime.now().difference(cachedAt) >
                const Duration(hours: 6))) {
      await _collectResources(silent: true);
    }
  }

  List<MediaItem> _demoItems() {
    return MockData.items
        .map((e) => MediaItem(
              id: e.id,
              title: e.title,
              category: e.category,
              status: e.status,
              coverColor: e.coverColor,
              source: e.source,
              videoSources:
                  e.videoSources.isNotEmpty ? e.videoSources : MockData.sourcePool,
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
      final q = _query.toLowerCase();
      final matchQuery = _query.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          (item.overview?.toLowerCase().contains(q) ?? false);
      return matchCat && matchSource && matchQuery;
    }).toList();
  }

  bool _matchesSource(MediaItem item) {
    switch (_activeSource) {
      case 'favorite':
        return _favoriteIds.contains(item.id);
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

  Future<void> _toggleFavorite(MediaItem item) async {
    final added = await SourceStore.toggleFavorite(item.id);
    if (!mounted) return;
    setState(() {
      if (added) {
        _favoriteIds.add(item.id);
      } else {
        _favoriteIds.remove(item.id);
      }
    });
  }

  /// 返回播放页后，轻量刷新收藏 / 历史（只读 SharedPreferences，不触发采集）。
  Future<void> _reloadLocalState() async {
    final favorites = await SourceStore.loadFavorites();
    final history = await SourceStore.loadHistory();
    if (mounted) {
      setState(() {
        _favoriteIds = favorites.toSet();
        _history = history;
      });
    }
  }

  void _onSearchChanged(String v) {
    setState(() => _query = v);
    _searchDebounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () => _runSearch(v));
  }

  Future<void> _runSearch(String raw) async {
    final query = raw.trim();
    if (query.isEmpty || _cmsSearchSources.isEmpty) {
      if (mounted) setState(() => _searchResults = null);
      return;
    }
    if (mounted) {
      setState(() {
        _searching = true;
        _searchResults = [];
        _searchError = null;
      });
    }
    try {
      final results = <MediaItem>[];
      for (final src in _cmsSearchSources) {
        try {
          final items = await CmsService().search(src, query);
          results.addAll(items);
        } catch (_) {
          // 单源失败不阻断整体搜索
        }
      }
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchError = '搜索失败：$e';
          _searching = false;
        });
      }
    }
  }

  /// 首页「继续观看」横向卡片行；仅默认视图（全部资源 + 无搜索词）显示。
  Widget _buildHistoryRow() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('继续观看',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final rec = _history[i];
              final poster = rec['posterUrl'] as String?;
              final title = (rec['title'] as String?) ?? '';
              final pos = (rec['positionMs'] as int? ?? 0);
              final dur = (rec['durationMs'] as int? ?? 0);
              final progress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
              final sources = (rec['videoSources'] as List?)?.whereType<String>().toList() ?? const <String>[];
              return GestureDetector(
                onTap: () {
                  if (sources.isEmpty) return;
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            title: title,
                            id: rec['id'] as String?,
                            posterUrl: poster,
                            videoSources: sources,
                            initialPositionMs: pos,
                          ),
                        ),
                      )
                      .then((_) => _reloadLocalState());
                },
                child: Container(
                  width: 160,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.surface,
                  ),
                  child: Stack(
                    children: [
                      if (poster != null)
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: poster,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            errorWidget: (_, __, ___) =>
                                Container(color: AppTheme.surfaceAlt),
                          ),
                        )
                      else
                        const Positioned.fill(
                            child: ColoredBox(color: AppTheme.surfaceAlt)),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('续播',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white38,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.accent),
                                minHeight: 4,
                              ),
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

  Widget _buildSearchView() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_searchError ?? '未找到匹配的影片（可能该 CMS 源无结果或不可达）',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('搜索结果 · ${_searchResults!.length} 条',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ),
          MediaGrid(
            items: _searchResults!,
            onTap: (item) => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(item: item, items: _items),
                  ),
                )
                .then((_) => _reloadLocalState()),
            favoriteIds: _favoriteIds,
            onToggleFavorite: _toggleFavorite,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    final showHistory =
        _activeSource == 'all' && _query.isEmpty && _history.isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (showHistory) _buildHistoryRow(),
          FeaturedBanner(
            items: _items,
            onTap: _openPlayer,
          ),
          MediaGrid(
            items: _filtered,
            onTap: _openPlayer,
            favoriteIds: _favoriteIds,
            onToggleFavorite: _toggleFavorite,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
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
      await SourceStore.saveLoggedIn(true);
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
    SourceStore.saveLoggedIn(false);
  }

  void _openPlayer(MediaItem item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DetailScreen(item: item, items: _items),
          ),
        )
        .then((_) => _reloadLocalState());
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
                      Flexible(
                        child: TopSearchBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults != null
                          ? _buildSearchView()
                          : _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search_off,
                                          size: 48, color: AppTheme.textSecondary),
                                      const SizedBox(height: 12),
                                      Text('未找到匹配的影片',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                )
                              : _buildHomeView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
