import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 登录页（UI 原型）：演示账号 admin / admin123。
/// 成功后 pop(true)，由 HomeScreen 接管「解锁用户管理」。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _loading = false;

  static const String _demoUser = 'admin';
  static const String _demoPass = 'admin123';

  void _submit() {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    // 模拟登录校验（UI 原型，无真实后端）
    setState(() {
      _loading = true;
      _error = null;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (u == _demoUser && p == _demoPass) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _loading = false;
          _error = '用户名或密码错误（演示账号 admin / admin123）';
        });
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w < 420 ? w * 0.9 : 360.0;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1014),
      body: Center(
        child: Container(
          width: cardW,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceAlt),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 20)),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '影视台',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '登录后可访问「用户管理」等后台功能',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(labelText: '用户名'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入用户名' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v == null || v.isEmpty ? '请输入密码' : null,
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    '演示账号 admin / 密码 admin123',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
