import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media.dart';

/// A user-configured media source.
///
/// Mirrors the reference "CMS source" form for UI learning: name, type,
/// API endpoint, search mode, parse URL, group, category mapping, plus a list
/// of explicit playback URLs. Non-raw endpoints are collected only when the
/// user has explicitly configured them.
class MediaSourceCfg {
  String name;

  /// Source type: 'raw' | 'cms-xml' | 'cms-json' | 'drpy-js0' | 'app-v3' | 'app-v1'
  String type;

  /// API / site endpoint provided by the user (empty by default).
  String endpoint;

  /// Search mode: 'off' | 'aggregate' | 'local'
  String searchMode;

  /// Optional parse / extractor URL.
  String parseUrl;

  /// Group / folder label.
  String group;

  /// Comma-separated category mapping.
  String categories;

  /// Explicit playback URLs (used as fallback lines when no parser is run).
  List<String> urls;

  MediaSourceCfg({
    required this.name,
    this.type = 'raw',
    this.endpoint = '',
    this.searchMode = 'off',
    this.parseUrl = '',
    this.group = '默认',
    this.categories = '',
    required this.urls,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'endpoint': endpoint,
        'searchMode': searchMode,
        'parseUrl': parseUrl,
        'group': group,
        'categories': categories,
        'urls': urls,
      };

  factory MediaSourceCfg.fromJson(Map<String, dynamic> j) => MediaSourceCfg(
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? 'raw',
        endpoint: j['endpoint'] as String? ?? '',
        searchMode: j['searchMode'] as String? ?? 'off',
        parseUrl: j['parseUrl'] as String? ?? '',
        group: j['group'] as String? ?? '默认',
        categories: j['categories'] as String? ?? '',
        urls: (j['urls'] as List?)?.map((e) => e as String).toList() ?? [],
      );
}

/// Persists the TMDB API key and the user's source list via SharedPreferences.
class SourceStore {
  static const String _kSources = 'vh_sources';
  static const String _kTmdb = 'vh_tmdb_key';
  static const String _kItems = 'vh_collected_items';
  static const String _kItemsAt = 'vh_collected_items_at';
  static const String _kAutoCollect = 'vh_auto_collect';
  static const String _kLoggedIn = 'vh_logged_in';
  static const String _kFavorites = 'vh_favorites';
  static const String _kHistory = 'vh_history';
  static const Map<String, String> _legacyNames = {
    '量子资源': 'Sintel 预告片',
    '非凡资源': 'Big Buck Bunny 样片',
    '明帝影视': 'Big Buck Bunny 开源电影',
    '雷电影视': 'Big Buck Bunny 10 秒测试',
    '本地资源': 'Elephants Dream 10 秒测试',
    '星辰影视': 'Jellyfish 10 秒测试',
    '极光资源': 'Sintel 10 秒测试',
    '全网搜': 'W3C Bunny',
    '云端解析': 'Google 示例视频',
  };

  static List<MediaSourceCfg> defaults() => [
        MediaSourceCfg(
          name: 'Sintel 预告片',
          urls: ['https://media.w3.org/2010/05/sintel/trailer.mp4'],
        ),
        MediaSourceCfg(
          name: 'Big Buck Bunny 样片',
          urls: ['https://www.w3schools.com/html/mov_bbb.mp4'],
        ),
        MediaSourceCfg(
          name: 'Big Buck Bunny 开源电影',
          urls: [
            'https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4',
          ],
        ),
        MediaSourceCfg(
          name: 'Big Buck Bunny 10 秒测试',
          urls: [
            'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
          ],
        ),
        MediaSourceCfg(
          name: 'Elephants Dream 10 秒测试',
          urls: [
            'https://test-videos.co.uk/vids/elephantsdream/mp4/h264/360/ElephantsDream_360_10s_1MB.mp4',
          ],
        ),
        MediaSourceCfg(
          name: 'Jellyfish 10 秒测试',
          urls: [
            'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
          ],
        ),
        MediaSourceCfg(
          name: 'Sintel 10 秒测试',
          urls: [
            'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
          ],
        ),
        MediaSourceCfg(
          name: 'W3C Bunny',
          urls: ['https://media.w3.org/2010/05/bunny/movie.mp4'],
        ),
        MediaSourceCfg(
          name: 'Google 示例视频',
          urls: [
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          ],
        ),
      ];

  static Future<List<MediaSourceCfg>> loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSources);
    if (raw == null) return defaults();
    try {
      final list = json.decode(raw) as List;
      return _migrateLegacyNames(list
          .map((e) => MediaSourceCfg.fromJson(e as Map<String, dynamic>))
          .toList());
    } catch (_) {
      return defaults();
    }
  }

  static List<MediaSourceCfg> _migrateLegacyNames(List<MediaSourceCfg> sources) {
    for (final source in sources) {
      final replacement = _legacyNames[source.name];
      if (replacement != null && source.endpoint.trim().isEmpty) {
        source.name = replacement;
      }
    }
    return sources;
  }

  static Future<void> saveSources(List<MediaSourceCfg> sources) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSources,
      json.encode(sources.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String> loadTmdbKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTmdb) ?? '';
  }

  static Future<void> saveTmdbKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTmdb, key);
  }

  static Future<bool> loadAutoCollect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoCollect) ?? true;
  }

  static Future<void> saveAutoCollect(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoCollect, value);
  }

  static Future<bool> loadLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> saveLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, value);
  }

  // ---- 收藏 / 稍后看 ----
  static Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavorites);
    if (raw == null) return const [];
    try {
      final list = json.decode(raw) as List;
      return list.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  /// 切换收藏状态，返回切换后是否处于收藏状态。
  static Future<bool> toggleFavorite(String id) async {
    final favs = await loadFavorites();
    final set = favs.toSet();
    final added = !set.contains(id);
    if (added) {
      set.add(id);
    } else {
      set.remove(id);
    }
    await saveFavorites(set.toList());
    return added;
  }

  static Future<void> saveFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFavorites, json.encode(ids));
  }

  // ---- 观看历史 / 续播 ----
  static Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistory);
    if (raw == null) return const [];
    try {
      final list = json.decode(raw) as List;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveHistory(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, json.encode(records));
  }

  /// 记录/更新一条观看进度（按 id 去重，最近观看置顶，最多保留 50 条）。
  static Future<void> recordWatch({
    required String id,
    required String title,
    String? posterUrl,
    required List<String> videoSources,
    required int positionMs,
    required int durationMs,
  }) async {
    final list = await loadHistory();
    list.removeWhere((r) => r['id'] == id);
    list.insert(0, {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'videoSources': videoSources,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if (list.length > 50) list.removeRange(50, list.length);
    await saveHistory(list);
  }

  static Future<List<MediaItem>> loadCollectedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kItems);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveCollectedItems(List<MediaItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kItems,
      json.encode(items.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_kItemsAt, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> loadCollectedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kItemsAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
