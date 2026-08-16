import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 用户管理（后台）页面 —— UI 学习用途，数据为本地 mock，无真实后端。
/// 支持：查看用户明细、调整角色权限、生成临时密码、启用 / 禁用账号。

enum UserRole { user, vip, admin }
enum UserStatus { active, disabled }

class AppUser {
  final int id;
  final String name;
  final String email;
  UserRole role;
  UserStatus status;
  final String registered;
  final String lastActive;
  final int logins;
  final String ip;
  final String device;
  final String region;
  final String plan;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.registered,
    required this.lastActive,
    required this.logins,
    required this.ip,
    required this.device,
    required this.region,
    required this.plan,
  });
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // mock 用户数据（仅演示）
  final List<AppUser> _users = [
    AppUser(id: 1, name: '影迷小王', email: 'xiaowang@example.com', role: UserRole.user, status: UserStatus.active, registered: '2025-11-03', lastActive: '2026-08-16 09:12', logins: 142, ip: '116.22.31.8', device: 'iPhone 15 Pro', region: '广东·深圳', plan: '免费'),
    AppUser(id: 2, name: '追剧狂魔', email: 'zhuiju@example.com', role: UserRole.vip, status: UserStatus.active, registered: '2025-09-18', lastActive: '2026-08-16 08:40', logins: 530, ip: '223.104.5.22', device: 'iPad Air', region: '浙江·杭州', plan: '连续剧会员'),
    AppUser(id: 3, name: '夜猫子', email: 'nightowl@example.com', role: UserRole.user, status: UserStatus.active, registered: '2026-01-22', lastActive: '2026-08-15 23:51', logins: 88, ip: '112.10.99.3', device: 'Android · 小米14', region: '四川·成都', plan: '免费'),
    AppUser(id: 4, name: '阿May', email: 'amay@example.com', role: UserRole.user, status: UserStatus.disabled, registered: '2025-12-01', lastActive: '2026-07-30 14:20', logins: 36, ip: '120.85.11.7', device: 'MacBook Pro', region: '上海·浦东', plan: '免费'),
    AppUser(id: 5, name: '电影老饕', email: 'cinephile@example.com', role: UserRole.vip, status: UserStatus.active, registered: '2025-06-09', lastActive: '2026-08-16 07:05', logins: 911, ip: '36.45.2.19', device: 'Windows PC', region: '北京·朝阳', plan: '全站会员'),
    AppUser(id: 6, name: 'tech_admin', email: 'admin@shipin.tai', role: UserRole.admin, status: UserStatus.active, registered: '2025-01-01', lastActive: '2026-08-16 10:30', logins: 2048, ip: '内网 10.0.0.9', device: '管理后台', region: '本地·运维', plan: '管理员'),
    AppUser(id: 7, name: '小鹿乱撞', email: 'deer@example.com', role: UserRole.user, status: UserStatus.active, registered: '2026-03-15', lastActive: '2026-08-14 21:10', logins: 64, ip: '117.136.40.5', device: 'iPhone 14', region: '江苏·南京', plan: '免费'),
    AppUser(id: 8, name: '刷剧不睡', email: 'nosleep@example.com', role: UserRole.user, status: UserStatus.disabled, registered: '2026-02-02', lastActive: '2026-06-12 02:33', logins: 27, ip: '183.14.8.66', device: 'Android · 一加12', region: '湖北·武汉', plan: '免费'),
    AppUser(id: 9, name: 'VIP会员Lee', email: 'lee@example.com', role: UserRole.vip, status: UserStatus.active, registered: '2025-10-10', lastActive: '2026-08-15 19:45', logins: 377, ip: '101.88.23.4', device: 'Apple TV', region: '福建·厦门', plan: '全站会员'),
    AppUser(id: 10, name: '路人甲', email: 'luRenjia@example.com', role: UserRole.user, status: UserStatus.active, registered: '2026-04-28', lastActive: '2026-08-13 12:00', logins: 19, ip: '125.34.9.51', device: 'Web · Chrome', region: '陕西·西安', plan: '免费'),
    AppUser(id: 11, name: '动漫迷妹', email: 'animefan@example.com', role: UserRole.user, status: UserStatus.active, registered: '2026-05-19', lastActive: '2026-08-16 06:18', logins: 205, ip: '106.61.2.88', device: 'iPad mini', region: '湖南·长沙', plan: '免费'),
    AppUser(id: 12, name: '老电影收藏', email: 'classic@example.com', role: UserRole.vip, status: UserStatus.active, registered: '2025-08-21', lastActive: '2026-08-12 15:30', logins: 612, ip: '58.246.77.1', device: 'Fire TV', region: '天津·和平', plan: '电影会员'),
    AppUser(id: 13, name: '测试账号01', email: 'test01@example.com', role: UserRole.user, status: UserStatus.disabled, registered: '2026-07-01', lastActive: '2026-07-01 10:00', logins: 2, ip: '127.0.0.1', device: 'Web · 测试', region: '未知', plan: '免费'),
    AppUser(id: 14, name: '周末影院', email: 'weekend@example.com', role: UserRole.user, status: UserStatus.active, registered: '2026-06-06', lastActive: '2026-08-15 22:05', logins: 73, ip: '218.76.5.30', device: 'iPhone 13', region: '重庆·渝中', plan: '免费'),
  ];

  final TextEditingController _searchController = TextEditingController();
  UserRole? _roleFilter;
  UserStatus? _statusFilter;

  List<AppUser> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _users.where((u) {
      if (_roleFilter != null && u.role != _roleFilter) return false;
      if (_statusFilter != null && u.status != _statusFilter) return false;
      if (q.isNotEmpty) {
        final hay = '${u.name} ${u.email} ${u.ip}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  int get _activeCount => _users.where((u) => u.status == UserStatus.active).length;
  int get _disabledCount => _users.where((u) => u.status == UserStatus.disabled).length;
  int get _todayCount => _users.where((u) => u.lastActive.startsWith('2026-08-16')).length;

  Color _avatarColor(String name) {
    final palette = [
      AppTheme.accent,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
      Colors.green,
    ];
    var h = 0;
    for (var i = 0; i < name.length; i++) {
      h = (h * 31 + name.codeUnitAt(i)) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }

  String _roleLabel(UserRole r) =>
      r == UserRole.admin ? '管理员' : r == UserRole.vip ? '会员' : '普通用户';

  Color _roleColor(UserRole r) =>
      r == UserRole.admin ? AppTheme.accent : r == UserRole.vip ? Colors.amber : Colors.grey;

  String _statusLabel(UserStatus s) => s == UserStatus.active ? '已启用' : '已禁用';
  Color _statusColor(UserStatus s) => s == UserStatus.active ? Colors.teal : Colors.orange;

  void _toggleStatus(AppUser u) {
    setState(() {
      u.status = u.status == UserStatus.active ? UserStatus.disabled : UserStatus.active;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(u.status == UserStatus.disabled
            ? '已禁用用户「${u.name}」'
            : '已启用用户「${u.name}」'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setRole(AppUser u, UserRole r) {
    setState(() => u.role = r);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将「${u.name}」设为${_roleLabel(r)}'), duration: const Duration(seconds: 2)),
    );
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    var s = '';
    for (var i = 0; i < 12; i++) {
      s += chars[(DateTime.now().microsecondsSinceEpoch + i * 7) % chars.length];
    }
    return s;
  }

  void _resetPassword(AppUser u) {
    final pwd = _generatePassword();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已为「${u.name}」生成临时密码：$pwd（演示：已通过邮件发送）'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showDetail(AppUser u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _avatarColor(u.name),
              child: Text(u.name[0], style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name, style: const TextStyle(color: AppTheme.textPrimary)),
                  Text(u.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _detailItem('用户ID', '#${u.id}'),
              _detailItem('角色', _roleLabel(u.role)),
              _detailItem('状态', _statusLabel(u.status)),
              _detailItem('套餐', u.plan),
              _detailItem('登录次数', '${u.logins} 次'),
              _detailItem('注册时间', u.registered),
              _detailItem('最近活跃', u.lastActive),
              _detailItem('登录IP', u.ip),
              _detailItem('设备', u.device),
              _detailItem('地区', u.region),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetPassword(u);
            },
            child: const Text('生成临时密码'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String k, String v) => SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(v, style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
      );

  Widget _statCard(String num, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceAlt),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(num, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 用户管理'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
              ),
              child: const Text(
                '本站为 UI 原型演示，下列为 mock 用户数据。可查看用户明细、调整角色权限、生成临时密码、启用 / 禁用账号。',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('${_users.length}', '总用户', AppTheme.accent),
                const SizedBox(width: 12),
                _statCard('$_activeCount', '已启用', Colors.teal),
                const SizedBox(width: 12),
                _statCard('$_disabledCount', '已禁用', Colors.orange),
                const SizedBox(width: 12),
                _statCard('$_todayCount', '今日活跃', Colors.cyan),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '搜索用户名 / 邮箱 / IP',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
                DropdownButton<UserRole?>(
                  value: _roleFilter,
                  hint: const Text('全部角色', style: TextStyle(color: AppTheme.textSecondary)),
                  dropdownColor: AppTheme.surface,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部角色')),
                    DropdownMenuItem(value: UserRole.user, child: Text(_roleLabel(UserRole.user))),
                    DropdownMenuItem(value: UserRole.vip, child: Text(_roleLabel(UserRole.vip))),
                    DropdownMenuItem(value: UserRole.admin, child: Text(_roleLabel(UserRole.admin))),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v),
                ),
                DropdownButton<UserStatus?>(
                  value: _statusFilter,
                  hint: const Text('全部状态', style: TextStyle(color: AppTheme.textSecondary)),
                  dropdownColor: AppTheme.surface,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部状态')),
                    DropdownMenuItem(value: UserStatus.active, child: Text(_statusLabel(UserStatus.active))),
                    DropdownMenuItem(value: UserStatus.disabled, child: Text(_statusLabel(UserStatus.disabled))),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 16),
                Text('共 ${list.length} 位用户', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.surfaceAlt),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('用户')),
                      DataColumn(label: Text('角色')),
                      DataColumn(label: Text('状态')),
                      DataColumn(label: Text('最近活跃')),
                      DataColumn(label: Text('注册时间')),
                      DataColumn(label: Text('操作'), numeric: true),
                    ],
                    rows: list.map((u) => _userRow(u)).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _userRow(AppUser u) => DataRow(
        cells: [
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _avatarColor(u.name),
                  child: Text(u.name[0], style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: const TextStyle(color: AppTheme.textPrimary)),
                    Text(u.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _roleColor(u.role).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_roleLabel(u.role), style: TextStyle(color: _roleColor(u.role), fontSize: 12)),
                ),
                const SizedBox(width: 6),
                DropdownButton<UserRole>(
                  value: u.role,
                  dropdownColor: AppTheme.surface,
                  underline: const SizedBox(),
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r), style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (r) => _setRole(u, r!),
                ),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(u.status).withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_statusLabel(u.status), style: TextStyle(color: _statusColor(u.status), fontSize: 12)),
            ),
          ),
          DataCell(Text(u.lastActive, style: const TextStyle(color: AppTheme.textPrimary))),
          DataCell(Text(u.registered, style: const TextStyle(color: AppTheme.textPrimary))),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  color: AppTheme.textSecondary,
                  tooltip: '详情',
                  onPressed: () => _showDetail(u),
                ),
                IconButton(
                  icon: const Icon(Icons.key_outlined, size: 18),
                  color: AppTheme.textSecondary,
                  tooltip: '重置密码',
                  onPressed: () => _resetPassword(u),
                ),
                IconButton(
                  icon: Icon(
                    u.status == UserStatus.active ? Icons.block_outlined : Icons.check_circle_outline,
                    size: 18,
                  ),
                  color: u.status == UserStatus.active ? Colors.orange : Colors.teal,
                  tooltip: u.status == UserStatus.active ? '禁用' : '启用',
                  onPressed: () => _toggleStatus(u),
                ),
              ],
            ),
          ),
        ],
      );
}
