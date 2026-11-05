import 'package:flutter/material.dart';
import '../data/source_store.dart';
import '../theme/app_theme.dart';

/// Settings: TMDB API key + user-configurable source management.
///
/// Source form mirrors the reference CMS source dialog:
/// name, type (raw/cms/drpy/app), endpoint, search mode, parse URL, group,
/// category mapping, plus explicit playback URLs.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();
  List<MediaSourceCfg> _sources = [];
  bool _autoCollect = true;

  // 每个字段维护独立控制器，避免在 build() 内反复新建导致泄漏与光标跳动。
  final Map<int, TextEditingController> _nameC = {};
  final Map<int, TextEditingController> _endpointC = {};
  final Map<int, TextEditingController> _parseC = {};
  final Map<int, TextEditingController> _groupC = {};
  final Map<int, TextEditingController> _catC = {};
  final Map<String, TextEditingController> _urlC = {};

  TextEditingController _ctl(
          Map<int, TextEditingController> map, int i, String initial) =>
      map.putIfAbsent(i, () => TextEditingController(text: initial));

  TextEditingController _urlCtl(int i, int j, String initial) =>
      _urlC.putIfAbsent('$i:$j', () => TextEditingController(text: initial));

  void _disposeSourceControllers() {
    for (final c in _nameC.values) c.dispose();
    _nameC.clear();
    for (final c in _endpointC.values) c.dispose();
    _endpointC.clear();
    for (final c in _parseC.values) c.dispose();
    _parseC.clear();
    for (final c in _groupC.values) c.dispose();
    _groupC.clear();
    for (final c in _catC.values) c.dispose();
    _catC.clear();
    for (final c in _urlC.values) c.dispose();
    _urlC.clear();
  }

  static const List<Map<String, String>> _types = [
    {'value': 'raw', 'label': '直链源'},
    {'value': 'cms-xml', 'label': 'cms[xml]'},
    {'value': 'cms-json', 'label': 'cms[json]'},
    {'value': 'drpy-js0', 'label': 'drpy[js0]'},
    {'value': 'app-v3', 'label': 'app[v3]'},
    {'value': 'app-v1', 'label': 'app[v1]'},
  ];

  static const List<Map<String, String>> _searchModes = [
    {'value': 'off', 'label': '关闭'},
    {'value': 'aggregate', 'label': '聚合搜索'},
    {'value': 'local', 'label': '本站搜索'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _disposeSourceControllers();
    super.dispose();
  }

  Future<void> _load() async {
    final key = await SourceStore.loadTmdbKey();
    final srcs = await SourceStore.loadSources();
    final autoCollect = await SourceStore.loadAutoCollect();
    if (mounted) {
      setState(() {
        _keyController.text = key;
        _sources = srcs;
        _autoCollect = autoCollect;
      });
    }
  }

  Future<void> _save() async {
    await SourceStore.saveTmdbKey(_keyController.text.trim());
    await SourceStore.saveSources(_sources);
    await SourceStore.saveAutoCollect(_autoCollect);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _addSource() =>
      setState(() => _sources.add(MediaSourceCfg(name: '新资源源', urls: [''])));
  void _delSource(int i) {
    _disposeSourceControllers();
    setState(() => _sources.removeAt(i));
  }

  void _addUrl(int i) => setState(() => _sources[i].urls.add(''));
  void _delUrl(int i, int j) {
    _disposeSourceControllers();
    setState(() => _sources[i].urls.removeAt(j));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('TMDB API Key', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              hintText: '在 themoviedb.org 免费注册后获取 v3 API Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '仅拉取影片元数据（海报/简介/分类），不提供视频流。留空也会采集公共领域影片。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启动时自动采集'),
            subtitle: const Text(
              '打开后进入首页会后台刷新公共领域影片和你配置的授权接口。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _autoCollect,
            onChanged: (v) => setState(() => _autoCollect = v),
          ),
          const SizedBox(height: 20),
          const Text('资源源管理', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '填入你自有 / 已授权的接口或视频直链。cms[json]/cms[xml] 会参与自动采集；直链源作为播放兜底线路。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ..._sources.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctl(_nameC, i, s.name),
                            onChanged: (v) => s.name = v,
                            decoration: const InputDecoration(labelText: '* 名称'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _delSource(i),
                          child: const Text('删除源'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('类型', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Wrap(
                      spacing: 0,
                      children: _types.map((t) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: t['value']!,
                              groupValue: s.type,
                              onChanged: (v) => setState(() => s.type = v!),
                            ),
                            Text(t['label']!, style: const TextStyle(fontSize: 13)),
                          ],
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _ctl(_endpointC, i, s.endpoint),
                      onChanged: (v) => s.endpoint = v,
                      decoration: const InputDecoration(
                        labelText: '接口',
                        hintText: 'http://example.com/api.php/provide/vod/',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('搜索', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Wrap(
                      spacing: 0,
                      children: _searchModes.map((m) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: m['value']!,
                              groupValue: s.searchMode,
                              onChanged: (v) => setState(() => s.searchMode = v!),
                            ),
                            Text(m['label']!, style: const TextStyle(fontSize: 13)),
                          ],
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _ctl(_parseC, i, s.parseUrl),
                      onChanged: (v) => s.parseUrl = v,
                      decoration: const InputDecoration(labelText: '解析'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctl(_groupC, i, s.group),
                            onChanged: (v) => s.group = v,
                            decoration: const InputDecoration(labelText: '分组'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _ctl(_catC, i, s.categories),
                            onChanged: (v) => s.categories = v,
                            decoration: const InputDecoration(
                              labelText: '类别',
                              hintText: '逗号分隔',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('播放直链（作为兜底线路）',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ...s.urls.asMap().entries.map((u) {
                      final j = u.key;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlCtl(i, j, s.urls[j]),
                              onChanged: (v) => s.urls[j] = v,
                              decoration: const InputDecoration(
                                labelText: '视频直链 URL (mp4/m3u8)',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delUrl(i, j),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      );
                    }),
                    TextButton(
                      onPressed: () => _addUrl(i),
                      child: const Text('+ 添加 URL'),
                    ),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton(
            onPressed: _addSource,
            child: const Text('+ 添加资源源'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
