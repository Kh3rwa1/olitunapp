import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_states.dart';
import 'admin_analytics_providers.dart';
import 'widgets/admin_analytics_cards.dart';
import 'widgets/admin_analytics_charts.dart';
import 'widgets/admin_analytics_range_status.dart';
import 'widgets/admin_analytics_toolbar.dart';

export 'admin_analytics_providers.dart';
export 'widgets/admin_analytics_cards.dart';
export 'widgets/admin_analytics_charts.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snapshot = ref.watch(adminAnalyticsSnapshotProvider);
    final range = ref.watch(adminAnalyticsRangeProvider);
    final density = ref.watch(adminAnalyticsDensityProvider);
    final compact = density == AdminAnalyticsDensity.compact;

    return Material(
      color: Colors.transparent,
      child: snapshot.when(
        loading: () =>
            const AdminLoadingState(label: 'Loading learning analytics'),
        error: (error, _) => AdminErrorState(
          title: 'Analytics unavailable',
          message: error.toString(),
          onRetry: () => ref.invalidate(adminAnalyticsSnapshotProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminAnalyticsSnapshotProvider);
            await ref.read(adminAnalyticsSnapshotProvider.future);
          },
          child: Semantics(
            label: data.semanticsSummary,
            child: ListView(
              padding: EdgeInsets.all(
                compact ? AdminTokens.space5 : AdminTokens.space7,
              ),
              children: [
                AdminPageHeader(
                  eyebrow: 'Learning Health',
                  title: 'Analytics',
                  subtitle:
                      'Nightly rollups, learner activity, retention, sources, and platform mix.',
                  actions: [
                    AdminAnalyticsToolbar(
                      range: range,
                      density: density,
                      snapshot: data,
                      isDark: isDark,
                      onRefresh: () =>
                          ref.invalidate(adminAnalyticsSnapshotProvider),
                      onRangeChanged: (nextRange) {
                        ref.read(adminAnalyticsRangeProvider.notifier).state =
                            nextRange;
                      },
                      onDensityChanged: (nextDensity) {
                        ref.read(adminAnalyticsDensityProvider.notifier).state =
                            nextDensity;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AdminTokens.space4),
                AdminAnalyticsRangeStatus(
                  range: range,
                  snapshot: data,
                  isDark: isDark,
                ),
                SizedBox(
                  height: compact ? AdminTokens.space5 : AdminTokens.space7,
                ),
                if (!data.hasAnyData) ...[
                  EmptyAnalyticsCard(isDark: isDark, compact: compact),
                  const SizedBox(height: AdminTokens.space6),
                ],
                KpiGrid(snapshot: data, isDark: isDark, compact: compact),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                ResponsiveGrid(
                  spacing: compact ? AdminTokens.space4 : AdminTokens.space6,
                  left: DauTrendCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                  right: PlatformSplitCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                ResponsiveGrid(
                  spacing: compact ? AdminTokens.space4 : AdminTokens.space6,
                  left: TopEventSourcesCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                  right: TopEventsCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                RetentionHeatmapCard(
                  snapshot: data,
                  isDark: isDark,
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
