import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AnalyticsLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const AnalyticsLegendDot({
    super.key,
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

class AnalyticsChart extends StatelessWidget {
  final bool isDark;
  final List<int> lessons;
  final List<int> vocabulary;
  final List<String> dayLabels;

  const AnalyticsChart({
    super.key,
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
