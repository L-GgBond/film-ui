import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/media.dart';
import '../data/mock_data.dart';

/// Left sidebar: logo, primary navigation, and media source list.
class AppSidebar extends StatelessWidget {
  final String activeNavId;
  final String activeSourceId;
  final ValueChanged<String> onNavChanged;
  final ValueChanged<String> onSourceChanged;
  final bool collapsed;
  final bool showAdmin; // 登录后才显示「用户管理」
  final VoidCallback onLogin; // 点击「登录」
  final VoidCallback onLogout; // 点击「退出登录」

  const AppSidebar({
    super.key,
    required this.activeNavId,
    required this.activeSourceId,
    required this.onNavChanged,
    required this.onSourceChanged,
    this.collapsed = false,
    this.showAdmin = false,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: collapsed ? 64 : 210,
      color: AppTheme.surface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  const Text(
                    '影视台',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceAlt),
          // Primary navigation（未登录时隐藏「用户管理」）
          ...MockData.navItems
              .where((nav) => nav.id != 'admin' || showAdmin)
              .map((nav) => _navTile(nav)),
          // 登录 / 退出登录
          _SideTile(
            icon: showAdmin ? Icons.logout : Icons.login,
            label: showAdmin ? '退出登录' : '登录',
            active: false,
            collapsed: collapsed,
            onTap: showAdmin ? onLogout : onLogin,
          ),
          const SizedBox(height: 8),
          if (!collapsed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '资源源',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          // Source list
          ...MockData.sources.map((src) => _sourceTile(src)),
        ],
      ),
      ),
    );
  }

  Widget _navTile(NavItem nav) {
    final active = nav.id == activeNavId;
    return _SideTile(
      icon: nav.icon,
      label: nav.label,
      active: active,
      collapsed: collapsed,
      onTap: () => onNavChanged(nav.id),
    );
  }

  Widget _sourceTile(MediaSource src) {
    final active = src.id == activeSourceId;
    return _SideTile(
      icon: src.icon,
      label: src.name,
      active: active,
      collapsed: collapsed,
      onTap: () => onSourceChanged(src.id),
    );
  }
}

class _SideTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _SideTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent.withOpacity(0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? AppTheme.accent : AppTheme.textSecondary,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
