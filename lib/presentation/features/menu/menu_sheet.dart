import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Menu sheet shown when hamburger menu is tapped
class MenuSheet extends StatelessWidget {
  const MenuSheet({
    super.key,
    required this.onStatsTap,
    required this.onSettingsTap,
    required this.onHelpTap,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.trunk.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Menu title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '메뉴',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Menu items
          _MenuItem(
            icon: Icons.bar_chart_rounded,
            label: '감정 통계',
            subtitle: '월간 감정 분석 보기',
            color: AppColors.leafGreen,
            onTap: () {
              Navigator.pop(context);
              onStatsTap();
            },
          ),
          _MenuItem(
            icon: Icons.settings_rounded,
            label: '설정',
            subtitle: '알림, 계정 관리',
            color: AppColors.leafBlue,
            onTap: () {
              Navigator.pop(context);
              onSettingsTap();
            },
          ),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: '도움말',
            subtitle: '앱 사용법, FAQ',
            color: AppColors.leafYellow,
            onTap: () {
              Navigator.pop(context);
              onHelpTap();
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
