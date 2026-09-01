part of '../admin_analytics_screen.dart';

// KPI and top-list analytics cards.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    super.key,
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
          KpiCard(
            label: 'DAU',
            value: snapshot.dau.toString(),
            caption: 'Active learners today',
            tooltip:
                'Daily Active Users: Distinct active user/session IDs active today (UTC).',
            icon: Icons.today_rounded,
            isDark: isDark,
            compact: compact,
          ),
          KpiCard(
            label: 'WAU',
            value: snapshot.wau.toString(),
            caption: 'Active learners this week',
            tooltip:
                'Weekly Active Users: Distinct active user/session IDs active in the last 7 days.',
            icon: Icons.calendar_view_week_rounded,
            isDark: isDark,
            compact: compact,
          ),
          KpiCard(
            label: 'MAU',
            value: snapshot.mau.toString(),
            caption: 'Active learners this month',
            tooltip:
                'Monthly Active Users: Distinct active user/session IDs active in the last 30 days.',
            icon: Icons.calendar_month_rounded,
            isDark: isDark,
            compact: compact,
          ),
          KpiCard(
            label: 'Rollups',
            value: snapshot.rollupRows.toString(),
            caption: '${snapshot.eventRows} raw events sampled',
            tooltip:
                'Nightly aggregated summary records computed server-side across all events.',
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

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.tooltip,
    required this.icon,
    required this.isDark,
    required this.compact,
  });

  final String label;
  final String value;
  final String caption;
  final String? tooltip;
  final IconData icon;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final widgetContent = Panel(
      isDark: isDark,
      compact: compact,
      child: Semantics(
        label: '$label $value. $caption',
        child: Row(
          children: [
            IconBadge(icon: icon, isDark: isDark, compact: compact),
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

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widgetContent);
    }
    return widgetContent;
  }
}

class DauTrendCard extends StatelessWidget {
  const DauTrendCard({
    super.key,
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

    return ChartCard(
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
                          fontFamily: 'Inter',
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
          : NoChartData(isDark: isDark, label: 'No daily active data yet'),
    );
  }
}

class PlatformSplitCard extends StatelessWidget {
  const PlatformSplitCard({
    super.key,
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
      AppColors.brandBlue,
      AppColors.warning,
      AppColors.accentPurple,
      AppColors.accentPink,
    ];

    return ChartCard(
      title: 'Platform Split',
      subtitle: 'Where learning sessions happen',
      semanticsLabel:
          'Platform split chart across ${entries.length} platforms.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? NoChartData(isDark: isDark, label: 'No platform data yet')
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
                LegendList(
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

class TopEventSourcesCard extends StatelessWidget {
  const TopEventSourcesCard({
    super.key,
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

    return ChartCard(
      title: 'Top Events by Source',
      subtitle: 'Which surfaces produce learning activity',
      semanticsLabel: 'Top events by source chart with ${entries.length} rows.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? NoChartData(isDark: isDark, label: 'No source data yet')
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

class TopEventsCard extends StatelessWidget {
  const TopEventsCard({
    super.key,
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

    return ChartCard(
      title: 'Event Mix',
      subtitle: 'Lessons, quizzes, streaks, and habit signals',
      semanticsLabel: 'Top event mix chart with ${entries.length} event types.',
      isDark: isDark,
      compact: compact,
      child: entries.isEmpty
          ? NoChartData(isDark: isDark, label: 'No event rollups yet')
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
                          color: AppColors.brandBlue,
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
                          fontFamily: 'Inter',
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
