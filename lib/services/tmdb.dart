import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media.dart';

/// TMDB (The Movie Database) public API client.
///
/// Used ONLY to fetch movie/TV metadata (poster, title, overview, category) —
/// this is a legal, metadata-only aggregation and does NOT provide video streams.
/// Get a free v3 API key at https://www.themoviedb.org/settings/api
class TmdbService {
  static const String _base = 'https://api.themoviedb.org/3';
  static const String _imgBase = 'https://image.tmdb.org/t/p/w500';

  final String apiKey;

  const TmdbService(this.apiKey);

  /// Fetch the weekly trending movies & TV shows (Chinese localized).
  Future<List<MediaItem>> fetchTrending() async {
    final uri = Uri.parse(
      '$_base/trending/all/week?api_key=$apiKey&language=zh-CN',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('TMDB HTTP ${res.statusCode}');
    }
    final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final results = (data['results'] as List).where((r) => r['poster_path'] != null);

    return results.map<MediaItem>((r) {
      final isTv = r['media_type'] == 'tv';
      return MediaItem(
        id: 'tmdb_${r['id']}',
        title: (r['title'] as String?) ?? (r['name'] as String?) ?? '未命名',
        category: isTv ? 'tv' : 'movie',
        status: isTv ? '剧集' : '电影',
        coverColor: const Color(0xFF455A64),
        source: 'TMDB',
        // videoSources are filled in by the caller (user-configured sources).
        videoSources: const [],
        posterUrl: '$_imgBase${r['poster_path']}',
        overview: (r['overview'] as String?) ?? '',
      );
    }).toList();
  }
}
