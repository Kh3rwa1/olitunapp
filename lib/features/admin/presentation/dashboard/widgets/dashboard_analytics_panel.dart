import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';

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
                  _LegendDot(
                    color: AppColors.primary,
                    label: 'Lessons',
                    isDark: isDark,
                  ),
                  _LegendDot(
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
              error: (_, __) => _ChartEmpty(
                isDark: isDark,
                icon: Icons.cloud_off_rounded,
                message: 'Couldn\'t load engagement data',
              ),
              data: (m) {
                final hasData =
                    m.lessonsSeries.any((v) => v > 0) ||
                    m.vocabularySeries.any((v) => v > 0);
                if (!hasData) {
                  return _ChartEmpty(
                    isDark: isDark,
                    icon: Icons.show_chart_rounded,
                    message: 'No activity in the last 7 days',
                  );
                }
                return _Chart(
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

class _ChartEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  const _ChartEmpty({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AdminTokens.textMuted(isDark)),
          const SizedBox(height: 10),
          Text(
            message,
            style: AdminTokens.body(
              isDark,
            ).copyWith(fontSize: 13, color: AdminTokens.textTertiary(isDark)),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AdminTokens.label(isDark).copyWith(
            fontSize: 11.5,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  final bool isDark;
  final List<int> lessons;
  final List<int> vocabulary;
  final List<String> dayLabels;
  const _Chart({
    required this.isDark,
    required this.lessons,
    required this.vocabulary,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black12;
    final axisColor = AdminTokens.textMuted(isDark);

    final maxValue = [
      ...lessons,
      ...vocabulary,
    ].fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = (maxValue < 4 ? 4 : maxValue + 1).toDouble();
    final rawInterval = (yMax / 4).ceilToDouble();
    final yInterval = rawInterval < 1.0 ? 1.0 : rawInterval;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: axisColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: axisColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1A2030) : Colors.white,
            tooltipBorder: BorderSide(color: AdminTokens.border(isDark)),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      color: AdminTokens.textPrimary(isDark),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          _series(
            lessons.map((e) => e.toDouble()).toList(),
            color: AppColors.primary,
            fillTop: 0.18,
          ),
          _series(
            vocabulary.map((e) => e.toDouble()).toList(),
            color: AppColors.duoBlue,
            fillTop: 0.10,
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  LineChartBarData _series(
    List<double> ys, {
    required Color color,
    double fillTop = 0.15,
    double fillBottom = 0.0,
    bool isDashed = false,
    double barWidth = 3.5,
  }) {
    return LineChartBarData(
      spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
      isCurved: true,
      curveSmoothness: 0.32,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 2,
          strokeColor: isDark ? const Color(0xFF111621) : Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: fillTop),
            color.withValues(alpha: fillBottom),
          ],
        ),
      ),
      dashArray: isDashed ? [4, 4] : null,
    );
  }
}
