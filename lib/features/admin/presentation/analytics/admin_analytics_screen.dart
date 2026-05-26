import 'package:appwrite/appwrite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_states.dart';
import 'admin_analytics_csv_exporter.dart';
import 'admin_analytics_models.dart';

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
          Query.greaterThanEqual('dateKey', startKey),
          Query.lessThanEqual('dateKey', endKey),
          Query.orderDesc('dateKey'),
          Query.limit(500),
        ],
        paginate: false,
      );

      var events = <Map<String, dynamic>>[];
      try {
        events = await db.listDocuments(
          'learning_analytics_events',
          queries: [
            Query.greaterThanEqual('dateKey', startKey),
            Query.lessThanEqual('dateKey', endKey),
            Query.orderDesc('dateKey'),
            Query.limit(1000),
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
                  _EmptyAnalyticsCard(isDark: isDark, compact: compact),
                  const SizedBox(height: AdminTokens.space6),
                ],
                _KpiGrid(snapshot: data, isDark: isDark, compact: compact),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                _ResponsiveGrid(
                  spacing: compact ? AdminTokens.space4 : AdminTokens.space6,
                  left: _DauTrendCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                  right: _PlatformSplitCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                _ResponsiveGrid(
                  spacing: compact ? AdminTokens.space4 : AdminTokens.space6,
                  left: _TopEventSourcesCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                  right: _TopEventsCard(
                    snapshot: data,
                    isDark: isDark,
                    compact: compact,
                  ),
                ),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space6,
                ),
                _RetentionHeatmapCard(
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

class _RangeStatus extends StatelessWidget {
  const _RangeStatus({
    required this.range,
    required this.snapshot,
    required this.isDark,
  });

  final AdminAnalyticsDateRange range;
  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return Wrap(
      spacing: AdminTokens.space3,
      runSpacing: AdminTokens.space2,
      children: [
        _StatusChip(
          isDark: isDark,
          icon: Icons.date_range_rounded,
          label: range.label(now),
        ),
        _StatusChip(
          isDark: isDark,
          icon: Icons.storage_rounded,
          label: '${snapshot.rollupRows} rollups',
        ),
        _StatusChip(
          isDark: isDark,
          icon: Icons.bolt_rounded,
          label: '${snapshot.eventRows} raw events sampled',
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isDark,
    required this.icon,
    required this.label,
  });

  final bool isDark;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AdminTokens.accent),
          const SizedBox(width: AdminTokens.space2),
          Text(
            label,
            style: AdminTokens.label(
              isDark,
            ).copyWith(color: AdminTokens.textPrimary(isDark)),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final cards = [
          _KpiCard(
            label: 'DAU',
            value: snapshot.dau.toString(),
            caption: 'Active learners today',
            icon: Icons.today_rounded,
            isDark: isDark,
            compact: compact,
          ),
          _KpiCard(
            label: 'WAU',
            value: snapshot.wau.toString(),
            caption: 'Active learners this week',
            icon: Icons.calendar_view_week_rounded,
            isDark: isDark,
            compact: compact,
          ),
          _KpiCard(
            label: 'MAU',
            value: snapshot.mau.toString(),
            caption: 'Active learners this month',
            icon: Icons.calendar_month_rounded,
            isDark: isDark,
            compact: compact,
          ),
          _KpiCard(
            label: 'Rollups',
            value: snapshot.rollupRows.toString(),
            caption: '${snapshot.eventRows} raw events sampled',
            icon: Icons.stacked_bar_chart_rounded,
            isDark: isDark,
            compact: compact,
          ),
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: compact ? 2 : 4,
          childAspectRatio: compact ? 1.95 : 2.25,
          crossAxisSpacing: compact ? AdminTokens.space3 : AdminTokens.space4,
          mainAxisSpacing: compact ? AdminTokens.space3 : AdminTokens.space4,
          children: cards,
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.isDark,
    required this.compact,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      compact: compact,
      child: Semantics(
        label: '$label $value. $caption',
        child: Row(
          children: [
            _IconBadge(icon: icon, isDark: isDark, compact: compact),
            SizedBox(width: compact ? AdminTokens.space3 : AdminTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AdminTokens.eyebrow(isDark)),
                  const SizedBox(height: AdminTokens.space1),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: AdminTokens.display(
                        isDark,
                      ).copyWith(fontSize: compact ? 28 : 34, letterSpacing: 0),
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTokens.label(isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DauTrendCard extends StatelessWidget {
  const _DauTrendCard({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final trendDays = snapshot.rangeDays.clamp(1, 90).toInt();
    final days = List.generate(
      trendDays,
      (index) => snapshot.startDate.add(Duration(days: index)),
    );
    final values = days
        .map((day) => snapshot.dailyActiveUsers[day] ?? 0)
        .toList();
    final max = values.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    final yMax = (max < 4 ? 4 : max + 1).toDouble();
    final bottomInterval = (days.length / 6).ceilToDouble().clamp(1.0, 30.0);

    return _ChartCard(
      title: 'DAU Trend',
      subtitle: 'Unique learners active per day',
      semanticsLabel: 'DAU trend chart for ${snapshot.rangeDays} days.',
      isDark: isDark,
      compact: compact,
      child: values.any((value) => value > 0)
          ? LineChart(
              LineChartData(
                minY: 0,
                maxY: yMax,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AdminTokens.border(isDark), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: AdminTokens.label(isDark).copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: bottomInterval,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${days[index].month}/${days[index].day}',
                            style: AdminTokens.label(
                              isDark,
                            ).copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i += 1)
                        FlSpot(i.toDouble(), values[i].toDouble()),
                    ],
                    color: AdminTokens.accent,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminTokens.accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipBorderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    tooltipBorder: BorderSide(
                      color: AdminTokens.border(isDark),
                    ),
                    getTooltipColor: (_) =>
                        isDark ? const Color(0xFF1A2030) : Colors.white,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.round();
                      final date = index >= 0 && index < days.length
                          ? formatShortDate(days[index])
                          : 'Day ${index + 1}';
                      return LineTooltipItem(
                        '$date\n${spot.y.toInt()} active',
                        TextStyle(
                          fontFamily: 'Poppins',
                          color: AdminTokens.textPrimary(isDark),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          : _NoChartData(isDark: isDark, label: 'No daily active data yet'),
    );
  }
}

class _PlatformSplitCard extends StatelessWidget {
  const _PlatformSplitCard({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.platformTotals.entries.take(5).toList();
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    final colors = [
      AdminTokens.accent,
      AppColors.duoBlue,
      AppColors.warning,
      AppColors.duoPurple,
      AppColors.accentPink,
    ];

    return _ChartCard(
      title: 'Platform Split',
      subtitle: 'Where learning sessions happen',
      semanticsLabel:
          'Platform split chart across ${entries.length} platforms.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? _NoChartData(isDark: isDark, label: 'No platform data yet')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: entries
                      .map(
                        (entry) =>
                            '${entry.key}: ${(entry.value / total * 100).round()}%',
                      )
                      .join('  '),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: compact ? 28 : 36,
                      child: Row(
                        children: [
                          for (var i = 0; i < entries.length; i += 1)
                            Expanded(
                              flex: entries[i].value,
                              child: ColoredBox(
                                color: colors[i % colors.length],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: compact ? AdminTokens.space4 : AdminTokens.space5,
                ),
                _LegendList(
                  entries: entries,
                  colors: colors,
                  isDark: isDark,
                  total: total,
                  compact: compact,
                ),
              ],
            ),
    );
  }
}

class _TopEventSourcesCard extends StatelessWidget {
  const _TopEventSourcesCard({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.eventSourceTotals.entries
        .take(compact ? 10 : 8)
        .toList();
    final max = entries.fold<int>(0, (current, entry) {
      return entry.value > current ? entry.value : current;
    });

    return _ChartCard(
      title: 'Top Events by Source',
      subtitle: 'Which surfaces produce learning activity',
      semanticsLabel: 'Top events by source chart with ${entries.length} rows.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? _NoChartData(isDark: isDark, label: 'No source data yet')
          : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) => SizedBox(
                height: compact ? AdminTokens.space2 : AdminTokens.space3,
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final fraction = max == 0 ? 0.0 : entry.value / max;
                return Semantics(
                  label: '${entry.key}, ${entry.value} events',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AdminTokens.label(isDark).copyWith(
                                color: AdminTokens.textPrimary(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: AdminTokens.space3),
                          Text(
                            entry.value.toString(),
                            style: AdminTokens.label(isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: AdminTokens.space2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: fraction,
                          backgroundColor: AdminTokens.sunken(isDark),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AdminTokens.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TopEventsCard extends StatelessWidget {
  const _TopEventsCard({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.eventTotals.entries
        .take(compact ? 10 : 8)
        .toList();
    final max = entries.fold<int>(0, (current, entry) {
      return entry.value > current ? entry.value : current;
    });

    return _ChartCard(
      title: 'Event Mix',
      subtitle: 'Lessons, quizzes, streaks, and habit signals',
      semanticsLabel: 'Top event mix chart with ${entries.length} event types.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? _NoChartData(isDark: isDark, label: 'No event rollups yet')
          : BarChart(
              BarChartData(
                maxY: (max < 4 ? 4 : max + 1).toDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AdminTokens.border(isDark), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: AdminTokens.label(isDark).copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              _compactLabel(entries[index].key),
                              style: AdminTokens.label(
                                isDark,
                              ).copyWith(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < entries.length; i += 1)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          color: AppColors.duoBlue,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipBorderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    tooltipBorder: BorderSide(
                      color: AdminTokens.border(isDark),
                    ),
                    getTooltipColor: (_) =>
                        isDark ? const Color(0xFF1A2030) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x;
                      if (index < 0 || index >= entries.length) return null;
                      final entry = entries[index];
                      return BarTooltipItem(
                        '${entry.key.replaceAll('_', ' ')}\n${entry.value} events',
                        TextStyle(
                          fontFamily: 'Poppins',
                          color: AdminTokens.textPrimary(isDark),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

class _RetentionHeatmapCard extends StatelessWidget {
  const _RetentionHeatmapCard({
    required this.snapshot,
    required this.isDark,
    required this.compact,
  });

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cohorts = snapshot.retentionCohorts;
    return _Panel(
      isDark: isDark,
      compact: compact,
      child: Semantics(
        label: 'Retention cohort heatmap with ${cohorts.length} cohorts.',
        image: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              title: 'Retention Cohorts',
              subtitle: 'Percent of learners returning in later weeks',
              isDark: isDark,
            ),
            const SizedBox(height: AdminTokens.space5),
            if (cohorts.isEmpty)
              SizedBox(
                height: 180,
                child: _NoChartData(
                  isDark: isDark,
                  label: 'Raw events are needed for retention cohorts',
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HeatmapLabel('Cohort', width: 120, isDark: isDark),
                        _HeatmapLabel('Size', width: 70, isDark: isDark),
                        for (var week = 0; week < 6; week += 1)
                          _HeatmapLabel('W$week', width: 70, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: AdminTokens.space2),
                    for (final cohort in cohorts)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AdminTokens.space2,
                        ),
                        child: Row(
                          children: [
                            _HeatmapLabel(
                              formatShortDate(cohort.weekStart),
                              width: 120,
                              isDark: isDark,
                              strong: true,
                            ),
                            _HeatmapLabel(
                              cohort.size.toString(),
                              width: 70,
                              isDark: isDark,
                            ),
                            for (final value in cohort.weekRetention)
                              _HeatmapCell(value: value, isDark: isDark),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.left,
    required this.right,
    required this.spacing,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.child,
    required this.isDark,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final String semanticsLabel;
  final Widget child;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, subtitle: subtitle, isDark: isDark),
          SizedBox(height: compact ? AdminTokens.space4 : AdminTokens.space5),
          SizedBox(
            height: compact ? 246 : 300,
            child: Semantics(label: semanticsLabel, image: true, child: child),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    required this.isDark,
    this.compact = false,
  });

  final Widget child;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact ? AdminTokens.space4 : AdminTokens.space5,
      ),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AdminTokens.sectionTitle(isDark)),
        const SizedBox(height: AdminTokens.space1),
        Text(subtitle, style: AdminTokens.body(isDark)),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.isDark,
    this.compact = false,
  });

  final IconData icon;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 44 : 52,
      height: compact ? 44 : 52,
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Icon(icon, color: AdminTokens.accent),
    );
  }
}

class _LegendList extends StatelessWidget {
  const _LegendList({
    required this.entries,
    required this.colors,
    required this.isDark,
    required this.total,
    required this.compact,
  });

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final bool isDark;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: compact ? AdminTokens.space2 : AdminTokens.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AdminTokens.space2),
                Expanded(
                  child: Text(
                    entries[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTokens.label(
                      isDark,
                    ).copyWith(color: AdminTokens.textPrimary(isDark)),
                  ),
                ),
                Text(
                  '${(entries[i].value / total * 100).round()}% · ${entries[i].value}',
                  style: AdminTokens.label(isDark),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeatmapLabel extends StatelessWidget {
  const _HeatmapLabel(
    this.label, {
    required this.width,
    required this.isDark,
    this.strong = false,
  });

  final String label;
  final double width;
  final bool isDark;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style:
            (strong
                    ? AdminTokens.bodyStrong(isDark)
                    : AdminTokens.label(isDark))
                .copyWith(fontSize: 12),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.value, required this.isDark});

  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AdminTokens.sunken(isDark),
      AdminTokens.accent,
      value.clamp(0, 1),
    )!;
    return Semantics(
      label: '${(value * 100).round()} percent retained',
      child: Container(
        width: 58,
        height: 38,
        margin: const EdgeInsets.only(right: AdminTokens.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          border: Border.all(color: AdminTokens.border(isDark)),
        ),
        child: Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: value > 0.48
                ? Colors.white
                : AdminTokens.textPrimary(isDark),
          ),
        ),
      ),
    );
  }
}

class _NoChartData extends StatelessWidget {
  const _NoChartData({required this.isDark, required this.label});

  final bool isDark;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(icon: Icons.insights_rounded, isDark: isDark),
          const SizedBox(height: AdminTokens.space3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AdminTokens.bodyStrong(isDark),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({required this.isDark, required this.compact});

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      compact: compact,
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.schedule_rounded,
            isDark: isDark,
            compact: compact,
          ),
          const SizedBox(width: AdminTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for first rollup',
                  style: AdminTokens.cardTitle(isDark),
                ),
                const SizedBox(height: AdminTokens.space1),
                Text(
                  'The nightly pipeline is connected. This dashboard will populate after learning events are aggregated.',
                  style: AdminTokens.body(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _compactLabel(String value) {
  final trimmed = value.replaceAll('_', ' ');
  if (trimmed.length <= 12) return trimmed;
  return '${trimmed.substring(0, 11)}.';
}
