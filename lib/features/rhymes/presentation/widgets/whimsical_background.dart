import 'dart:math' as math;
import 'package:flutter/material.dart';

class WhimsicalBackground extends StatefulWidget {
  final Widget child;
  const WhimsicalBackground({super.key, required this.child});

  @override
  State<WhimsicalBackground> createState() => _WhimsicalBackgroundState();
}

class _WhimsicalBackgroundState extends State<WhimsicalBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
            ),
          ),
        ),

        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _BlobPainter(
                animationValue: _controller.value,
                isDark: isDark,
              ),
            );
          },
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _BlobPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final angle = animationValue * 2 * math.pi;

    // Blob 1
    paint.color = (isDark
        ? Colors.blue.withOpacity(0.1)
        : Colors.blue.withOpacity(0.05));
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.sin(angle) * 50,
        size.height * 0.3 + math.cos(angle) * 30,
      ),
      200,
      paint,
    );

    // Blob 2
    paint.color = (isDark
        ? Colors.cyan.withOpacity(0.1)
        : Colors.cyan.withOpacity(0.05));
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.cos(angle * 0.8) * 40,
        size.height * 0.7 + math.sin(angle * 1.2) * 60,
      ),
      250,
      paint,
    );

    // Blob 3
    paint.color = (isDark
        ? Colors.teal.withOpacity(0.1)
        : Colors.teal.withOpacity(0.05));
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + math.sin(angle * 1.5) * 70,
        size.height * 0.9 + math.cos(angle * 0.5) * 40,
      ),
      180,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => true;
}
