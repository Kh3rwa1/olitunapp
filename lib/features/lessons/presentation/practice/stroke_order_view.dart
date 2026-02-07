import 'package:flutter/material.dart';

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
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
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
                              color: Colors.grey.withOpacity(0.10),
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
                'Watch the stroke flow and follow the same direction.',
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
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.letterChar,
                  style: TextStyle(
                    fontSize: 190,
                    color: Colors.grey.withOpacity(0.12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: StrokePainter(
                  progress: _animation,
                  color: Colors.teal,
                  letter: widget.letterChar,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Watch how to write',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            _controller.reset();
            _controller.forward();
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.refresh),
        ),
      ],
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
      ..color = Colors.grey.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, guidePaint);

    for (final metric in path.computeMetrics()) {
      final animatedPath = metric.extractPath(0.0, metric.length * progress.value);
      canvas.drawPath(animatedPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
