import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/source_store.dart';
import '../models/media.dart';
import 'http_util.dart';

/// Adapter for user-owned or authorized CMS-style video APIs.
///
/// Supports common MacCMS JSON responses and a conservative XML fallback. The
/// caller must provide endpoints they are allowed to use.
class CmsService {
  static const int _timeoutSeconds = 8;

  Future<List<MediaItem>> fetch(MediaSourceCfg source, {int page = 1}) async {
    final endpoint = source.endpoint.trim();
    if (endpoint.isEmpty) return const [];

    final uri = _catalogUri(endpoint, source.type, page);
    final res =
        await HttpUtil.get(uri, timeout: const Duration(seconds: _timeoutSeconds));
    if (res.statusCode != 200) {
      throw Exception('${source.name} HTTP ${res.statusCode}');
    }

    final body = utf8.decode(res.bodyBytes);
    if (source.type == 'cms-xml' || body.trimLeft().startsWith('<')) {
      return _parseXml(body, source);
    }
    return _parseJson(body, source);
  }

  Uri _catalogUri(String endpoint, String type, int page) {
    final uri = Uri.parse(endpoint);
    final query = Map<String, String>.from(uri.queryParameters);
    if (type == 'cms-json' || type == 'cms-xml') {
      query.putIfAbsent('ac', () => 'detail');
      query.putIfAbsent('pg', () => '$page');
    }
    return uri.replace(queryParameters: query);
  }

  /// 真实 CMS 搜索：MacCMS 约定使用 `?ac=detail&wd=关键词`。
  /// 复用与目录采集相同的解析逻辑（JSON / XML 自适应）。
  Future<List<MediaItem>> search(MediaSourceCfg source, String keyword) async {
    final endpoint = source.endpoint.trim();
    final kw = keyword.trim();
    if (endpoint.isEmpty || kw.isEmpty) return const [];

    final uri = _searchUri(endpoint, source.type, kw);
    final res =
        await HttpUtil.get(uri, timeout: const Duration(seconds: _timeoutSeconds));
    if (res.statusCode != 200) {
      throw Exception('${source.name} HTTP ${res.statusCode}');
    }
    final body = utf8.decode(res.bodyBytes);
    if (source.type == 'cms-xml' || body.trimLeft().startsWith('<')) {
      return _parseXml(body, source);
    }
    return _parseJson(body, source);
  }

  Uri _searchUri(String endpoint, String type, String keyword) {
    final uri = Uri.parse(endpoint);
    final query = Map<String, String>.from(uri.queryParameters);
    if (type == 'cms-json' || type == 'cms-xml') {
      query['ac'] = 'detail';
      query['wd'] = keyword;
    } else {
      // 非标准源：把关键词拼到 query 的 wd 字段，兼容多数自建 API。
      query['wd'] = keyword;
    }
    return uri.replace(queryParameters: query);
  }

  List<MediaItem> _parseJson(String body, MediaSourceCfg source) {
    final decoded = json.decode(body);
    final root = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final rawList =
        decoded is List ? decoded : root['list'] ?? root['data'] ?? root['items'] ?? root['videos'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map((raw) => _itemFromCmsMap(Map<String, dynamic>.from(raw), source))
        .whereType<MediaItem>()
        .toList();
  }

  List<MediaItem> _parseXml(String body, MediaSourceCfg source) {
    final videos = RegExp(r'<video\b[^>]*>([\s\S]*?)</video>', caseSensitive: false)
        .allMatches(body);
    return videos.map((match) {
      final block = match.group(1) ?? '';
      final data = {
        'vod_id': _tag(block, 'id') ?? _tag(block, 'vod_id'),
        'vod_name': _tag(block, 'name') ?? _tag(block, 'vod_name'),
        'type_name': _tag(block, 'type') ?? _tag(block, 'type_name'),
        'vod_pic': _tag(block, 'pic') ?? _tag(block, 'vod_pic'),
        'vod_remarks': _tag(block, 'note') ?? _tag(block, 'vod_remarks'),
        'vod_content': _tag(block, 'des') ?? _tag(block, 'vod_content'),
        'vod_play_url': _tag(block, 'dl') ?? _tag(block, 'vod_play_url'),
      };
      return _itemFromCmsMap(data, source);
    }).whereType<MediaItem>().toList();
  }

  String? _tag(String xml, String name) {
    final match = RegExp(
      '<$name\\b[^>]*>([\\s\\S]*?)</$name>',
      caseSensitive: false,
    ).firstMatch(xml);
    final value = match?.group(1);
    if (value == null) return null;
    return _cleanText(value);
  }

  MediaItem? _itemFromCmsMap(Map<String, dynamic> raw, MediaSourceCfg source) {
    final rawId = _first(raw, const ['vod_id', 'id', 'video_id']);
    final title = _first(raw, const ['vod_name', 'name', 'title']);
    if (title == null || title.trim().isEmpty) return null;

    final urls = _extractPlayUrls(
      _first(raw, const ['vod_play_url', 'play_url', 'url', 'urls']) ?? '',
    );
    final typeName = _first(raw, const ['type_name', 'class', 'category']) ?? '';

    return MediaItem(
      id: 'cms_${_stableId('${source.name}_${rawId ?? title}')}',
      title: _cleanText(title),
      category: _categoryFrom(typeName),
      status: _cleanText(_first(raw, const ['vod_remarks', 'remarks', 'note']) ?? '已采集'),
      coverColor: const Color(0xFF455A64),
      source: source.name,
      videoSources: urls,
      posterUrl: _absoluteUrl(_first(raw, const ['vod_pic', 'pic', 'poster', 'cover']), source.endpoint),
      overview: _short(_cleanText(_first(raw, const ['vod_content', 'content', 'desc', 'description']) ?? '')),
    );
  }

  String? _first(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  List<String> _extractPlayUrls(String raw) {
    final urls = <String>[];
    final parts = raw
        .split(RegExp(r'[\n#]+'))
        .expand((p) => p.split(r'$$$'))
        .expand((p) => p.split(','));
    for (final part in parts) {
      final text = part.trim();
      final candidate = text.contains(r'$') ? text.split(r'$').last.trim() : text;
      if (_isPlayable(candidate) && !urls.contains(candidate)) urls.add(candidate);
    }
    return urls;
  }

  bool _isPlayable(String url) {
    final lower = url.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) return false;
    return lower.contains('.m3u8') ||
        lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.flv') ||
        lower.contains('.mkv') ||
        lower.contains('.ts');
  }

  String _categoryFrom(String typeName) {
    final text = typeName.toLowerCase();
    if (text.contains('剧') || text.contains('tv') || text.contains('series')) return 'tv';
    if (text.contains('动漫') || text.contains('动画') || text.contains('anime')) return 'anime';
    if (text.contains('综艺') || text.contains('show') || text.contains('variety')) return 'variety';
    if (text.contains('纪录') || text.contains('documentary')) return 'doc';
    return 'movie';
  }

  String? _absoluteUrl(String? value, String endpoint) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final base = Uri.tryParse(endpoint);
    if (base == null || !base.hasScheme) return value;
    return base.resolve(value).toString();
  }

  String _cleanText(String value) => value
      .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();

  String _short(String value) {
    if (value.length <= 160) return value;
    return value.substring(0, 160);
  }

  String _stableId(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }
}
