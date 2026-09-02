import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/api/appwrite_query_builders.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_states.dart';
import 'admin_analytics_csv_exporter.dart';
import 'admin_analytics_models.dart';
part 'widgets/admin_analytics_cards.dart';
part 'widgets/admin_analytics_charts.dart';
part 'admin_analytics_screen_sections.dart';

enum AdminAnalyticsRangePreset { seven, thirty, ninety, custom }

enum AdminAnalyticsDensity { comfortable, compact }

class AdminAnalyticsDateRange {
  const AdminAnalyticsDateRange({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const AdminAnalyticsDateRange.last30()
    : preset = AdminAnalyticsRangePreset.thirty,
      customStart = null,
      customEnd = null;

  const AdminAnalyticsDateRange.custom({
    required DateTime start,
    required DateTime end,
  }) : preset = AdminAnalyticsRangePreset.custom,
       customStart = start,
       customEnd = end;

  final AdminAnalyticsRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  int get days => switch (preset) {
    AdminAnalyticsRangePreset.seven => 7,
    AdminAnalyticsRangePreset.thirty => 30,
    AdminAnalyticsRangePreset.ninety => 90,
    AdminAnalyticsRangePreset.custom => 30,
  };

  DateTime startFor(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom && customStart != null) {
      return _dateOnly(customStart!);
    }
    final end = endFor(now);
    return end.subtract(Duration(days: days - 1));
  }

  DateTime endFor(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom && customEnd != null) {
      return _dateOnly(customEnd!);
    }
    return _dateOnly(now);
  }

  String label(DateTime now) {
    if (preset == AdminAnalyticsRangePreset.custom &&
        customStart != null &&
        customEnd != null) {
      return '${formatShortDate(startFor(now))} - ${formatShortDate(endFor(now))}';
    }
    return switch (preset) {
      AdminAnalyticsRangePreset.seven => 'Last 7 days',
      AdminAnalyticsRangePreset.thirty => 'Last 30 days',
      AdminAnalyticsRangePreset.ninety => 'Last 90 days',
      AdminAnalyticsRangePreset.custom => 'Custom range',
    };
  }
}

final adminAnalyticsRangeProvider = StateProvider<AdminAnalyticsDateRange>(
  (_) => const AdminAnalyticsDateRange.last30(),
);

final adminAnalyticsDensityProvider = StateProvider<AdminAnalyticsDensity>(
  (_) => AdminAnalyticsDensity.comfortable,
);

final adminAnalyticsSnapshotProvider =
    FutureProvider.autoDispose<AdminAnalyticsSnapshot>((ref) async {
      final db = ref.read(appwriteDbServiceProvider);
      final range = ref.watch(adminAnalyticsRangeProvider);
      final now = DateTime.now().toUtc();
      final start = range.startFor(now);
      final end = range.endFor(now);
      final startKey = formatDateKey(start);
      final endKey = formatDateKey(end);

      final rollups = await db.listDocuments(
        'learning_analytics_daily_rollups',
        queries: [
          DbQuery.greaterThanEqual('dateKey', startKey),
          DbQuery.lessThanEqual('dateKey', endKey),
          DbQuery.orderDesc('dateKey'),
          DbQuery.limit(500),
        ],
        paginate: false,
      );

      var events = <Map<String, dynamic>>[];
      try {
        events = await db.listDocuments(
          'learning_analytics_events',
          queries: [
            DbQuery.greaterThanEqual('dateKey', startKey),
            DbQuery.lessThanEqual('dateKey', endKey),
            DbQuery.orderDesc('dateKey'),
            DbQuery.limit(1000),
          ],
          paginate: false,
        );
      } catch (_) {
        // Rollups still power the product dashboard when raw event reads are
        // restricted. DAU/retention gracefully drop to zero instead of failing
        // the whole admin page.
      }

      return AdminAnalyticsSnapshot.fromRows(
        rollups: rollups,
        events: events,
        now: now,
        startDate: start,
        endDate: end,
      );
    });

DateTime _dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

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
                    _AnalyticsToolbar(
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
                _RangeStatus(range: range, snapshot: data, isDark: isDark),
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

class _AnalyticsToolbar extends StatelessWidget {
  const _AnalyticsToolbar({
    required this.range,
    required this.density,
    required this.snapshot,
    required this.isDark,
    required this.onRefresh,
    required this.onRangeChanged,
    required this.onDensityChanged,
  });

  final AdminAnalyticsDateRange range;
  final AdminAnalyticsDensity density;
  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final VoidCallback onRefresh;
  final ValueChanged<AdminAnalyticsDateRange> onRangeChanged;
  final ValueChanged<AdminAnalyticsDensity> onDensityChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminTokens.space3,
      runSpacing: AdminTokens.space3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RangeSegmentedControl(
          range: range,
          isDark: isDark,
          onChanged: (preset) => _changeRange(context, preset),
        ),
        _ToolbarAction(
          label: density == AdminAnalyticsDensity.compact
              ? 'Compact'
              : 'Comfortable',
          icon: density == AdminAnalyticsDensity.compact
              ? Icons.density_small_rounded
              : Icons.density_medium_rounded,
          isDark: isDark,
          onTap: () {
            onDensityChanged(
              density == AdminAnalyticsDensity.compact
                  ? AdminAnalyticsDensity.comfortable
                  : AdminAnalyticsDensity.compact,
            );
          },
        ),
        _ToolbarAction(
          label: 'Export CSV',
          icon: Icons.download_rounded,
          isDark: isDark,
          onTap: () => _exportCsv(context),
        ),
        _ToolbarAction(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          isDark: isDark,
          onTap: onRefresh,
        ),
      ],
    );
  }

  Future<void> _changeRange(
    BuildContext context,
    AdminAnalyticsRangePreset preset,
  ) async {
    if (preset != AdminAnalyticsRangePreset.custom) {
      onRangeChanged(AdminAnalyticsDateRange(preset: preset));
      return;
    }

    final now = DateTime.now().toUtc();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(2025),
      lastDate: _dateOnly(now).add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: range.startFor(now),
        end: range.endFor(now),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AdminTokens.accent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    onRangeChanged(
      AdminAnalyticsDateRange.custom(start: picked.start, end: picked.end),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final csv = snapshot.toRollupsCsv();
    final now = DateTime.now().toUtc();
    final renderObject = context.findRenderObject();
    final sharePositionOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    await exportAnalyticsCsv(
      filename:
          'olitun-learning-analytics-${formatDateKey(range.startFor(now))}-to-${formatDateKey(range.endFor(now))}.csv',
      csv: csv,
      sharePositionOrigin: sharePositionOrigin,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          snapshot.rollupsForExport.isEmpty
              ? 'CSV header $analyticsCsvExportLabel. No rollups loaded for this range yet.'
              : 'CSV $analyticsCsvExportLabel with ${snapshot.rollupsForExport.length} rollup rows.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _RangeSegmentedControl extends StatelessWidget {
  const _RangeSegmentedControl({
    required this.range,
    required this.isDark,
    required this.onChanged,
  });

  final AdminAnalyticsDateRange range;
  final bool isDark;
  final ValueChanged<AdminAnalyticsRangePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Analytics date range selector',
      child: SegmentedButton<AdminAnalyticsRangePreset>(
        selected: {range.preset},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AdminTokens.accentSoft(isDark)
                : AdminTokens.sunken(isDark);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AdminTokens.accent
                : AdminTokens.textSecondary(isDark);
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: AdminTokens.border(isDark)),
          ),
        ),
        segments: const [
          ButtonSegment(
            value: AdminAnalyticsRangePreset.seven,
            label: Text('7d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.thirty,
            label: Text('30d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.ninety,
            label: Text('90d'),
          ),
          ButtonSegment(
            value: AdminAnalyticsRangePreset.custom,
            label: Text('Custom'),
          ),
        ],
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AdminTokens.textSecondary(isDark)),
                const SizedBox(width: AdminTokens.space2),
                Text(label, style: AdminTokens.label(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _compactLabel(String value) {
  final trimmed = value.replaceAll('_', ' ');
  if (trimmed.length <= 12) return trimmed;
  return '${trimmed.substring(0, 11)}.';
}
