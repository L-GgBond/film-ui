import 'package:flutter/material.dart';
import '../data/source_store.dart';
import '../models/media.dart';
import 'archive.dart';
import 'cms_service.dart';
import 'tmdb.dart';

class CollectionResult {
  final List<MediaItem> items;
  final List<String> messages;

  const CollectionResult({
    required this.items,
    required this.messages,
  });
}

/// Collects real catalogs from legal/public or user-authorized sources.
class ResourceCollector {
  const ResourceCollector();

  Future<CollectionResult> collect({
    required List<MediaSourceCfg> sources,
    required String tmdbKey,
    int archiveRows = 24,
  }) async {
    final messages = <String>[];
    final collected = <MediaItem>[];

    try {
      final archive = await ArchiveService().fetchPublicDomain(rows: archiveRows);
      collected.addAll(archive);
      messages.add('Internet Archive：${archive.length} 部公共领域/CC 影片');
    } catch (e) {
      messages.add('Internet Archive 采集失败：$e');
    }

    final cmsSources = sources
        .where((s) => s.endpoint.trim().isNotEmpty && s.type != 'raw')
        .toList();
    for (final source in cmsSources) {
      try {
        final items = await CmsService().fetch(source);
        collected.addAll(items);
        messages.add('${source.name}：${items.length} 条');
      } catch (e) {
        messages.add('${source.name} 采集失败：$e');
      }
    }

    final rawItems = _rawLineItems(sources);
    collected.addAll(rawItems);
    if (rawItems.isNotEmpty) {
      messages.add('直链源：${rawItems.length} 条');
    }

    if (tmdbKey.trim().isNotEmpty) {
      try {
        final tmdb = await TmdbService(tmdbKey.trim()).fetchTrending();
        messages.add('TMDB：${tmdb.length} 条元数据已验证（不混入播放资源）');
      } catch (e) {
        messages.add('TMDB 采集失败：$e');
      }
    }

    final deduped = _dedupe(collected);
    if (deduped.isNotEmpty) {
      await SourceStore.saveCollectedItems(deduped);
    }

    return CollectionResult(items: deduped, messages: messages);
  }

  List<MediaItem> _rawLineItems(List<MediaSourceCfg> sources) {
    final out = <MediaItem>[];
    for (final source in sources.where((s) => s.type == 'raw')) {
      for (var i = 0; i < source.urls.length; i++) {
        final url = source.urls[i].trim();
        if (url.isEmpty) continue;
        out.add(MediaItem(
          id: 'raw_${source.name}_$i',
          title: source.urls.length == 1 ? source.name : '${source.name} ${i + 1}',
          category: 'movie',
          status: '直链资源',
          coverColor: const Color(0xFF455A64),
          source: source.name,
          videoSources: [url],
          overview: '用户配置的自有或授权播放直链。',
        ));
      }
    }
    return out;
  }

  List<MediaItem> _dedupe(List<MediaItem> items) {
    final seen = <String>{};
    final out = <MediaItem>[];
    for (final item in items) {
      final key = '${item.source}:${item.title}'.toLowerCase();
      if (seen.add(key)) out.add(item);
    }
    return out;
  }
}
