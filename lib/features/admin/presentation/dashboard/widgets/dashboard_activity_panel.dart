import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import 'activity_row.dart';
import 'dashboard_empty_state.dart';

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
            error: (_, _) => DashboardEmptyState(
              isDark: isDark,
              icon: Icons.cloud_off_rounded,
              message: 'Couldn\'t load recent activity',
            ),
            data: (m) {
              final items = m.recentActivity;
              if (items.isEmpty) {
                return DashboardEmptyState(
                  isDark: isDark,
                  icon: Icons.inbox_rounded,
                  message: 'No recent changes yet',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    ActivityRow(
                      isDark: isDark,
                      title: items[i].title,
                      subtitle:
                          '${items[i].subtitle} · ${formatRelative(items[i].timestamp)}',
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
