import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';

class DashboardActivityPanel extends ConsumerWidget {
  final bool isDark;
  const DashboardActivityPanel({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY',
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recent changes',
                    style: AdminTokens.sectionTitle(isDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTokens.sunken(isDark),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AdminTokens.border(isDark)),
                ),
                child: Text(
                  'Latest',
                  style: AdminTokens.label(isDark).copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.4,
                    color: AdminTokens.textTertiary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          metricsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (_, __) => _ActivityEmpty(
              isDark: isDark,
              icon: Icons.cloud_off_rounded,
              message: 'Couldn\'t load recent activity',
            ),
            data: (m) {
              final items = m.recentActivity;
              if (items.isEmpty) {
                return _ActivityEmpty(
                  isDark: isDark,
                  icon: Icons.inbox_rounded,
                  message: 'No recent changes yet',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _ActivityRow(
                      isDark: isDark,
                      title: items[i].title,
                      subtitle:
                          '${items[i].subtitle} · ${_formatRelative(items[i].timestamp)}',
                      icon: items[i].icon,
                      color: items[i].color,
                    ),
                    if (i < items.length - 1)
                      Divider(color: AdminTokens.divider(isDark), height: 18),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms);
  }
}

String _formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

class _ActivityEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  const _ActivityEmpty({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: AdminTokens.textMuted(isDark)),
            const SizedBox(height: 10),
            Text(
              message,
              style: AdminTokens.body(
                isDark,
              ).copyWith(fontSize: 13, color: AdminTokens.textTertiary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ActivityRow({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AdminTokens.label(isDark).copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  color: AdminTokens.textTertiary(isDark),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AdminTokens.textMuted(isDark),
        ),
      ],
    );
  }
}
