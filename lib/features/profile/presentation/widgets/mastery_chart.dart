import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/entities/user_stats_entity.dart';

class ChartDataPoint {
  final String dayName;
  final double accuracy;
  final int quizCount;
  final DateTime date;
  final bool isDemo;

  ChartDataPoint({
    required this.dayName,
    required this.accuracy,
    required this.quizCount,
    required this.date,
    this.isDemo = false,
  });
}

class MasteryTimelineChart extends ConsumerStatefulWidget {
  final UserStatsEntity stats;
  const MasteryTimelineChart({super.key, required this.stats});

  @override
  ConsumerState<MasteryTimelineChart> createState() =>
      _MasteryTimelineChartState();
}

class _MasteryTimelineChartState extends ConsumerState<MasteryTimelineChart>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex = 6; // Default to highlight today (last node)
  late List<ChartDataPoint> _dataPoints;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final reduceEffects = ref.read(reduceVisualEffectsProvider);
    if (!reduceEffects) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<ChartDataPoint> _getChartData() {
    final List<ChartDataPoint> points = [];
    final now = DateTime.now();
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = weekdays[day.weekday % 7];

      int totalCorrect = 0;
      int totalQuestions = 0;
      int count = 0;

      for (final result in widget.stats.quizHistory.values) {
        final completedDate = DateTime.tryParse(result.completedAt)?.toLocal();
        if (completedDate != null &&
            completedDate.year == day.year &&
            completedDate.month == day.month &&
            completedDate.day == day.day) {
          totalCorrect += result.score.clamp(0, result.totalQuestions);
          totalQuestions += result.totalQuestions;
          count++;
        }
      }

      final accuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;

      points.add(
        ChartDataPoint(
          dayName: dayStr,
          accuracy: accuracy,
          quizCount: count,
          date: day,
        ),
      );
    }
    return points;
  }

  void _handleTap(Offset localPosition, double width, double height) {
    const leftPadding = 45.0;
    const rightPadding = 15.0;
    final chartWidth = width - leftPadding - rightPadding;
    final stepX = chartWidth / 6;

    final touchX = localPosition.dx;
    final index = ((touchX - leftPadding) / stepX).round().clamp(0, 6);

    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reduceVisualEffectsProvider, (previous, next) {
      if (next) {
        _pulseController.stop();
      } else {
        _pulseController.repeat();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _dataPoints = _getChartData();
    final hasQuizzes = widget.stats.quizHistory.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 180.0;

        const leftPadding = 45.0;
        const rightPadding = 15.0;
        const topPadding = 25.0;
        const bottomPadding = 30.0;

        final chartWidth = width - leftPadding - rightPadding;
        const chartHeight = height - topPadding - bottomPadding;
        final stepX = chartWidth / 6;

        Widget? tooltipWidget;
        if (_selectedIndex != null && _selectedIndex! < _dataPoints.length) {
          final pt = _dataPoints[_selectedIndex!];
          final nodeX = leftPadding + (_selectedIndex! * stepX);
          final nodeY = topPadding + chartHeight - (pt.accuracy * chartHeight);

          tooltipWidget = Positioned(
            left: (nodeX - 70).clamp(8.0, width - 148.0),
            top: (nodeY - 70).clamp(4.0, height - 60.0),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0,
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pt.dayName == 'Sun'
                                    ? 'Sunday'
                                    : pt.dayName == 'Mon'
                                    ? 'Monday'
                                    : pt.dayName == 'Tue'
                                    ? 'Tuesday'
                                    : pt.dayName == 'Wed'
                                    ? 'Wednesday'
                                    : pt.dayName == 'Thu'
                                    ? 'Thursday'
                                    : pt.dayName == 'Fri'
                                    ? 'Friday'
                                    : 'Saturday',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              if (pt.isDemo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.duoOrange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEMO',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.duoOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accuracy: ${(pt.accuracy * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pt.isDemo
                                ? 'Sample progress'
                                : '${pt.quizCount} Quizzes taken',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Container(
              width: double.infinity,
              height: 275,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.5)
                      : AppColors.lightBorder.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mastery Progression',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasQuizzes
                                  ? 'Weekly accuracy tracking'
                                  : 'Take quizzes to see your progress',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: height,
                    child: GestureDetector(
                      onTapDown: (details) =>
                          _handleTap(details.localPosition, width, height),
                      onPanUpdate: (details) =>
                          _handleTap(details.localPosition, width, height),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: MasteryChartPainter(
                                points: _dataPoints,
                                selectedIndex: _selectedIndex,
                                isDark: isDark,
                                pulseValue: _pulseController.value,
                              ),
                            ),
                          ),
                          ?tooltipWidget,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class MasteryChartPainter extends CustomPainter {
  final List<ChartDataPoint> points;
  final int? selectedIndex;
  final bool isDark;
  final double pulseValue;

  MasteryChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.isDark,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 45.0;
    const rightPadding = 15.0;
    const topPadding = 25.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final stepX = chartWidth / 6;

    // 1. Draw Grid Lines (0%, 25%, 50%, 75%, 100%)
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    final levels = [1.0, 0.75, 0.5, 0.25, 0.0];
    final labels = ['100%', '75%', '50%', '25%', '0%'];

    for (int i = 0; i < levels.length; i++) {
      final y = topPadding + chartHeight - (levels[i] * chartHeight);

      // Dashed lines helper
      double startX = leftPadding;
      const dashWidth = 5.0;
      const dashSpace = 4.0;

      while (startX < size.width - rightPadding) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(
            (startX + dashWidth).clamp(leftPadding, size.width - rightPadding),
            y,
          ),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Draw Grid Label Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    if (points.isEmpty) return;

    // 2. Generate smooth bezier paths
    final path = Path();
    final areaPath = Path();

    const x0 = leftPadding;
    final y0 = topPadding + chartHeight - (points[0].accuracy * chartHeight);

    path.moveTo(x0, y0);
    areaPath.moveTo(x0, topPadding + chartHeight);
    areaPath.lineTo(x0, y0);

    for (int i = 0; i < points.length - 1; i++) {
      final pA = points[i];
      final pB = points[i + 1];

      final xA = leftPadding + (i * stepX);
      final yA = topPadding + chartHeight - (pA.accuracy * chartHeight);

      final xB = leftPadding + ((i + 1) * stepX);
      final yB = topPadding + chartHeight - (pB.accuracy * chartHeight);

      final controlX1 = xA + (xB - xA) / 2;
      final controlY1 = yA;

      final controlX2 = xA + (xB - xA) / 2;
      final controlY2 = yB;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, xB, yB);
      areaPath.cubicTo(controlX1, controlY1, controlX2, controlY2, xB, yB);
    }

    final lastX = leftPadding + (6 * stepX);
    areaPath.lineTo(lastX, topPadding + chartHeight);
    areaPath.close();

    // 3. Draw linear gradient area underneath
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, topPadding),
        Offset(size.width / 2, topPadding + chartHeight),
        [
          AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.18),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, fillPaint);

    // 4. Draw Glow Halo Line (wide, blurred, low opacity)
    final haloPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
    canvas.drawPath(path, haloPaint);

    // 5. Draw Sharp Bezier Stroke
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(leftPadding, topPadding),
        Offset(lastX, topPadding),
        [AppColors.primary, AppColors.primaryLight],
      )
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 6. Draw Day Labels at the bottom
    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + (i * stepX);
      final y = topPadding + chartHeight + 10;

      final isSelected = selectedIndex == i;

      final textPainter = TextPainter(
        text: TextSpan(
          text: points[i].dayName,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white38 : Colors.black45),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));

      // 7. Draw Nodes on the line
      final nodeY =
          topPadding + chartHeight - (points[i].accuracy * chartHeight);

      if (isSelected) {
        // Pulse outer glow circle
        final pulseRadius = 8.0 + (pulseValue * 5.0);
        final pulsePaint = Paint()
          ..color = AppColors.primary.withValues(
            alpha: 0.25 * (1.0 - pulseValue),
          )
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, nodeY), pulseRadius, pulsePaint);

        // Highlight solid nodes
        final highlightOuterPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, nodeY), 7.0, highlightOuterPaint);

        final highlightInnerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, nodeY), 3.0, highlightInnerPaint);
      } else {
        // Standard small node
        final nodeOuterPaint = Paint()
          ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
          ..style = PaintingStyle.fill;
        final nodeInnerPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, nodeY), 5.0, nodeInnerPaint);
        canvas.drawCircle(Offset(x, nodeY), 2.5, nodeOuterPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MasteryChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.points != points;
  }
}
