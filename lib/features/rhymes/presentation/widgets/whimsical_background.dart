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
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B), // Custom indigo-dark
                    ]
                  : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
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

        // Subtle Grid Overlay (Optimized with CustomPaint)
        if (!isDark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _GridPainter()),
            ),
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final angle = animationValue * 2 * math.pi;

    // Blob 1: Deep Blue / Soft Blue
    paint.color = (isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
        : const Color(0xFF60A5FA).withValues(alpha: 0.08));
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.sin(angle) * 70,
        size.height * 0.2 + math.cos(angle * 0.5) * 50,
      ),
      size.width * 0.6,
      paint,
    );

    // Blob 2: Indigo / Light Indigo
    paint.color = (isDark
        ? const Color(0xFF6366F1).withValues(alpha: 0.1)
        : const Color(0xFF818CF8).withValues(alpha: 0.06));
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.cos(angle * 0.7) * 60,
        size.height * 0.5 + math.sin(angle * 1.1) * 80,
      ),
      size.width * 0.7,
      paint,
    );

    // Blob 3: Violet / Soft Lavender
    paint.color = (isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
        : const Color(0xFFA78BFA).withValues(alpha: 0.07));
    canvas.drawCircle(
      Offset(
        size.width * 0.4 + math.sin(angle * 1.3) * 90,
        size.height * 0.8 + math.cos(angle * 0.6) * 60,
      ),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    const spacing = 32.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
