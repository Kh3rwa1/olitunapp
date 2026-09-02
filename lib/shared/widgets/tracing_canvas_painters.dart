// ignore_for_file: deprecated_member_use

part of 'tracing_canvas.dart';

// Custom painter that renders tracing guides, strokes and the example animation.
class _TracingPainter extends CustomPainter {
  final TracingConfig config;
  final int activeStrokeIndex;
  final List<Offset> currentRawPoints;
  final List<List<Offset>> completedStrokes;
  final Color accentColor;
  final bool isDark;
  final double exampleProgress;
  final int exampleStrokeIndex;

  _TracingPainter({
    required this.config,
    required this.activeStrokeIndex,
    required this.currentRawPoints,
    required this.completedStrokes,
    required this.accentColor,
    required this.isDark,
    required this.exampleProgress,
    required this.exampleStrokeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Guidelines
    _paintGuideLayout(canvas, size);

    // 2. Draw Expected Ghost Stroke Guides
    _paintExpectedStrokes(canvas, size);

    // 3. Draw Completed Strokes
    _paintCompletedStrokes(canvas, size);

    // 4. Draw Current User Drawing
    _paintUserDrawnCurrentStroke(canvas, size);

    // 5. Draw Example Animation if active
    _paintExampleAutoAnimation(canvas, size);
  }

  void _paintGuideLayout(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Outer boundary box padding
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // Dotted midlines
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);

    final dashPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, dashPaint);
  }

  void _paintExpectedStrokes(Canvas canvas, Size size) {
    if (config.guide == TracingGuide.none) return;

    for (int i = 0; i < config.strokes.length; i++) {
      final stroke = config.strokes[i];
      final path = _buildStrokePath(stroke, size);

      final isCurrent = i == activeStrokeIndex;

      final paint = Paint()
        ..color = isCurrent
            ? accentColor.withOpacity(0.18)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withOpacity(0.5)
        ..strokeWidth = config.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (config.guide == TracingGuide.dotted) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      // Draw starting point highlight
      if (isCurrent && stroke.path.isNotEmpty) {
        final start = Offset(
          stroke.path[0].x * size.width,
          stroke.path[0].y * size.height,
        );
        canvas.drawCircle(
          start,
          config.strokeWidth / 1.6,
          Paint()..color = accentColor.withOpacity(0.35),
        );
        canvas.drawCircle(start, 6.0, Paint()..color = accentColor);
      }
    }
  }

  void _paintCompletedStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in completedStrokes) {
      final path = Path();
      if (stroke.isEmpty) continue;
      path.moveTo(stroke[0].dx * size.width, stroke[0].dy * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * size.width, stroke[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintUserDrawnCurrentStroke(Canvas canvas, Size size) {
    if (currentRawPoints.length < 2) return;

    final paint = Paint()
      ..color = accentColor.withOpacity(0.7)
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(currentRawPoints[0].dx, currentRawPoints[0].dy);
    for (int i = 1; i < currentRawPoints.length; i++) {
      path.lineTo(currentRawPoints[i].dx, currentRawPoints[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintExampleAutoAnimation(Canvas canvas, Size size) {
    if (exampleStrokeIndex < 0 || exampleStrokeIndex >= config.strokes.length) {
      return;
    }
    final stroke = config.strokes[exampleStrokeIndex];
    if (stroke.path.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = accentColor.withOpacity(0.75)
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePath = _buildStrokePath(stroke, size);
    _drawAnimatedPath(canvas, strokePath, exampleProgress, paint);
  }

  Path _buildStrokePath(TracingStroke stroke, Size size) {
    final path = Path();
    if (stroke.path.isEmpty) return path;

    final hasControlPoints = stroke.path.any((p) => p.isControlPoint);

    final start = Offset(
      stroke.path[0].x * size.width,
      stroke.path[0].y * size.height,
    );
    path.moveTo(start.dx, start.dy);

    if (hasControlPoints && stroke.path.length >= 4) {
      final cp1 = Offset(
        stroke.path[1].x * size.width,
        stroke.path[1].y * size.height,
      );
      final cp2 = Offset(
        stroke.path[2].x * size.width,
        stroke.path[2].y * size.height,
      );
      final end = Offset(
        stroke.path[3].x * size.width,
        stroke.path[3].y * size.height,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    } else {
      for (int i = 1; i < stroke.path.length; i++) {
        final pt = Offset(
          stroke.path[i].x * size.width,
          stroke.path[i].y * size.height,
        );
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Custom dash algorithm using PathMetrics
    for (final metric in path.computeMetrics()) {
      double start = 0.0;
      const double dashLength = 8.0;
      const double spaceLength = 6.0;

      while (start < metric.length) {
        final double end = (start + dashLength).clamp(0.0, metric.length);
        final Path dash = metric.extractPath(start, end);
        canvas.drawPath(dash, paint);
        start += dashLength + spaceLength;
      }
    }
  }

  void _drawAnimatedPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    for (final metric in path.computeMetrics()) {
      final double end = metric.length * progress;
      final Path animatedSubpath = metric.extractPath(0.0, end);
      canvas.drawPath(animatedSubpath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracingPainter oldDelegate) {
    return oldDelegate.activeStrokeIndex != activeStrokeIndex ||
        oldDelegate.currentRawPoints != currentRawPoints ||
        oldDelegate.completedStrokes != completedStrokes ||
        oldDelegate.exampleProgress != exampleProgress ||
        oldDelegate.exampleStrokeIndex != exampleStrokeIndex;
  }
}
