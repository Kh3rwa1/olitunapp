import 'package:flutter/material.dart';

class StrokeOrderView extends StatefulWidget {
  final String letterChar;

  const StrokeOrderView({super.key, required this.letterChar});

  @override
  State<StrokeOrderView> createState() => _StrokeOrderViewState();
}

class _StrokeOrderViewState extends State<StrokeOrderView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Auto start and loop
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    // Simulate a path for demo (circle/spiral-ish) based on size
    // In real app, we'd have SVG paths for each letter
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Simple path simulation: Draw a circle starting from top
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Draw background guide (faint)
    canvas.drawPath(path, bgPaint);

    // Draw animated path
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(
        0.0,
        metric.length * progress.value,
      );
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
