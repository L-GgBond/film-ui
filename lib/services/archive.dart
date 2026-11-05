import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/media.dart';

/// Internet Archive public-domain / CC film library client.
///
/// Pulls REAL, legally-playable open films (Open_Source_Movies / Prelinger
/// collections) via the archive.org public search + metadata APIs.
/// This is the same legal, public-domain route used by the HTML preview and
/// contains NO copyrighted-platform streams.
class ArchiveService {
  static const String _searchBase = 'https://archive.org/advancedsearch.php';
  static const String _metadataBase = 'https://archive.org/metadata/';
  static const String _downloadBase = 'https://archive.org/download/';
  static const String _imgBase = 'https://archive.org/services/img/';

  /// Fetch a list of public-domain / CC films with real playback URLs.
  Future<List<MediaItem>> fetchPublicDomain({int rows = 16}) async {
    final q = Uri.encodeComponent('collection:(Open_Source_Movies OR Prelinger)');
    final searchUrl = Uri.parse(
      '$_searchBase?q=$q'
      '&fl[]=identifier&fl[]=title&fl[]=year&fl[]=description&fl[]=downloads'
      '&rows=$rows&output=json&sort[]=downloads+desc',
    );
    final res = await http.get(searchUrl).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('archive.org HTTP ${res.statusCode}');
    }
    final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final response = data['response'] as Map<String, dynamic>?;
    final docs = (response?['docs'] as List?) ?? [];

    // Resolve each identifier's mp4 in parallel (bounded by rows).
    final results = await Future.wait(docs.map(_buildItem));
    return results.whereType<MediaItem>().toList();
  }

  static Future<MediaItem?> _buildItem(dynamic d) async {
    final doc = d as Map<String, dynamic>;
    final id = doc['identifier'] as String? ?? '';
    if (id.isEmpty) return null;
    try {
      final mdRes = await http.get(Uri.parse('$_metadataBase$id'))
          .timeout(const Duration(seconds: 6));
      if (mdRes.statusCode != 200) return null;
      final md = json.decode(utf8.decode(mdRes.bodyBytes)) as Map<String, dynamic>;
      final files = (md['files'] as List?) ?? [];

      String? mp4Name;
      for (final f in files) {
        final name = (f as Map<String, dynamic>)['name'] as String? ?? '';
        final lower = name.toLowerCase();
        if (lower.endsWith('.mp4') && !lower.contains('sample')) {
          mp4Name = name;
          break;
        }
      }
      if (mp4Name == null) return null;

      final url = '$_downloadBase$id/${Uri.encodeComponent(mp4Name)}';
      final thumb = '$_imgBase$id';
      final year = doc['year']?.toString();
      final descRaw = doc['description'] as String? ?? '';
      final desc = descRaw.replaceAll(RegExp(r'<[^>]+>'), '');

      return MediaItem(
        id: 'ia_$id',
        title: (doc['title'] as String?) ?? id,
        category: 'movie',
        status: (year != null && year.isNotEmpty ? '$year · ' : '') + '公共领域',
        coverColor: const Color(0xFF455A64),
        source: 'Internet Archive',
        // Primary playback URL first; caller appends open-licensed fallback lines.
        videoSources: [url],
        posterUrl: thumb,
        overview: desc.length > 140 ? desc.substring(0, 140) : desc,
      );
    } catch (_) {
      return null;
    }
  }
}
