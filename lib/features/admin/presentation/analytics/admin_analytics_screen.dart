import 'package:appwrite/appwrite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_buttons.dart';
import '../widgets/common/admin_states.dart';
import 'admin_analytics_models.dart';

final adminAnalyticsSnapshotProvider =
    FutureProvider.autoDispose<AdminAnalyticsSnapshot>((ref) async {
      final db = ref.read(appwriteDbServiceProvider);
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(days: 90));
      final startKey = formatDateKey(start);

      final rollups = await db.listDocuments(
        'learning_analytics_daily_rollups',
        queries: [
          Query.greaterThanEqual('dateKey', startKey),
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
      );
    });

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snapshot = ref.watch(adminAnalyticsSnapshotProvider);

    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      body: SafeArea(
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
                padding: const EdgeInsets.all(AdminTokens.space7),
                children: [
                  AdminPageHeader(
                    eyebrow: 'Learning Health',
                    title: 'Analytics',
                    subtitle:
                        'Nightly rollups, learner activity, retention, sources, and platform mix.',
                    actions: [
                      AdminSecondaryButton(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            ref.invalidate(adminAnalyticsSnapshotProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTokens.space7),
                  if (!data.hasAnyData) ...[
                    _EmptyAnalyticsCard(isDark: isDark),
                    const SizedBox(height: AdminTokens.space6),
                  ],
                  _KpiGrid(snapshot: data, isDark: isDark),
                  const SizedBox(height: AdminTokens.space6),
                  _ResponsiveGrid(
                    left: _DauTrendCard(snapshot: data, isDark: isDark),
                    right: _PlatformSplitCard(snapshot: data, isDark: isDark),
                  ),
                  const SizedBox(height: AdminTokens.space6),
                  _ResponsiveGrid(
                    left: _TopEventSourcesCard(snapshot: data, isDark: isDark),
                    right: _TopEventsCard(snapshot: data, isDark: isDark),
                  ),
                  const SizedBox(height: AdminTokens.space6),
                  _RetentionHeatmapCard(snapshot: data, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

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
          ),
          _KpiCard(
            label: 'WAU',
            value: snapshot.wau.toString(),
            caption: 'Active learners this week',
            icon: Icons.calendar_view_week_rounded,
            isDark: isDark,
          ),
          _KpiCard(
            label: 'MAU',
            value: snapshot.mau.toString(),
            caption: 'Active learners this month',
            icon: Icons.calendar_month_rounded,
            isDark: isDark,
          ),
          _KpiCard(
            label: 'Rollups',
            value: snapshot.rollupRows.toString(),
            caption: '${snapshot.eventRows} raw events sampled',
            icon: Icons.stacked_bar_chart_rounded,
            isDark: isDark,
          ),
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: compact ? 2 : 4,
          childAspectRatio: compact ? 1.55 : 2.25,
          crossAxisSpacing: AdminTokens.space4,
          mainAxisSpacing: AdminTokens.space4,
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
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      child: Semantics(
        label: '$label $value. $caption',
        child: Row(
          children: [
            _IconBadge(icon: icon, isDark: isDark),
            const SizedBox(width: AdminTokens.space4),
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
                      ).copyWith(fontSize: 34, letterSpacing: 0),
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
  const _DauTrendCard({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();
    final days = List.generate(
      14,
      (index) => DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 13 - index)),
    );
    final values = days
        .map((day) => snapshot.dailyActiveUsers[day] ?? 0)
        .toList();
    final max = values.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    final yMax = (max < 4 ? 4 : max + 1).toDouble();

    return _ChartCard(
      title: 'DAU Trend',
      subtitle: 'Unique learners active per day',
      semanticsLabel: 'DAU trend chart for the last 14 days.',
      isDark: isDark,
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
                      interval: 3,
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
              ),
            )
          : _NoChartData(isDark: isDark, label: 'No daily active data yet'),
    );
  }
}

class _PlatformSplitCard extends StatelessWidget {
  const _PlatformSplitCard({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

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
      child: entries.isEmpty
          ? _NoChartData(isDark: isDark, label: 'No platform data yet')
          : Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 34,
                      sectionsSpace: 3,
                      sections: [
                        for (var i = 0; i < entries.length; i += 1)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: colors[i % colors.length],
                            title:
                                '${(entries[i].value / total * 100).round()}%',
                            titleStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            radius: 54,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AdminTokens.space4),
                Expanded(
                  child: _LegendList(
                    entries: entries,
                    colors: colors,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopEventSourcesCard extends StatelessWidget {
  const _TopEventSourcesCard({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.eventSourceTotals.entries.take(8).toList();
    final max = entries.fold<int>(0, (current, entry) {
      return entry.value > current ? entry.value : current;
    });

    return _ChartCard(
      title: 'Top Events by Source',
      subtitle: 'Which surfaces produce learning activity',
      semanticsLabel: 'Top events by source chart with ${entries.length} rows.',
      isDark: isDark,
      child: entries.isEmpty
          ? _NoChartData(isDark: isDark, label: 'No source data yet')
          : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AdminTokens.space3),
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
  const _TopEventsCard({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.eventTotals.entries.take(8).toList();
    final max = entries.fold<int>(0, (current, entry) {
      return entry.value > current ? entry.value : current;
    });

    return _ChartCard(
      title: 'Event Mix',
      subtitle: 'Lessons, quizzes, streaks, and habit signals',
      semanticsLabel: 'Top event mix chart with ${entries.length} event types.',
      isDark: isDark,
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
              ),
            ),
    );
  }
}

class _RetentionHeatmapCard extends StatelessWidget {
  const _RetentionHeatmapCard({required this.snapshot, required this.isDark});

  final AdminAnalyticsSnapshot snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cohorts = snapshot.retentionCohorts;
    return _Panel(
      isDark: isDark,
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
  const _ResponsiveGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              left,
              const SizedBox(height: AdminTokens.space6),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AdminTokens.space6),
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
  });

  final String title;
  final String subtitle;
  final String semanticsLabel;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, subtitle: subtitle, isDark: isDark),
          const SizedBox(height: AdminTokens.space5),
          SizedBox(
            height: 300,
            child: Semantics(label: semanticsLabel, image: true, child: child),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTokens.space5),
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
  const _IconBadge({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
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
  });

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < entries.length; i += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminTokens.space3),
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
                  entries[i].value.toString(),
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
  const _EmptyAnalyticsCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      child: Row(
        children: [
          _IconBadge(icon: Icons.schedule_rounded, isDark: isDark),
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
