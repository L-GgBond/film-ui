import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A user-configured media source.
///
/// Mirrors the reference "CMS source" form for UI learning: name, type,
/// API endpoint, search mode, parse URL, group, category mapping, plus a list
/// of explicit playback URLs. The app stores this configuration; it does NOT
/// automatically fetch catalogs from arbitrary third-party endpoints.
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

  static List<MediaSourceCfg> defaults() => [
        MediaSourceCfg(name: '量子资源', urls: ['https://media.w3.org/2010/05/sintel/trailer.mp4']),
        MediaSourceCfg(name: '非凡资源', urls: ['https://www.w3schools.com/html/mov_bbb.mp4']),
        MediaSourceCfg(name: '明帝影视', urls: ['https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4']),
        MediaSourceCfg(name: '雷电影视', urls: ['https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4']),
        MediaSourceCfg(name: '本地资源', urls: ['https://test-videos.co.uk/vids/elephantsdream/mp4/h264/360/ElephantsDream_360_10s_1MB.mp4']),
        MediaSourceCfg(name: '星辰影视', urls: ['https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4']),
        MediaSourceCfg(name: '极光资源', urls: ['https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4']),
        MediaSourceCfg(name: '全网搜', urls: ['https://media.w3.org/2010/05/bunny/movie.mp4']),
        MediaSourceCfg(name: '云端解析', urls: ['https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4']),
      ];

  static Future<List<MediaSourceCfg>> loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSources);
    if (raw == null) return defaults();
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => MediaSourceCfg.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaults();
    }
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
}
