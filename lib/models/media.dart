/// Data model for a media item shown in the poster grid.
///
/// All fields are mock/placeholder data used for UI learning only.
/// No real copyrighted resource links are involved.
class MediaItem {
  final String id;
  final String title;
  final String category; // 'latest' | 'movie' | 'tv'
  final String status; // e.g. "更新至12集" / "全12集"
  final Color coverColor; // placeholder color for the poster
  final String source; // mock source name, e.g. "量子资源"
  final List<String> videoSources; // public/open-licensed playback URLs (multi-line fallback)
  final String? posterUrl; // TMDB poster image url (optional)
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
