import 'package:flutter/material.dart';

/// Data model for a media item shown in the poster grid.
///
/// Items can come from local demo data, public-domain catalogs, or the user's
/// own authorized APIs. Playback URLs should only point to content the user is
/// allowed to distribute or view.
class MediaItem {
  final String id;
  final String title;
  final String category; // 'latest' | 'movie' | 'tv'
  final String status; // e.g. "更新至12集" / "全12集"
  final Color coverColor; // placeholder color for the poster
  final String source; // source name, e.g. "Internet Archive"
  final List<String> videoSources; // authorized playback URLs
  final String? posterUrl; // poster image url (optional)
  final String? overview; // short description (optional)

  const MediaItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.coverColor,
    required this.source,
    required this.videoSources,
    this.posterUrl,
    this.overview,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'status': status,
        'coverColor': coverColor.value,
        'source': source,
        'videoSources': videoSources,
        'posterUrl': posterUrl,
        'overview': overview,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '未命名',
        category: json['category'] as String? ?? 'movie',
        status: json['status'] as String? ?? '',
        coverColor: Color(json['coverColor'] as int? ?? 0xFF455A64),
        source: json['source'] as String? ?? '',
        videoSources: (json['videoSources'] as List?)
                ?.whereType<String>()
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            const [],
        posterUrl: json['posterUrl'] as String?,
        overview: json['overview'] as String?,
      );
}

/// A selectable media source shown in the left sidebar.
class MediaSource {
  final String id;
  final String name;
  final IconData icon;

  const MediaSource({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Top-level navigation entries shown in the sidebar.
class NavItem {
  final String id;
  final String label;
  final IconData icon;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
