import 'package:flutter/material.dart';
import '../models/media.dart';

/// Static mock data for learning UI only. No real copyrighted links.
class MockData {
  static const List<NavItem> navItems = [
    NavItem(id: 'movie', label: '影视', icon: Icons.movie_outlined),
    NavItem(id: 'tv', label: '电视', icon: Icons.live_tv_outlined),
    NavItem(id: 'parse', label: '解析', icon: Icons.hub_outlined),
    NavItem(id: 'clip', label: '过刻', icon: Icons.cut_outlined),
    NavItem(id: 'admin', label: '用户管理', icon: Icons.people_outline),
    NavItem(id: 'settings', label: '设置', icon: Icons.settings_outlined),
  ];

  static const List<MediaSource> sources = [
    MediaSource(id: 'all', name: '全部资源', icon: Icons.all_inbox_outlined),
    MediaSource(id: 'favorite', name: '我的收藏', icon: Icons.favorite_outlined),
    MediaSource(id: 'archive', name: '公共领域', icon: Icons.public),
    MediaSource(id: 'cc', name: 'CC 授权', icon: Icons.verified_outlined),
    MediaSource(id: 'cms', name: '自有 CMS', icon: Icons.storage_outlined),
    MediaSource(id: 'raw', name: '直链资源', icon: Icons.link_outlined),
    MediaSource(id: 'local', name: '本地资源', icon: Icons.folder_outlined),
    MediaSource(id: 'tmdb', name: 'TMDB 元数据', icon: Icons.movie_filter_outlined),
  ];

  static const List<String> categories = [
    '最新',
    '电影片',
    '连续剧',
    '动漫',
    '综艺',
    '纪录片',
    '更多',
  ];

  // 合法公开授权测试视频源（开源/CC，非版权影视内容）。多主机分布，国内相对可达。
  static const List<String> sourcePool = [
    'https://media.w3.org/2010/05/sintel/trailer.mp4',
    'https://www.w3schools.com/html/mov_bbb.mp4',
    'https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4',
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/elephantsdream/mp4/h264/360/ElephantsDream_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
    'https://media.w3.org/2010/05/bunny/movie.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  ];

  // 每条影片错位分配 4 条线路，覆盖不同主机，提升可访问概率。
  static List<String> _srcs(int i) {
    final n = sourcePool.length;
    return [
      sourcePool[i % n],
      sourcePool[(i + 2) % n],
      sourcePool[(i + 4) % n],
      sourcePool[n - 1],
    ];
  }

  // 真实且可达的开放授权（CC-BY）电影海报，来自 Blender 开源电影官方 CDN。
  // 用作默认封面（无 TMDB key 时），加载失败会自动回落渐变占位。
  static const List<String> posterPool = [
    'https://cloud.blender.org/static/films/big-buck-bunny/poster.jpg',
    'https://cloud.blender.org/static/films/sintel/poster.jpg',
    'https://cloud.blender.org/static/films/elephants-dream/poster.jpg',
    'https://cloud.blender.org/static/films/tears-of-steel/poster.jpg',
    'https://cloud.blender.org/static/films/cosmos-laundromat/poster.jpg',
    'https://cloud.blender.org/static/films/caminandes/poster.jpg',
    'https://cloud.blender.org/static/films/agent-327/poster.jpg',
    'https://cloud.blender.org/static/films/wing-it/poster.jpg',
    'https://cloud.blender.org/static/films/coffee-run/poster.jpg',
    'https://cloud.blender.org/static/films/sprite-fright/poster.jpg',
  ];

  static const List<List<dynamic>> _base = [
    ['1', '星际穿越者', 'latest', '更新至08集', Colors.indigo],
    ['2', '山海秘闻录', 'latest', '全24集', Colors.teal],
    ['3', '暗夜追凶', 'movie', 'HD高清', Colors.deepOrange],
    ['4', '云端之城', 'movie', 'HD高清', Colors.blueGrey],
    ['5', '荣耀时代', 'tv', '更新至32集', Colors.purple],
    ['6', '风起陇西', 'tv', '更新至12集', Colors.green],
    ['7', '深海回声', 'movie', 'HD高清', Colors.cyan],
    ['8', '岁月神偷', 'latest', '全10集', Colors.amber],
    ['9', '量子恋人', 'tv', '更新至05集', Colors.pink],
    ['10', '北境往事', 'movie', 'HD高清', Colors.brown],
    ['11', '光弧计划', 'latest', '更新至20集', Colors.lightBlue],
    ['12', '寂静海岸', 'tv', '全30集', Colors.blue],
    ['13', '明日边境', 'latest', '更新至03集', Colors.teal],
    ['14', '雾山谜案', 'latest', '全08集', Colors.deepPurple],
    ['15', '拾光记', 'latest', '更新至15集', Colors.pinkAccent],
    ['16', '破晓时分', 'latest', '全06集', Colors.indigoAccent],
    ['17', '星际尘埃', 'movie', 'HD高清', Colors.blueGrey],
    ['18', '红日', 'movie', 'HD高清', Colors.orange],
    ['19', '寒鸦之刃', 'movie', 'HD高清', Colors.deepOrange],
    ['20', '银翼编年', 'movie', 'HD高清', Colors.blueGrey],
    ['21', '长安十二时辰', 'tv', '更新至40集', Colors.green],
    ['22', '琅琊榜风云', 'tv', '全54集', Colors.lightGreen],
    ['23', '庆余年外传', 'tv', '更新至22集', Colors.green],
    ['24', '鹤唳华亭', 'tv', '全60集', Colors.teal],
    ['25', '灵笼', 'anime', '更新至12集', Colors.blue],
    ['26', '刺客伍六七', 'anime', '全20集', Colors.indigo],
    ['27', '镇魂街', 'anime', '更新至24集', Colors.blueAccent],
    ['28', '画江湖之不良人', 'anime', '全40集', Colors.indigo],
    ['29', '狐妖小红娘', 'anime', '更新至36集', Colors.blue],
    ['30', '一人之下', 'anime', '全30集', Colors.lightBlue],
    ['31', '奔跑吧', 'variety', '更新至12期', Colors.amber],
    ['32', '极限挑战', 'variety', '全10期', Colors.orange],
    ['33', '歌手2026', 'variety', '更新至08期', Colors.deepOrange],
    ['34', '喜剧之王单口季', 'variety', '全14期', Colors.orange],
    ['35', '地球脉动', 'doc', '全6集', Colors.teal],
    ['36', '蓝色星球', 'doc', '全7集', Colors.cyan],
    ['37', '人类星球', 'doc', '全8集', Colors.teal],
    ['38', '河西走廊', 'doc', '全10集', Colors.cyan],
  ];

  static final List<MediaItem> items = List.generate(_base.length, (i) {
    final b = _base[i];
    return MediaItem(
      id: b[0] as String,
      title: b[1] as String,
      category: b[2] as String,
      status: b[3] as String,
      coverColor: b[4] as Color,
      source: '演示数据',
      videoSources: _srcs(i),
      posterUrl: posterPool[i % posterPool.length],
    );
  });
}
