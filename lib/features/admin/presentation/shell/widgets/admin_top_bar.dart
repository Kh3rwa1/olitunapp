import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminTopBar extends StatelessWidget {
  final bool isDark;
  const AdminTopBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final crumbs = _crumbsFor(location);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminTokens.divider(isDark))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 16,
            color: AdminTokens.textTertiary(isDark),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AdminTokens.textMuted(isDark),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              crumbs[i],
              style: AdminTokens.label(isDark).copyWith(
                color: i == crumbs.length - 1
                    ? AdminTokens.textPrimary(isDark)
                    : AdminTokens.textTertiary(isDark),
                fontWeight: i == crumbs.length - 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          AdminTopBarChip(
            isDark: isDark,
            icon: Icons.bolt_rounded,
            label: 'Live',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          AdminTopBarChip(
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  List<String> _crumbsFor(String location) {
    if (location == '/admin' || location == '/admin/') return ['Dashboard'];
    final segments = location
        .replaceFirst('/admin/', '')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    return ['Admin', ...segments.map(_titleize)];
  }

  String _titleize(String s) {
    final cleaned = s.replaceAll('-', ' ').replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map(
          (p) => p.isEmpty
              ? p
              : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class AdminTopBarChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color? color;

  const AdminTopBarChip({
    super.key,
    required this.isDark,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AdminTokens.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: isDark ? 0.14 : 0.1)
            : AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.28)
              : AdminTokens.border(isDark),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: AdminTokens.label(isDark).copyWith(
              color: tint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
