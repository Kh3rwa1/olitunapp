import 'package:flutter/material.dart';

class TracingView extends StatefulWidget {
  final String letterChar;

  const TracingView({super.key, required this.letterChar});

  @override
  State<TracingView> createState() => _TracingViewState();
}

class _TracingViewState extends State<TracingView> {
  final List<Offset?> _points = [];

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
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
              // Background Guide (The Letter)
              Center(
                child: Text(
                  widget.letterChar,
                  style: TextStyle(
                    fontSize: 200,
                    color: Colors.grey.withOpacity(0.2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Interactive Drawing Canvas
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  _points.add(null); // End showing continuous line
                },
                child: CustomPaint(
                  painter: TracingPainter(points: _points, color: Colors.teal),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Trace the letter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _clearCanvas,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.delete_outline),
        ),
      ],
    );
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
      ..strokeWidth = 12.0
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
