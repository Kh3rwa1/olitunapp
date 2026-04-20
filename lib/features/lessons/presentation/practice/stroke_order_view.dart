import 'package:flutter/material.dart';

import 'practice_guide.dart';

class StrokeOrderView extends StatefulWidget {
  final String letterChar;

  const StrokeOrderView({super.key, required this.letterChar});

  @override
  State<StrokeOrderView> createState() => _StrokeOrderViewState();
}

class _StrokeOrderViewState extends State<StrokeOrderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            widget.letterChar,
                            style: TextStyle(
                              fontSize: boardSize * 0.56,
                              color: Colors.grey.withValues(alpha: 0.12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: StrokePainter(
                              progress: _animation,
                              color: const Color(0xFF35C7B5),
                              letter: widget.letterChar,
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
                'Watch the stroke flow and then switch to Tracing mode to replicate it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  _controller
                    ..reset()
                    ..forward();
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Replay Animation'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StrokePainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;
  final String letter;

  StrokePainter({
    required this.progress,
    required this.color,
    required this.letter,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = buildPracticeGuidePath(size, letter);
    canvas.drawPath(path, guidePaint);

    final targetLength =
        path.computeMetrics().fold<double>(
          0,
          (sum, metric) => sum + metric.length,
        ) *
        progress.value;
    var consumed = 0.0;

    for (final metric in path.computeMetrics()) {
      if (consumed >= targetLength) {
        break;
      }
      final remain = targetLength - consumed;
      final drawLength = remain.clamp(0.0, metric.length);
      final animatedPath = metric.extractPath(0.0, drawLength);
      canvas.drawPath(animatedPath, strokePaint);
      consumed += metric.length;
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.letter != letter;
  }
}
