import 'package:flutter/material.dart';

import 'practice_guide.dart';

class TracingView extends StatefulWidget {
  final String letterChar;

  const TracingView({super.key, required this.letterChar});

  @override
  State<TracingView> createState() => _TracingViewState();
}

class _TracingViewState extends State<TracingView> {
  final List<Offset?> _points = [];
  double _progress = 0;

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _progress = 0;
    });
  }

  void _recalculateProgress(double boardSize) {
    final guidePath = buildPracticeGuidePath(
      Size.square(boardSize),
      widget.letterChar,
    );
    final guidePoints = samplePath(guidePath, samplesPerMetric: 64);

    final progress = computeTraceProgress(
      guidePoints: guidePoints,
      tracedPoints: _points,
      tolerance: boardSize * 0.07,
    );

    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide.clamp(260.0, 560.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: boardSize,
                    height: boardSize,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111A28) : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.10)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            widget.letterChar,
                            style: TextStyle(
                              fontSize: boardSize * 0.56,
                              color: Colors.grey.withOpacity(0.14),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GuidePainter(
                              letterChar: widget.letterChar,
                              color: isDark
                                  ? Colors.white.withOpacity(0.18)
                                  : Colors.black.withOpacity(0.18),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() => _points.add(details.localPosition));
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _points.add(details.localPosition);
                              });
                            },
                            onPanEnd: (_) {
                              _points.add(null);
                              _recalculateProgress(boardSize);
                            },
                            child: CustomPaint(
                              painter: TracingPainter(
                                points: _points,
                                color: const Color(0xFF35C7B5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _progress >= 0.9
                    ? 'Amazing! Your trace is super accurate.'
                    : 'Trace on the guideline. Accuracy: ${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: _progress,
                  backgroundColor:
                      isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF35C7B5)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear Tracing'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuidePainter extends CustomPainter {
  final String letterChar;
  final Color color;

  _GuidePainter({required this.letterChar, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final path = buildPracticeGuidePath(size, letterChar);
    canvas.drawPath(path, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.letterChar != letterChar || oldDelegate.color != color;
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  TracingPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.04
      ..isAntiAlias = true;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.color != color;
  }
}
