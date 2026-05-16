import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import 'analytics_chart.dart';
import 'dashboard_empty_state.dart';

class DashboardAnalyticsPanel extends ConsumerWidget {
  final bool isDark;
  const DashboardAnalyticsPanel({super.key, required this.isDark});

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
                    'CONTENT ACTIVITY',
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text('Last 7 days', style: AdminTokens.sectionTitle(isDark)),
                ],
              ),
              Wrap(
                spacing: 14,
                children: [
                  AnalyticsLegendDot(
                    color: AppColors.primary,
                    label: 'Lessons',
                    isDark: isDark,
                  ),
                  AnalyticsLegendDot(
                    color: AppColors.duoBlue,
                    label: 'Vocabulary',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 230,
            child: metricsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (_, _) => DashboardEmptyState(
                isDark: isDark,
                icon: Icons.cloud_off_rounded,
                message: 'Couldn\'t load engagement data',
              ),
              data: (m) {
                final hasData =
                    m.lessonsSeries.any((v) => v > 0) ||
                    m.vocabularySeries.any((v) => v > 0);
                if (!hasData) {
                  return DashboardEmptyState(
                    isDark: isDark,
                    icon: Icons.show_chart_rounded,
                    message: 'No activity in the last 7 days',
                  );
                }
                return AnalyticsChart(
                  isDark: isDark,
                  lessons: m.lessonsSeries,
                  vocabulary: m.vocabularySeries,
                  dayLabels: m.dayLabels,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}
