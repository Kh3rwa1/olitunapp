import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminLoginBackground extends StatelessWidget {
  const AdminLoginBackground({super.key});

  Widget _blob({
    required Color color,
    double? top,
    double? left,
    double? bottom,
    double? right,
    required Duration duration,
    double size = 300,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(40, 40),
                duration: duration,
                curve: Curves.easeInOut,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.18, 1.18),
                duration: duration,
                curve: Curves.easeInOut,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF050810),
                  const Color(0xFF0A1018),
                  const Color(0xFF050810),
                ]
              : [AdminTokens.neutral50, Colors.white, AdminTokens.neutral75],
        ),
      ),
      child: Stack(
        children: [
          _blob(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            top: -80,
            left: -60,
            size: 320,
            duration: 18.seconds,
          ),
          _blob(
            color: AppColors.duoBlue.withValues(alpha: isDark ? 0.12 : 0.08),
            bottom: -100,
            right: -50,
            size: 360,
            duration: 22.seconds,
          ),
          // Subtle dot grid for texture.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.05 : 0.04,
                child: CustomPaint(painter: _DotGridPainter(isDark: isDark)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
