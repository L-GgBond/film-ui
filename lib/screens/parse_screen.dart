import 'package:flutter/material.dart';
import '../data/source_store.dart';
import '../theme/app_theme.dart';

/// Parse interface page: builds a request URL from the user's own configured
/// endpoints (UI + config demo only). Does NOT fetch any copyrighted content.
class ParseScreen extends StatefulWidget {
  const ParseScreen({super.key});

  @override
  State<ParseScreen> createState() => _ParseScreenState();
}

class _ParseScreenState extends State<ParseScreen> {
  List<MediaSourceCfg> _sources = [];
  int _selected = 0;
  final _urlCtrl = TextEditingController();
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SourceStore.loadSources();
    if (mounted) setState(() => _sources = s);
  }

  void _build() {
    if (_sources.isEmpty) {
      setState(() => _result = '尚未配置任何资源源，请先到设置中添加。');
      return;
    }
    final ep = _sources[_selected].endpoint;
    final url = _urlCtrl.text.trim();
    if (ep.isEmpty) {
      setState(() => _result = '该解析源未配置接口地址，请先到设置中填写 endpoint。');
      return;
    }
    if (url.isEmpty) {
      setState(() => _result = '请填入视频地址。');
      return;
    }
    final sep = ep.contains('?') ? '&' : '?';
    final req = '$ep$sepurl=${Uri.encodeComponent(url)}';
    setState(() {
      _result =
          '构造的请求 URL（仅演示，不会实际发送）：\n\n$req\n\n'
          '预期返回结构（示例）：\n{ "code": 200, "msg": "ok", "url": "（你的自有/授权播放地址）" }';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('解析接口'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '本页仅做请求构造与 UI 演示，不实际拉取版权内容。请在「设置 → 资源源配置」中填写你自有/已授权的接口地址。',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择解析源', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            const SizedBox(height: 6),
            if (_sources.isEmpty)
              const Text('（暂无资源源）', style: TextStyle(color: AppTheme.textSecondary))
            else
              DropdownButtonFormField<int>(
                value: _selected < _sources.length ? _selected : 0,
                items: _sources.asMap().entries.map((e) {
                  final s = e.value;
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text('${s.name}${s.endpoint.isEmpty ? '（未配置接口）' : ''}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selected = v ?? 0),
                dropdownColor: AppTheme.surface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text('视频地址 / 分享链接', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                hintText: '粘贴视频链接，如 https://example.com/video/123',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _build,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('构造请求'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0c0d10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceAlt),
                ),
                child: Text(
                  _result!,
                  style: const TextStyle(
                    color: Color(0xFF9fe0a0),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
